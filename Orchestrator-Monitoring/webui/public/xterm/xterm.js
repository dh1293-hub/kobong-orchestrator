;(()=>{ // terminal shim v11: multiline cursor ↑/↓, Shift+Enter new line, copy→caret, one-newline, echo filter
  if(!window.Terminal){
    class T{
      constructor(){
        this._el=null; this._onData=null;
        this._base=""; this._buf=""; this._cursor=0; this._active=true;

        // echo/newline control
        this._awaitEcho=false; this._lastSent=""; this._pendingFirstChunk=false; this._echoTimer=null;

        // history
        this._hist=[]; this._hidx=-1; this._stash="";

        // vertical move wishes
        this._wantCol=null; // 원하는 열(↑/↓ 유지)
      }

      open(el){
        this._el=el; el.classList.add("xterm","is-active");
        el.tabIndex=0; el.setAttribute("aria-label","terminal");
        this._print("[shim ready]\\n");

        el.addEventListener("pointerdown", ()=>{ this._active=true; el.classList.add("is-active"); });
        document.addEventListener("pointerdown", e=>{ if(!el.contains(e.target)){ this._active=false; el.classList.remove("is-active"); } });

        window.addEventListener("keydown", async (e)=>{
          if(!this._active || !this._onData) return;
          const k=e.key, ctrl=e.ctrlKey||e.metaKey, alt=e.altKey, shift=e.shiftKey;

          // Paste (Ctrl+V)
          if(ctrl && (k==="v"||k==="V")){
            try{ let t=await (navigator.clipboard?.readText?.()||Promise.resolve("")); if(t) this._insert(t); }catch{}
            e.preventDefault(); return;
          }

          // Copy or ^C (Ctrl+C)
          if(ctrl && (k==="c"||k==="C")){
            const sel=(window.getSelection()||{toString:()=>""});
            const text=sel.toString();
            if(text){
              try{ await navigator.clipboard?.writeText?.(text); }catch{}
              sel.removeAllRanges?.(); // 선택 해제
              this._active=true; this._cursor=this._buf.length; this._render(); // 커서 복귀
            }else{
              this._send("\x03"); this._commitLocalNewline(); // ^C 후 줄 정리
            }
            e.preventDefault(); return;
          }

          // Shift+Enter: 입력줄에 줄바꿈 삽입(전송 X)
          if(shift && k==="Enter"){ this._insert("\n"); e.preventDefault(); return; }

          // Enter: 한 줄 전송(단일 개행 정책)
          if(k==="Enter"){
            const line=this._buf, norm=line.replace(/\r\n|\n/g,"\r\n");
            if(line.trim().length>0){
              const last=this._hist[this._hist.length-1]; if(last!==line) this._hist.push(line);
            }
            this._hidx=-1; this._stash=""; this._wantCol=null;

            this._lastSent=norm; this._awaitEcho=true; this._pendingFirstChunk=true;
            clearTimeout(this._echoTimer); this._echoTimer=setTimeout(()=>{ this._awaitEcho=false; },1500);

            // 화면: 개행 없이 라인만 붙이고 입력 버퍼 비움
            this._base+=this._buf; this._buf=""; this._cursor=0; this._render();

            // 서버로 전송
            this._send(norm+"\r\n");
            e.preventDefault(); return;
          }

          // Multiline? ↑/↓는 줄 이동, Alt+↑/↓는 언제나 히스토리
          const hasMulti = this._buf.includes("\n");

          if(k==="ArrowUp"){
            if(!alt && (hasMulti && this._moveVert(-1))){ e.preventDefault(); return; }
            // history ↑
            if(this._hidx===-1){ this._stash=this._buf; if(this._hist.length>0){ this._hidx=this._hist.length-1; this._loadHist(); } }
            else if(this._hidx>0){ this._hidx--; this._loadHist(); }
            e.preventDefault(); return;
          }

          if(k==="ArrowDown"){
            if(!alt && (hasMulti && this._moveVert(+1))){ e.preventDefault(); return; }
            // history ↓
            if(this._hidx>-1){
              if(this._hidx<this._hist.length-1){ this._hidx++; this._loadHist(); }
              else { this._hidx=-1; this._buf=this._stash; this._cursor=this._buf.length; this._render(); }
            }
            e.preventDefault(); return;
          }

          // 라인 편집
          if(k==="Backspace"){ if(this._cursor>0){ this._buf=this._buf.slice(0,this._cursor-1)+this._buf.slice(this._cursor); this._cursor--; this._render(); } e.preventDefault(); return; }
          if(k==="Delete"){ if(this._cursor<this._buf.length){ this._buf=this._buf.slice(0,this._cursor)+this._buf.slice(this._cursor+1); this._render(); } e.preventDefault(); return; }
          if(k==="ArrowLeft"){ if(this._cursor>0){ this._cursor--; this._wantCol=null; this._render(); } e.preventDefault(); return; }
          if(k==="ArrowRight"){ if(this._cursor<this._buf.length){ this._cursor++; this._wantCol=null; this._render(); } e.preventDefault(); return; }
          if(k==="Home"){ this._cursor=this._bol(this._cursor); this._wantCol=0; this._render(); e.preventDefault(); return; }
          if(k==="End"){ this._cursor=this._eol(this._cursor); this._wantCol=null; this._render(); e.preventDefault(); return; }
          if(k==="Tab"){ this._insert("\t"); e.preventDefault(); return; }

          // 일반 문자
          if(!ctrl && !alt && typeof k==="string" && k.length===1){ this._insert(k); e.preventDefault(); return; }
        }, true);
      }

      // 서버 → 터미널
      write(s){
        let t=String(s).replace(/\r\n/g,"\n").replace(/\r/g,"\n").replace(/\x1b\[[0-9;]*m/g,"");
        if(this._pendingFirstChunk){
          t = t.replace(/^\n+/, ""); // 선행 개행 제거
          this._base += "\n";        // 단일 개행
          this._pendingFirstChunk=false;
        }
        if(this._awaitEcho && this._lastSent){
          const last=this._lastSent.replace(/\r\n/g,"\n");
          const esc=last.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
          const re=new RegExp(`(^|\\n)${esc}(\\n)?`);
          if(re.test(t)){ t=t.replace(re,(m,g1)=>g1||""); this._awaitEcho=false; }
        }
        if(!t) return; this._base+=t; this._render();
      }

      // ===== 입력 버퍼 편집 & 렌더 =====
      _insert(txt){
        txt=String(txt).replace(/\r\n/g,"\n").replace(/\r/g,"\n");
        this._buf=this._buf.slice(0,this._cursor)+txt+this._buf.slice(this._cursor);
        this._cursor += txt.length; this._wantCol=null; this._render();
      }
      _send(s){ try{ this._onData && this._onData(s); }catch{} }
      _print(s){ this._base+=String(s).replace(/\r\n/g,"\n").replace(/\r/g,"\n"); this._render(); }

      _render(){
        if(!this._el) return;
        const esc=(x)=>String(x).replace(/[&<>]/g,c=>({ '&':'&amp;','<':'&lt;','>':'&gt;' }[c]));
        const before=esc(this._buf.slice(0,this._cursor));
        const after =esc(this._buf.slice(this._cursor));
        this._el.innerHTML = esc(this._base) + before + '<span class="caret"></span>' + after;
        this._el.scrollTop=this._el.scrollHeight;
      }
      _commitLocalNewline(){ this._base+="\n"; this._buf=""; this._cursor=0; this._render(); }

      // ===== 멀티라인 커서 이동 =====
      _bol(i){ const s=this._buf; let j=i; while(j>0 && s[j-1]!="\n") j--; return j; }          // line start
      _eol(i){ const s=this._buf; let j=i; while(j<s.length && s[j]!="\n") j++; return j; }     // line end
      _lineStarts(){ const s=this._buf; const a=[0]; for(let i=0;i<s.length;i++) if(s[i]==="\n") a.push(i+1); return a; }
      _lc(i){ const L=this._lineStarts(); let ln=0; while(ln+1<L.length && L[ln+1]<=i) ln++; return { line:ln, col:i-L[ln], starts:L }; }
      _idx(line,col,starts){
        const s=this._buf, L=starts||this._lineStarts(), start=L[Math.max(0,Math.min(line, L.length-1))];
        const end=(line<L.length-1? L[line+1]-1 : s.length); // EOL index
        const c=Math.max(0, Math.min(col, end-start));
        return start + c;
      }
      _moveVert(d){ // d = -1(위) or +1(아래)
        const { line, col, starts } = this._lc(this._cursor);
        const tgt = line + d;
        if(tgt<0 || tgt>=starts.length) return false;
        const want = (this._wantCol==null)? col : this._wantCol;
        this._cursor = this._idx(tgt, want, starts);
        this._wantCol = want;
        this._render();
        return true;
      }

      onData(fn){ this._onData=fn; }
    }
    window.Terminal = T;
  }
})();
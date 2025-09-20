import React from "react";
import ReactDOM from "react-dom/client";
import "./index.css";
import WebGUIGithubUI from "./ui/Web-GUI-Github-v0.1";

function App(){ return <WebGUIGithubUI />; }

const el = document.getElementById("root") ?? (()=>{ const d=document.createElement("div"); d.id="root"; document.body.appendChild(d); return d; })();
ReactDOM.createRoot(el).render(<React.StrictMode><App /></React.StrictMode>);
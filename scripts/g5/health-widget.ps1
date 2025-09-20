#requires -Version 7.0
param([string]$Branch='main',[int]$PollSec=15)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSDefaultParameterValues['Out-File:Encoding']='utf8'
$PSDefaultParameterValues['*:Encoding']='utf8'

# ---- Ensure STA (WinForms 필요) ----
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
  try {
    $pwsh = (Get-Command pwsh).Source
    $args = @('-NoLogo','-NoProfile','-STA','-File', $PSCommandPath, '-Branch', $Branch, '-PollSec', $PollSec)
    Start-Process $pwsh -ArgumentList $args | Out-Null
    return
  } catch {
    Write-Error "Cannot relaunch with -STA: $($_.Exception.Message)"
    exit 1
  }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "Health Monitor"; $form.Size = [Drawing.Size]::new(360,140)
$form.FormBorderStyle = "FixedToolWindow"; $form.TopMost = $true; $form.StartPosition='CenterScreen'

$panel = New-Object System.Windows.Forms.Panel
$panel.Size = [Drawing.Size]::new(24,24); $panel.Location = [Drawing.Point]::new(12,12); $panel.BackColor = "Gray"
$form.Controls.Add($panel)

$lbl = New-Object System.Windows.Forms.Label
$lbl.AutoSize = $false; $lbl.Location = [Drawing.Point]::new(48,12)
$lbl.Size = [Drawing.Size]::new(290,48); $lbl.Text = "loading..."
$form.Controls.Add($lbl)

$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Text = "Open Run"; $btnOpen.Location = [Drawing.Point]::new(48,70)
$btnOpen.Add_Click({ if ($script:lastId) { Start-Process "gh" "run view $script:lastId --web" } })
$form.Controls.Add($btnOpen)

$btnLog = New-Object System.Windows.Forms.Button
$btnLog.Text = "Show Logs"; $btnLog.Location = [Drawing.Point]::new(150,70)
$btnLog.Add_Click({
  if ($script:lastId) {
    $wt = Get-Command wt.exe -ErrorAction SilentlyContinue
    if ($wt) {
      Start-Process $wt.Source "new-tab pwsh -NoLogo -NoProfile -Command `"gh run view $script:lastId --log; Read-Host 'Press Enter to close'`""
    } else {
      Start-Process "pwsh" "-NoLogo -NoProfile -Command `"gh run view $script:lastId --log; Read-Host 'Press Enter to close'`""
    }
  }
})
$form.Controls.Add($btnLog)

$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Visible = $true; $notify.Icon = [System.Drawing.SystemIcons]::Application; $notify.Text = "Health Monitor"

$script:lastId = $null; $script:lastConclusion = $null

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $PollSec*1000
$timer.Add_Tick({
  try {
    $json = gh run list --workflow 'Health Monitor' --branch $Branch --limit 1 --json databaseId,conclusion,status,updatedAt,displayTitle,url 2>$null
    if (-not $json) { return }
    $obj = $json | ConvertFrom-Json | Select-Object -First 1
    if ($null -eq $obj) { return }
    $script:lastId = $obj.databaseId
    $lbl.Text = "{0}`n{1}  •  {2}" -f $obj.displayTitle, $obj.conclusion.ToUpper(), ([datetime]$obj.updatedAt).ToLocalTime().ToString("HH:mm:ss")
    switch ($obj.conclusion) {
      'success' { $panel.BackColor = "LimeGreen" }
      'failure' { $panel.BackColor = "Crimson"   }
      default   { $panel.BackColor = "Goldenrod" }
    }
    if ($script:lastConclusion -and $script:lastConclusion -ne $obj.conclusion) {
      $notify.BalloonTipTitle = "Health Monitor"
      $notify.BalloonTipText  = "Conclusion changed: $($script:lastConclusion) → $($obj.conclusion)"
      $notify.ShowBalloonTip(3000)
    }
    $script:lastConclusion = $obj.conclusion
  } catch {
    $panel.BackColor = "Gray"; $lbl.Text = "error: $($_.Exception.Message)"
  }
})
$timer.Start()
[void]$form.ShowDialog()
$notify.Dispose()
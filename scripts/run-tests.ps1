param()
$ErrorActionPreference = "Stop"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -U pip
pip install -r requirements-dev.txt
$env:PYTHONPATH = (Get-Location).Path; pytest -q


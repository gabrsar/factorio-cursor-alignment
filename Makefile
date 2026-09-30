.DEFAULT_GOAL := help
.PHONY: help build compile test check install clean rebuild doctor

# Native Windows PowerShell; no Python or third-party modules required.
help build compile test check install clean rebuild doctor:
	powershell.exe -NoProfile -ExecutionPolicy Bypass -File ./build.ps1 -Task $@

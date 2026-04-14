param(
    [Parameter(Mandatory=$true)]
    [string]$TemplateName,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [string]$OutputDir = "D:\Codesys-MCP-main\Codesys-MCP-Test\projects",
    [string]$TemplateDir = "D:\Codesys-MCP-main\Codesys-MCP-Test\templates",
    [string]$CodesysExe = "C:\Program Files\CODESYS 3.5.19.50\CODESYS\Common\CODESYS.exe",
    [string]$Profile = "CODESYS V3.5 SP19 Patch 5"
)

$ErrorActionPreference = "Stop"

$registryPath = Join-Path $TemplateDir "template_registry.json"
$registry = Get-Content $registryPath -Raw | ConvertFrom-Json

$template = $registry.templates | Where-Object { $_.id -eq $TemplateName -or $_.name -eq $TemplateName }
if (-not $template) {
    Write-Error "Template '$TemplateName' not found. Available: $($registry.templates | ForEach-Object { $_.id })"
    exit 1
}

$templateFile = Join-Path $TemplateDir $template.file
if (-not (Test-Path $templateFile)) {
    Write-Error "Template file not found: $templateFile"
    exit 1
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$projectFile = Join-Path $OutputDir "$ProjectName.project"
Copy-Item $templateFile $projectFile -Force
Write-Host "Project created from template: $projectFile"

$scriptPath = Join-Path $OutputDir "$ProjectName._setup.py"
$scriptContent = @"
# encoding:utf-8
from __future__ import print_function
import sys

output_file = r"$($OutputDir)\$ProjectName._setup_result.txt"

def log(msg):
    with open(output_file, "a") as f:
        f.write(msg + "\n")
    print(msg)

try:
    proj = projects.open(r"$projectFile")
    log("Project opened: %s" % proj.path)

    app = proj.active_application
    log("Active application: %s" % app.get_name())

    result = app.generate_source()
    log("Build result: %s" % str(result))

    proj.save()
    log("Project saved.")

    proj.close()
    log("SETUP_SUCCESS")
except Exception as e:
    log("ERROR: %s" % str(e))
    import traceback
    log(traceback.format_exc())
    try:
        proj.close()
    except:
        pass
    sys.exit(1)
"@

Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8

$resultFile = Join-Path $OutputDir "$ProjectName._setup_result.txt"
if (Test-Path $resultFile) { Remove-Item $resultFile -Force }

Start-Process -FilePath $CodesysExe -ArgumentList "--profile=`"$Profile`"", "--runscript=`"$scriptPath`"" -NoNewWindow

$timeout = 60
$elapsed = 0
while (-not (Test-Path $resultFile) -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 1
    $elapsed++
}

if (Test-Path $resultFile) {
    Get-Content $resultFile
    if ((Get-Content $resultFile -Raw) -match "SETUP_SUCCESS") {
        Write-Host "`nProject setup completed successfully: $projectFile"
    }
} else {
    Write-Host "Timeout waiting for project setup"
}

Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
Remove-Item $resultFile -Force -ErrorAction SilentlyContinue

$TestDir = "D:\Codesys-MCP-main\Codesys-MCP-Test"
$pass = 0
$fail = 0

Write-Host "========================================"
Write-Host " CODESYS Integration Test"
Write-Host "========================================"

Write-Host "`n[1] Template Registry Check..."
try {
    $raw = Get-Content "$TestDir\templates\template_registry.json" -Raw
    $registry = $raw | ConvertFrom-Json
    if ($null -eq $registry.templates -or $registry.templates.Count -lt 1) { throw "No templates" }
    Write-Host "  PASS: Templates=$($registry.templates.Count)" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n[2] Template Project File Check..."
try {
    $f = "$TestDir\templates\Accumulator_Rev1.0.0.260412.project"
    if (-not (Test-Path $f)) { throw "File not found" }
    $sz = (Get-Item $f).Length
    Write-Host "  PASS: Size=$sz bytes" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n[3] Project Directory Check..."
try {
    $f = "$TestDir\projects\Accumulator_Rev1.0.0.260412.project"
    if (-not (Test-Path $f)) { throw "Project file not found" }
    Write-Host "  PASS: Project file exists" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n[4] Web Monitor Login API..."
try {
    $body = @{username='admin';password='admin'} | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "http://localhost:3000/api/login" -Method POST -ContentType "application/json" -Body $body
    if ($resp.role -ne "admin") { throw "Wrong role: $($resp.role)" }
    Write-Host "  PASS: Login role=$($resp.role)" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n[5] Templates API..."
try {
    $templates = Invoke-RestMethod -Uri "http://localhost:3000/api/templates"
    if ($templates.Count -lt 1) { throw "No templates" }
    Write-Host "  PASS: API templates=$($templates.Count)" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n[6] Alarm Config API..."
try {
    $alarms = Invoke-RestMethod -Uri "http://localhost:3000/api/alarm-config"
    if (-not $alarms.'PLC_PRG.nAccumulator') { throw "Alarm config missing" }
    Write-Host "  PASS: Alarm high=$($alarms.'PLC_PRG.nAccumulator'.high)" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n[7] Variable Data API..."
try {
    $data = Invoke-RestMethod -Uri "http://localhost:3000/api/variables/latest"
    if ($data.samples.Count -lt 1) { throw "No data" }
    $v = $data.samples[0].values
    Write-Host "  PASS: nAccumulator=$($v.'PLC_PRG.nAccumulator')" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n[8] User Permission Check..."
try {
    $body = @{username='viewer';password='viewer'} | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "http://localhost:3000/api/login" -Method POST -ContentType "application/json" -Body $body
    if ($resp.role -ne "viewer") { throw "Wrong role: $($resp.role)" }
    Write-Host "  PASS: Viewer role=$($resp.role)" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n[9] Frontend File Check..."
try {
    $f = "$TestDir\web-monitor\frontend\index.html"
    if (-not (Test-Path $f)) { throw "Frontend not found" }
    $c = Get-Content $f -Raw
    if ($c -notmatch "PLC_PRG.nAccumulator") { throw "Variable name mismatch" }
    Write-Host "  PASS: Frontend OK" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n[10] Backend Server Running..."
try {
    $r = Invoke-WebRequest -Uri "http://localhost:3000/" -UseBasicParsing
    if ($r.StatusCode -ne 200) { throw "Status=$($r.StatusCode)" }
    Write-Host "  PASS: HTTP 200" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "  FAIL: $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n========================================"
if ($fail -eq 0) {
    Write-Host " ALL $pass TESTS PASSED!" -ForegroundColor Green
} else {
    Write-Host " $pass PASSED, $fail FAILED" -ForegroundColor Red
}
Write-Host "========================================"

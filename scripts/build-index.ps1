# docs/index.json 생성기
#
# 뷰어가 목록을 GitHub API로 읽으면 미인증 한도(IP당 시간당 60회)에 걸린다.
# 모바일은 통신사 NAT로 IP를 공유해 특히 잘 막히고, 일부 사내망은 api.github.com 자체를 차단한다.
# 그래서 목록을 정적 파일로 만들어 Pages와 같은 출처에서 읽게 한다.
#
# 사용: powershell -ExecutionPolicy Bypass -File scripts\build-index.ps1

$ErrorActionPreference = 'Stop'
$Root    = Split-Path -Parent $PSScriptRoot
$DocsDir = Join-Path $Root 'docs'
$RepDir  = Join-Path $DocsDir 'reports'
$WipDir  = Join-Path $RepDir '_wip'
$OutFile = Join-Path $DocsDir 'index.json'

$reports = @()
if (Test-Path $RepDir) {
    $reports = Get-ChildItem $RepDir -Filter '*-on-device-ai-briefing.md' -File |
        Where-Object { $_.Name -match '^(\d{4}-\d{2}-\d{2})-' } |
        ForEach-Object {
            [pscustomobject]@{
                date = $Matches[1]
                file = $_.Name
                size = $_.Length
            }
        } | Sort-Object date -Descending
}

$wip = @()
if (Test-Path $WipDir) {
    $wip = Get-ChildItem $WipDir -Directory |
        Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' } |
        Sort-Object Name -Descending |
        ForEach-Object { $_.Name }
}

$manifest = [pscustomobject]@{
    generated = (Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')
    reports   = @($reports)
    wip       = @($wip)
}

# PowerShell 5.1의 ConvertTo-Json은 단일 원소 배열을 벗겨내므로 -Depth 를 명시한다
$json = $manifest | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($OutFile, $json, [System.Text.UTF8Encoding]::new($false))

Write-Output "index.json 생성: 리포트 $(@($reports).Count)건 / 생성중 $(@($wip).Count)건 -> $OutFile"

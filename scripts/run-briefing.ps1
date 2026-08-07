# On-device AI 동향 브리핑 — 로컬 스케줄 실행기
# Windows 작업 스케줄러가 매일 08:00 KST에 이 스크립트를 호출한다.
# 수동 실행:  powershell -ExecutionPolicy Bypass -File scripts\run-briefing.ps1

$ErrorActionPreference = 'Continue'

# 스크립트 위치 기준으로 프로젝트 루트를 잡는다 (작업 스케줄러의 CWD에 의존하지 않도록)
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$Date    = Get-Date -Format 'yyyy-MM-dd'
$Stamp   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$LogDir  = Join-Path $ProjectRoot 'logs'
$LogFile = Join-Path $LogDir "$Date-briefing.log"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

function Log($msg) {
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Add-Content -Path $LogFile -Value $line -Encoding utf8
}

Log "===== 브리핑 실행 시작 ($Stamp) ====="
Log "프로젝트 루트: $ProjectRoot"

# git 인증 프롬프트가 뜨면 스케줄 작업이 무한 대기하므로 차단한다.
# push가 실패해도 리포트는 로컬에 남으므로 치명적이지 않다.
$env:GIT_TERMINAL_PROMPT = '0'

# 최신 상태에서 시작 (다른 기기에서 올린 리포트가 있을 수 있음)
git pull --rebase --autostash 2>&1 | ForEach-Object { Log "git: $_" }

$Prompt = @'
오늘자 On-device AI 동향 브리핑 리포트를 작성하라.
에이전트 정의(.claude/agents/on-device-ai-monitor.md)의 실행 절차를 그대로 따른다.
6개 도메인을 병렬로 조사하고, 완료된 섹션은 docs/reports/_wip/ 에 즉시 저장하며,
체크포인트마다 git commit & push 한다.
전체판은 reports/_internal/YYYY-MM-DD-on-device-ai-briefing.md 에,
공개판은 docs/reports/YYYY-MM-DD-on-device-ai-briefing.md 에 저장한다.
'@

$AllowedTools = @(
    'Read', 'Write', 'Edit', 'Glob', 'Grep',
    'WebSearch', 'WebFetch', 'Agent', 'Task', 'TodoWrite',
    'Bash(git:*)', 'Bash(mkdir:*)', 'Bash(date:*)', 'Bash(ls:*)'
) -join ','

Log "claude 실행 (model=opus, agent=on-device-ai-monitor)"

$ClaudeOut = & claude -p $Prompt `
    --agent on-device-ai-monitor `
    --model opus `
    --permission-mode acceptEdits `
    --allowedTools $AllowedTools 2>&1

$ExitCode = $LASTEXITCODE

$ClaudeOut | ForEach-Object { Add-Content -Path $LogFile -Value $_ -Encoding utf8 }

$ReportPath = Join-Path $ProjectRoot "docs\reports\$Date-on-device-ai-briefing.md"
if (Test-Path $ReportPath) {
    Log "SUCCESS — 리포트 생성 완료: $ReportPath"
} else {
    Log "WARNING — 리포트 파일이 없다: $ReportPath (claude exit=$ExitCode)"
}

# 뷰어가 읽는 목록 파일을 항상 다시 만든다.
# 에이전트가 빠뜨려도 여기서 보정되므로 목록이 어긋날 일이 없다.
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'build-index.ps1') 2>&1 |
    ForEach-Object { Log "index: $_" }

# 에이전트가 push하지 못한 변경이 남아 있으면 여기서 한 번 더 시도한다
$Dirty = git status --porcelain
if ($Dirty) {
    Log "미커밋 변경 감지 — 마무리 커밋 시도"
    git add -A 2>&1 | ForEach-Object { Log "git: $_" }
    git commit -m "brief: $Date on-device AI 동향 (스케줄 실행 마무리)" 2>&1 | ForEach-Object { Log "git: $_" }
}
git push 2>&1 | ForEach-Object { Log "git: $_" }

Log "===== 종료 (exit=$ExitCode) ====="
exit $ExitCode

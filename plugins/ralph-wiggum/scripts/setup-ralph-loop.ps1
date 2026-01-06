<#
.SYNOPSIS
    Ralph Loop Setup Script - Windows PowerShell Version
.DESCRIPTION
    Creates state file for in-session Ralph loop
.EXAMPLE
    setup-ralph-loop.ps1 "Build a todo API" --max-iterations 20 --completion-promise "DONE"
#>

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"

# Parse arguments
$promptParts = @()
$maxIterations = 0
$completionPromise = "null"
$showHelp = $false

$i = 0
while ($i -lt $Arguments.Count) {
    $arg = $Arguments[$i]

    switch -Regex ($arg) {
        '^(-h|--help)$' {
            $showHelp = $true
            $i++
        }
        '^--max-iterations$' {
            $i++
            if ($i -lt $Arguments.Count) {
                $val = $Arguments[$i]
                if ($val -match '^\d+$') {
                    $maxIterations = [int]$val
                } else {
                    Write-Host "Error: --max-iterations must be a positive integer, got: $val" -ForegroundColor Red
                    exit 1
                }
            } else {
                Write-Host "Error: --max-iterations requires a number argument" -ForegroundColor Red
                exit 1
            }
            $i++
        }
        '^--completion-promise$' {
            $i++
            if ($i -lt $Arguments.Count) {
                $completionPromise = $Arguments[$i]
            } else {
                Write-Host "Error: --completion-promise requires a text argument" -ForegroundColor Red
                exit 1
            }
            $i++
        }
        default {
            $promptParts += $arg
            $i++
        }
    }
}

# Show help
if ($showHelp) {
    @"
Ralph Loop - Interactive self-referential development loop

USAGE:
  /ralph-wiggum:ralph-loop [PROMPT...] [OPTIONS]

ARGUMENTS:
  PROMPT...    Initial prompt to start the loop (can be multiple words)

OPTIONS:
  --max-iterations <n>           Maximum iterations before auto-stop (default: unlimited)
  --completion-promise '<text>'  Promise phrase to signal completion
  -h, --help                     Show this help message

DESCRIPTION:
  Starts a Ralph Wiggum loop in your CURRENT session. The stop hook prevents
  exit and feeds your output back as input until completion or iteration limit.

  To signal completion, output: <promise>YOUR_PHRASE</promise>

EXAMPLES:
  /ralph-wiggum:ralph-loop Build a todo API --completion-promise DONE --max-iterations 20
  /ralph-wiggum:ralph-loop Fix the auth bug --max-iterations 10
  /ralph-wiggum:ralph-loop Refactor cache layer

STOPPING:
  Only by reaching --max-iterations or detecting --completion-promise
  Use /ralph-wiggum:cancel-ralph to force stop

MONITORING:
  View current iteration:
    Get-Content .claude/ralph-loop.local.md | Select-String "iteration:"
"@
    exit 0
}

# Join prompt parts
$prompt = $promptParts -join " "

# Validate prompt
if ([string]::IsNullOrWhiteSpace($prompt)) {
    Write-Host "Error: No prompt provided" -ForegroundColor Red
    Write-Host ""
    Write-Host "Ralph needs a task description to work on."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  /ralph-wiggum:ralph-loop Build a REST API for todos"
    Write-Host "  /ralph-wiggum:ralph-loop Fix the auth bug --max-iterations 20"
    Write-Host ""
    Write-Host "For all options: /ralph-wiggum:ralph-loop --help"
    exit 1
}

# Create state directory
$stateDir = ".claude"
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

# Format completion promise for YAML
$completionPromiseYaml = if ($completionPromise -and $completionPromise -ne "null") {
    "`"$completionPromise`""
} else {
    "null"
}

# Create state file
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$stateContent = @"
---
active: true
iteration: 1
max_iterations: $maxIterations
completion_promise: $completionPromiseYaml
started_at: "$timestamp"
---

$prompt
"@

Set-Content ".claude/ralph-loop.local.md" -Value $stateContent

# Output setup message
Write-Host ""
Write-Host "Ralph loop activated in this session!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Iteration: 1"
if ($maxIterations -gt 0) {
    Write-Host "Max iterations: $maxIterations"
} else {
    Write-Host "Max iterations: unlimited"
}
if ($completionPromise -and $completionPromise -ne "null") {
    Write-Host "Completion promise: $completionPromise (ONLY output when TRUE!)"
} else {
    Write-Host "Completion promise: none (runs forever)"
}
Write-Host ""
Write-Host "The stop hook is now active. When you try to exit, the SAME PROMPT will be"
Write-Host "fed back to you. You'll see your previous work in files, creating a"
Write-Host "self-referential loop where you iteratively improve on the same task."
Write-Host ""
Write-Host "To monitor: Get-Content .claude/ralph-loop.local.md"
Write-Host ""
Write-Host "WARNING: This loop cannot be stopped manually! It will run infinitely" -ForegroundColor Yellow
Write-Host "    unless you set --max-iterations or --completion-promise." -ForegroundColor Yellow
Write-Host ""

# Output the prompt
Write-Host $prompt
Write-Host ""

# Display completion promise requirements if set
if ($completionPromise -and $completionPromise -ne "null") {
    Write-Host "===============================================================" -ForegroundColor Magenta
    Write-Host "CRITICAL - Ralph Loop Completion Promise" -ForegroundColor Magenta
    Write-Host "===============================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "To complete this loop, output this EXACT text:"
    Write-Host "  <promise>$completionPromise</promise>" -ForegroundColor Green
    Write-Host ""
    Write-Host "STRICT REQUIREMENTS (DO NOT VIOLATE):"
    Write-Host "  - Use <promise> XML tags EXACTLY as shown above"
    Write-Host "  - The statement MUST be completely and unequivocally TRUE"
    Write-Host "  - Do NOT output false statements to exit the loop"
    Write-Host "  - Do NOT lie even if you think you should exit"
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Magenta
}

exit 0

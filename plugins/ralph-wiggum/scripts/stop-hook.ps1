<#
.SYNOPSIS
    Ralph Wiggum Stop Hook - Windows PowerShell Version
.DESCRIPTION
    Prevents session exit when a ralph-loop is active.
    Feeds Claude's output back as input to continue the loop.
#>

$ErrorActionPreference = "Stop"

# Read hook input from stdin
$hookInput = $null
try {
    $inputLines = @()
    while ($line = [Console]::In.ReadLine()) {
        $inputLines += $line
    }
    $hookInputJson = $inputLines -join "`n"
    if ($hookInputJson) {
        $hookInput = $hookInputJson | ConvertFrom-Json
    }
} catch {
    # Silently continue if no input
}

# Check if ralph-loop is active
$ralphStateFile = ".claude/ralph-loop.local.md"

if (-not (Test-Path $ralphStateFile)) {
    # No active loop - allow exit
    exit 0
}

# Read state file content
$stateContent = Get-Content $ralphStateFile -Raw

# Parse YAML frontmatter (between --- markers)
$frontmatterMatch = [regex]::Match($stateContent, '(?s)^---\r?\n(.*?)\r?\n---')
if (-not $frontmatterMatch.Success) {
    Write-Error "Ralph loop: State file corrupted - no frontmatter found"
    Remove-Item $ralphStateFile -Force
    exit 0
}

$frontmatter = $frontmatterMatch.Groups[1].Value

# Extract values from frontmatter
$iteration = 0
$maxIterations = 0
$completionPromise = $null

foreach ($line in ($frontmatter -split "`n")) {
    $line = $line.Trim()
    if ($line -match '^iteration:\s*(\d+)') {
        $iteration = [int]$Matches[1]
    }
    elseif ($line -match '^max_iterations:\s*(\d+)') {
        $maxIterations = [int]$Matches[1]
    }
    elseif ($line -match '^completion_promise:\s*"?([^"]*)"?') {
        $completionPromise = $Matches[1]
        if ($completionPromise -eq "null") { $completionPromise = $null }
    }
}

# Validate iteration
if ($iteration -le 0) {
    Write-Host "Ralph loop: State file corrupted - invalid iteration" -ForegroundColor Yellow
    Remove-Item $ralphStateFile -Force
    exit 0
}

# Check if max iterations reached
if ($maxIterations -gt 0 -and $iteration -ge $maxIterations) {
    Write-Host "Ralph loop: Max iterations ($maxIterations) reached." -ForegroundColor Red
    Remove-Item $ralphStateFile -Force
    exit 0
}

# Get transcript path from hook input
$transcriptPath = $null
if ($hookInput -and $hookInput.transcript_path) {
    $transcriptPath = $hookInput.transcript_path
}

if (-not $transcriptPath -or -not (Test-Path $transcriptPath)) {
    Write-Host "Ralph loop: Transcript file not found" -ForegroundColor Yellow
    Remove-Item $ralphStateFile -Force
    exit 0
}

# Read transcript and find last assistant message
$transcriptContent = Get-Content $transcriptPath -Raw
$lastAssistantOutput = ""

# JSONL format - each line is a JSON object
$lines = $transcriptContent -split "`n" | Where-Object { $_ -match '"role"\s*:\s*"assistant"' }

if ($lines.Count -eq 0) {
    Write-Host "Ralph loop: No assistant messages in transcript" -ForegroundColor Yellow
    Remove-Item $ralphStateFile -Force
    exit 0
}

$lastLine = $lines[-1]

try {
    $lastMessage = $lastLine | ConvertFrom-Json

    # Extract text content from message
    if ($lastMessage.message -and $lastMessage.message.content) {
        $textParts = $lastMessage.message.content | Where-Object { $_.type -eq "text" }
        $lastAssistantOutput = ($textParts | ForEach-Object { $_.text }) -join "`n"
    }
} catch {
    Write-Host "Ralph loop: Failed to parse transcript JSON" -ForegroundColor Yellow
    Remove-Item $ralphStateFile -Force
    exit 0
}

if ([string]::IsNullOrWhiteSpace($lastAssistantOutput)) {
    Write-Host "Ralph loop: Assistant message contained no text" -ForegroundColor Yellow
    Remove-Item $ralphStateFile -Force
    exit 0
}

# Check for completion promise
if ($completionPromise) {
    # Extract text from <promise> tags
    $promiseMatch = [regex]::Match($lastAssistantOutput, '<promise>(.*?)</promise>', [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if ($promiseMatch.Success) {
        $promiseText = $promiseMatch.Groups[1].Value.Trim()
        $promiseText = $promiseText -replace '\s+', ' '

        if ($promiseText -eq $completionPromise) {
            Write-Host "Ralph loop: Detected <promise>$completionPromise</promise>" -ForegroundColor Green
            Remove-Item $ralphStateFile -Force
            exit 0
        }
    }
}

# Not complete - continue loop with SAME PROMPT
$nextIteration = $iteration + 1

# Extract prompt (everything after the closing ---)
$promptMatch = [regex]::Match($stateContent, '(?s)^---\r?\n.*?\r?\n---\r?\n(.*)$')
$promptText = ""
if ($promptMatch.Success) {
    $promptText = $promptMatch.Groups[1].Value.Trim()
}

if ([string]::IsNullOrWhiteSpace($promptText)) {
    Write-Host "Ralph loop: State file corrupted - no prompt found" -ForegroundColor Yellow
    Remove-Item $ralphStateFile -Force
    exit 0
}

# Update iteration in state file
$updatedContent = $stateContent -replace 'iteration:\s*\d+', "iteration: $nextIteration"
Set-Content $ralphStateFile -Value $updatedContent -NoNewline

# Build system message
if ($completionPromise) {
    $systemMsg = "Ralph iteration $nextIteration | To stop: output <promise>$completionPromise</promise> (ONLY when statement is TRUE - do not lie to exit!)"
} else {
    $systemMsg = "Ralph iteration $nextIteration | No completion promise set - loop runs infinitely"
}

# Output JSON to block the stop and feed prompt back
$response = @{
    decision = "block"
    reason = $promptText
    systemMessage = $systemMsg
}

$response | ConvertTo-Json -Compress

exit 0

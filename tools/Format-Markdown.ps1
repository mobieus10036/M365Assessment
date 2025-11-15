Param(
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]$Root = (Get-Location).Path,
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Remove-Emojis([string]$text) {
    # Remove common emoji ranges and variation selectors, plus surrogate pairs
    $text = [Regex]::Replace($text, "[\u2600-\u27BF\uFE0F]", "")
    $text = [Regex]::Replace($text, "[\uD83C-\uDBFF][\uDC00-\uDFFF]", "")
    return $text
}

function Normalize-Markdown([string]$text) {
    # Ensure single trailing newline
    $text = $text -replace "\s+$", ""
    # Collapse 3+ blank lines to 2
    $text = [Regex]::Replace($text, "(\r?\n){3,}", "`n`n")
    # Ensure blank line before fenced code blocks
    $text = [Regex]::Replace($text, "(?m)([^\r\n])\r?\n```", "$1`n`n```")
    # Ensure blank line after fenced code blocks
    $text = [Regex]::Replace($text, "(?m)```\r?\n([^\r\n])", "````n`n$1")
    # Ensure blank line before headings
    $text = [Regex]::Replace($text, "(?m)([^\r\n])\r?\n(#+\s)", "$1`n`n$2")
    # Ensure blank line before list blocks
    $text = [Regex]::Replace($text, "(?m)(?<!^)([^\r\n])\r?\n(-\s|\d+\.\s)", "$1`n`n$2")
    # Wrap bare URLs in angle brackets
    $text = [Regex]::Replace($text, "(?<!\]|\))\bhttps?://\S+", { param($m) "<" + $m.Value.TrimEnd('.', ',', ';', ')') + ">" })
    return $text + "`n"
}

$mdFiles = Get-ChildItem -Path $Root -Recurse -File -Include *.md
if (-not $mdFiles) { return }

foreach ($file in $mdFiles) {
    $orig = [IO.File]::ReadAllText($file.FullName)
    $text = Remove-Emojis $orig
    $text = Normalize-Markdown $text
    if ($text -ne $orig) {
        if ($WhatIf) {
            Write-Host "Would update: $($file.FullName)"
        } else {
            [IO.File]::WriteAllText($file.FullName, $text, [Text.Encoding]::UTF8)
            Write-Host "Updated: $($file.FullName)"
        }
    }
}

Write-Host "Markdown formatting complete."
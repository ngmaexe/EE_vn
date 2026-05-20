param(
  [Parameter(Mandatory = $true)]
  [string]$file
)

$ErrorActionPreference = "Stop"

# Root folder = folder where this script is located
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$booksDir = Join-Path $root "Books"
$navDir   = Join-Path $root "Navigation"
$source   = Join-Path $booksDir $file
$dest     = Join-Path $navDir "temp.html"

# Check folders
if (-not (Test-Path $booksDir)) {
  Write-Host "Loi: Khong tim thay thu muc Books."
  exit 1
}

if (-not (Test-Path $navDir)) {
  New-Item -ItemType Directory -Path $navDir | Out-Null
}

# Check source file
if (-not (Test-Path $source)) {
  Write-Host "Loi: File '$file' khong ton tai trong thu muc Books."
  Write-Host ""
  Write-Host "Cac file HTML hien co trong Books:"
  Get-ChildItem -Path $booksDir -Filter *.html | ForEach-Object {
    Write-Host ("- " + $_.Name)
  }
  exit 1
}

# Read HTML
$content = Get-Content -Raw -Path $source -Encoding UTF8

# Prefer book_toc area if available, otherwise use whole file
$tocStart = $content.IndexOf('<div class="book_toc"', [StringComparison]::InvariantCultureIgnoreCase)

if ($tocStart -ge 0) {
  $tocSegment = $content.Substring($tocStart)
} else {
  $tocSegment = $content
}

# Find all links like href="#ch1", href="#ch01", href='#ch2'
$pattern = '<a\s+[^>]*href\s*=\s*["'']#(?<id>ch\d+)["''][^>]*>(?<text>.*?)</a\s*>'

$matches = [regex]::Matches(
  $tocSegment,
  $pattern,
  [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
  [Text.RegularExpressions.RegexOptions]::Singleline
)

$items = @()
$seen = @{}

foreach ($m in $matches) {
  $id = $m.Groups["id"].Value.Trim()

  if ($id -eq "ch00") {
    continue
  }

  # Clean anchor text
  $text = $m.Groups["text"].Value

  # Remove HTML comments
  $text = [regex]::Replace($text, '<!--.*?-->', '', 'Singleline')

  # Remove any remaining HTML tags inside title
  $text = [regex]::Replace($text, '<[^>]+>', '', 'Singleline')

  # Decode HTML entities: &nbsp;, &amp;, etc.
  $text = [System.Net.WebUtility]::HtmlDecode($text)

  # Normalize whitespace
  $text = $text -replace [char]160, ' '
  $text = [regex]::Replace($text, '\s+', ' ').Trim()

  if ([string]::IsNullOrWhiteSpace($text)) {
    continue
  }

  # Avoid duplicate chapter IDs
  if ($seen.ContainsKey($id)) {
    continue
  }

  $seen[$id] = $true

  $items += [pscustomobject]@{
    Id   = $id
    Text = $text
  }
}

if ($items.Count -eq 0) {
  Write-Host "Loi: Khong tim thay muc luc trong '$file'."
  Write-Host "Can co cac link dang: <a href=""#ch1"">...</a>"
  exit 1
}

# Build heading and href
$bookCode = [System.IO.Path]::GetFileNameWithoutExtension($file)

# If file is SS_10.html, heading becomes 10
# If file is upanishadKeno.html, heading remains upanishadKeno
$heading = $bookCode -replace '^SS_', ''

$hrefBase = "../Books/$file"

# Build clean output
$output = New-Object System.Collections.Generic.List[string]

$output.Add('<div class="book_section">')
$output.Add('  <h3>')
$output.Add('    <a href="' + $hrefBase + '" target="Client">' + [System.Net.WebUtility]::HtmlEncode($heading) + '</a>')
$output.Add('  </h3>')
$output.Add('')
$output.Add('  <ul>')

foreach ($item in $items) {
  $safeText = [System.Net.WebUtility]::HtmlEncode($item.Text)

  $output.Add('    <li>')
  $output.Add('      <a href="' + $hrefBase + '#' + $item.Id + '" target="Client">' + $safeText + '</a>')
  $output.Add('    </li>')
  $output.Add('')
}

$output.Add('  </ul>')
$output.Add('</div>')

# Save as UTF-8
$output | Set-Content -Path $dest -Encoding UTF8

Write-Host ""
Write-Host "Da tao thanh cong:"
Write-Host $dest
Write-Host ""
Write-Host "So muc luc da tao: $($items.Count)"
Write-Host "Ban co the copy noi dung trong Navigation\temp.html vao Navigation\booklist.html."
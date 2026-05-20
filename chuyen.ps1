param(
  [string]$file
)

if (-not $file) {
  Write-Host "Usage: chuyen file.html"
  Write-Host "Example: chuyen SS_10.html"
  Write-Host "File HTML phai nam trong thu muc Books."
  exit 1
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $root "Books\$file"
$dest = Join-Path $root "Navigation\temp.html"

if (-not (Test-Path $source)) {
  Write-Host "Loi: File '$file' khong ton tai trong thu muc Books."
  Write-Host "Cac file Books hien co:"
  Get-ChildItem -Path (Join-Path $root 'Books') -Filter *.html | ForEach-Object { Write-Host $_.Name }
  exit 1
}

$content = Get-Content -Raw -Path $source -Encoding UTF8

$tocStart = $content.IndexOf('<div class="book_toc"', [StringComparison]::InvariantCultureIgnoreCase)
if ($tocStart -ge 0) {
  $tocSegment = $content.Substring($tocStart)
  $tocEnd = $tocSegment.IndexOf('</div>', [StringComparison]::InvariantCultureIgnoreCase)
  if ($tocEnd -gt 0) {
    $tocSegment = $tocSegment.Substring(0, $tocEnd)
  }
} else {
  $tocSegment = $content
}

$matches = [regex]::Matches($tocSegment, '<a\s+href="#(?<id>ch\d+)"[^>]*>(?<text>.*?)</a>', [Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [Text.RegularExpressions.RegexOptions]::Singleline)

$items = @()
foreach ($m in $matches) {
  $id = $m.Groups['id'].Value
  if ($id -eq 'ch00') { continue }
  $text = $m.Groups['text'].Value.Trim()
  if (-not [string]::IsNullOrWhiteSpace($text)) {
    $items += [pscustomobject]@{ Id = $id; Text = $text }
  }
}

if ($items.Count -eq 0) {
  Write-Host "Loi: Khong tim thay noi dung muc luc trong '$file'."
  Write-Host "Hay kiem tra cau truc file va thu lai."
  exit 1
}

$bookCode = [System.IO.Path]::GetFileNameWithoutExtension($file)
$bookSuffix = $bookCode -replace '^SS_', ''
$heading = "$bookSuffix"
$hrefBase = "../Books/$file"

$output = @()
$output += '<div class="book_section">'
$output += '  <h3>'
$output += ('    <a href="' + $hrefBase + '" target="Client">' + $heading + '</a>')
$output += '  </h3>'
$output += '  <ul>'
foreach ($item in $items) {
  $output += '    <li>'
  $output += ('      <a href="' + $hrefBase + '#'+ $item.Id + '" target="Client">' + $item.Text + '</a>')
  $output += '    </li>'
}
$output += '  </ul>'
$output += '</div>'

$output | Set-Content -Path $dest -Encoding UTF8

Write-Host "Da tao noi dung book_section cho '$file' vao '$dest'."
Write-Host "Mo 'Navigation\temp.html' de chinh sua va copy noi dung vao 'Navigation\booklist.html'."

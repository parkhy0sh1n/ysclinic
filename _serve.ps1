$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$prefix = 'http://localhost:8000/'
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try {
    $listener.Start()
} catch {
    Write-Host "BIND_FAILED: $($_.Exception.Message)"
    exit 1
}
Write-Host "SERVING $root AT $prefix"

$mime = @{
    '.html' = 'text/html; charset=utf-8'; '.htm' = 'text/html; charset=utf-8';
    '.css' = 'text/css; charset=utf-8'; '.js' = 'application/javascript; charset=utf-8';
    '.json' = 'application/json; charset=utf-8'; '.png' = 'image/png'; '.jpg' = 'image/jpeg';
    '.jpeg' = 'image/jpeg'; '.gif' = 'image/gif'; '.svg' = 'image/svg+xml'; '.webp' = 'image/webp';
    '.ico' = 'image/x-icon'; '.mp4' = 'video/mp4'; '.woff' = 'font/woff'; '.woff2' = 'font/woff2';
    '.ttf' = 'font/ttf'; '.xml' = 'application/xml; charset=utf-8'; '.txt' = 'text/plain; charset=utf-8'
}

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $req = $ctx.Request
        $res = $ctx.Response
        $rel = [System.Uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart('/'))
        if ([string]::IsNullOrEmpty($rel)) { $rel = 'index.html' }
        $path = Join-Path $root $rel
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($path).ToLower()
            $ct = $mime[$ext]; if (-not $ct) { $ct = 'application/octet-stream' }
            $res.ContentType = $ct
            $bytes = [System.IO.File]::ReadAllBytes($path)
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $res.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found: ' + $rel)
            $res.OutputStream.Write($msg, 0, $msg.Length)
        }
        $res.OutputStream.Close()
    } catch {
        # per-request error, keep serving
    }
}

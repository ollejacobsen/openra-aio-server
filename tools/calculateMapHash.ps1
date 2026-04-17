#.\calculateMapHash.ps1 -mapFolder 'D:\your\maps\path' -utility 'C:\path\to\OpenRA.Utility.exe'
param(
    [Parameter(Mandatory = $true)]
    [string]$mapFolder,
    [Parameter(Mandatory = $true)]
    [string]$utility
)

$maps = Get-ChildItem -Path $mapFolder -Filter *.oramap
if ($maps.Count -eq 0) {
    Write-Host "No .oramap files found in $mapFolder"
}
foreach ($map in $maps) {
    $file = $map.FullName
    Write-Host "Hash for ${file}:"
    $hash = & $utility ra --map-hash $file
    if ($hash) {
        $outFile = "$($map.FullName).$hash"
        Write-Host "Creating $outFile"
        New-Item -Path $outFile -ItemType File -Force | Out-Null
    }
}
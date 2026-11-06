param([switch] $UsePublicBucket)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne 'X64') {
    throw 'This consumer requires a Windows x64 runner.'
}

$package = 'qrcode-barcode-scanner'
$scoopCommit = 'e6aa3b366bdee8ed138c1e0f7b85192ebdd35d0f' # Scoop v0.6.0
$scannerCommit = '176ac96ef16ee330dbfc6ada10327d0b4e23a8b2' # Scanner v0.11.0
$fixtureHash = 'c636e8d56df483ff1ec06dbe9b5bcba226c579f8fc1c3d10c4ccf4e100762ec8'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = "bucket/$package.json"
$manifestFile = Join-Path $root $manifestPath
$manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
$version = $manifest.version
$work = Join-Path $env:RUNNER_TEMP 'Scoop consumer test'
$env:SCOOP = Join-Path $work 'scoop'
$env:SCOOP_CACHE = Join-Path $work 'cache'
$env:SCOOP_GLOBAL = Join-Path $work 'global'
$env:XDG_CONFIG_HOME = Join-Path $work 'config'
$shims = Join-Path $env:SCOOP 'shims'
$env:PATH = "$shims;$env:PATH"

# Bootstrap the official Scoop core in its usual directory without a floating installer.
$core = Join-Path $env:SCOOP 'apps/scoop/current'
New-Item -ItemType Directory -Path $core -Force | Out-Null
git -C $core init --quiet
git -C $core fetch --quiet --depth=1 https://github.com/ScoopInstaller/Scoop.git $scoopCommit
git -C $core checkout --quiet --detach FETCH_HEAD
$scoop = Join-Path $core 'bin/scoop.ps1'
& $scoop config aria2-enabled false

$bucketUrl = if ($UsePublicBucket) {
    'https://github.com/qrcode-ai-com/scoop-bucket.git'
} else {
    ([uri] $root).AbsoluteUri
}
& $scoop bucket add qrcode-ai $bucketUrl
if ($LASTEXITCODE -ne 0) { throw 'Scoop could not add the bucket.' }
$bucketPath = Join-Path $env:SCOOP 'buckets/qrcode-ai'
$bucketCommit = git -C $bucketPath rev-parse HEAD
$candidateCommit = git -C $root rev-parse HEAD
if ($bucketCommit -cne $candidateCommit) {
    throw "Tested bucket commit $bucketCommit differs from candidate $candidateCommit."
}
$manifestHash = (Get-FileHash -LiteralPath $manifestFile -Algorithm SHA256).Hash
$bucketManifestHash = (Get-FileHash -LiteralPath (Join-Path $bucketPath $manifestPath) -Algorithm SHA256).Hash
if ($manifestHash -cne $bucketManifestHash) { throw 'The installed bucket manifest differs from the candidate.' }

& $scoop install "qrcode-ai/$package" --no-update-scoop
if ($LASTEXITCODE -ne 0) { throw 'Scoop installation failed.' }
$installed = Join-Path $env:SCOOP "apps/$package/$version"
if (!(Test-Path -LiteralPath (Join-Path $installed 'qrscan.exe') -PathType Leaf)) {
    throw "Scoop did not install qrscan.exe into $installed."
}
$shim = (Get-Command qrscan -CommandType Application).Source
if ($shim -ine (Join-Path $shims 'qrscan.exe')) { throw "Unexpected qrscan shim $shim." }

Push-Location $work
try {
    $banner = ((& qrscan --version) -join "`n").TrimEnd()
    if ($banner -cne "qrscan $version") { throw "Unexpected version banner $banner." }

    $fixture = 'mixed codes.png'
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/qrcode-ai-com/qrcode-barcode-scanner/$scannerCommit/fixtures/symbology/mixed-code128-qr.png" -OutFile $fixture
    if ((Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash -ine $fixtureHash) {
        throw 'Mixed-symbol fixture SHA-256 mismatch.'
    }
    $profiles = foreach ($profile in 'fast', 'frame', 'full') {
        $report = (& qrscan $fixture --profile $profile --budget-ms 0) | ConvertFrom-Json
        $found = @($report.detections | ForEach-Object { "$($_.symbology):$($_.content.text)" })
        if ($report.versions.scanner -cne $version -or $report.trace.engine_panics -ne 0 -or
            $report.trace.budget_exhausted -cne $false -or $found.Count -ne 2 -or
            $found -cnotcontains 'code128:STOCK-4827' -or $found -cnotcontains 'qr_code:https://qrc-ai.com/76xMa') {
            throw "Unexpected $profile report: $($report | ConvertTo-Json -Depth 20 -Compress)."
        }
        [ordered]@{ profile = $profile; detections = $found }
    }
} finally {
    Pop-Location
}

& $scoop uninstall $package
if ($LASTEXITCODE -ne 0 -or (Test-Path -LiteralPath $shim) -or
    (Test-Path -LiteralPath $installed) -or (Get-Command qrscan -ErrorAction SilentlyContinue)) {
    throw 'Uninstall did not remove the app and its PATH entry.'
}
if ((git -C $core rev-parse HEAD) -cne $scoopCommit) { throw 'Scoop core changed during the consumer run.' }

[ordered]@{
    version = $version
    platform = 'windows-x64'
    public_bucket = $UsePublicBucket.IsPresent
    bucket_commit = $bucketCommit
    scoop_commit = $scoopCommit
    scanner_commit = $scannerCommit
    manifest_sha256 = $manifestHash.ToLowerInvariant()
    archive_url = $manifest.architecture.'64bit'.url
    archive_sha256 = $manifest.architecture.'64bit'.hash
    fixture_sha256 = $fixtureHash
    version_banner = $banner
    scan_profiles = @($profiles)
    uninstalled = $true
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $env:RUNNER_TEMP 'scoop-consumer-receipt.json') -Encoding utf8

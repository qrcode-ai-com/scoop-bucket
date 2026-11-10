# QR Code AI Scoop bucket

Install `qrscan`, the [QR Code AI](https://qrcode-ai.com/en-US/qr-code-scanner/cli) command-line scanner, with Scoop on Windows x64. It decodes QR codes, barcodes and supported 2D codes from local image files. The scanner returns decoded data as JSON by default and works without a web account.

## Install and scan

Install [Scoop](https://scoop.sh/) and make sure `git` is on your PATH. Run the following commands in PowerShell.

```powershell
scoop bucket add qrcode-ai https://github.com/qrcode-ai-com/scoop-bucket.git
scoop install qrcode-ai/qrcode-barcode-scanner
qrscan --version
qrscan '.\my label.png' --profile full
```

Replace `my label.png` with your image.

| | QR codes | Barcodes |
| --- | --- | --- |
| **Try the scanner live** | [QR code scanner](https://qrcode-ai.com/en-US/qr-code-scanner) | [Barcode scanner](https://qrcode-ai.com/en-US/barcode-scanner) |
| **Command line guide** | [QR code scanner for the command line](https://qrcode-ai.com/en-US/qr-code-scanner/cli) | [Barcode scanner for the command line](https://qrcode-ai.com/en-US/barcode-scanner/cli) |
| **Create a code** | [QR code generator](https://qrcode-ai.com/en-US/qr-code-generator) | [Barcode generator](https://qrcode-ai.com/en-US/barcode-generator) |

## Try a QR code and Code 128 in one image

```powershell
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/qrcode-ai-com/qrcode-barcode-scanner/v0.11.0/fixtures/symbology/mixed-code128-qr.png' -OutFile 'mixed-codes.png'
qrscan .\mixed-codes.png --profile fast
```

The JSON `detections` includes the QR URL and Code 128 value `STOCK-4827`.

## Update or remove the CLI

```powershell
scoop update qrcode-barcode-scanner
scoop uninstall qrcode-barcode-scanner
```

Remove the bucket with `scoop bucket rm qrcode-ai` if you no longer need it.

## Release and source

The manifest installs the Windows x64 ZIP from [scanner release 0.11.0](https://github.com/qrcode-ai-com/qrcode-barcode-scanner/releases/tag/v0.11.0). Scoop verifies its SHA-256 against the manifest. The release also provides the [exact corresponding source archive](https://github.com/qrcode-ai-com/qrcode-barcode-scanner/releases/download/v0.11.0/qrcode-barcode-scanner-cli-0.11.0-source.tar.gz) and [checksums for source and binaries](https://github.com/qrcode-ai-com/qrcode-barcode-scanner/releases/download/v0.11.0/qrcode-barcode-scanner-cli-0.11.0-SHA256SUMS). The scanner is available under [AGPL-3.0-or-later](https://github.com/qrcode-ai-com/qrcode-barcode-scanner/blob/176ac96ef16ee330dbfc6ada10327d0b4e23a8b2/LICENSING.md). The binary ZIP includes the license and third-party notices.

Report scanning issues in the [scanner repository](https://github.com/qrcode-ai-com/qrcode-barcode-scanner/issues). Report Scoop installation issues in this repository.

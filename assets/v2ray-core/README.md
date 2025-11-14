# V2Ray Core Files

This directory contains V2Ray core binaries required for Windows desktop version.

## Files (Auto-downloaded)

The following files are automatically downloaded during build:
- `v2ray.exe` - V2Ray core executable
- `geoip.dat` - IP geolocation database
- `geosite.dat` - Domain geolocation database

## Manual Download

If you need to download manually, run:

```powershell
.\scripts\download_v2ray_core.ps1
```

Or download from: https://github.com/v2fly/v2ray-core/releases

## Note

These files are excluded from git due to their large size (see `.gitignore`).
They are automatically downloaded during:
1. GitHub Actions build process
2. Local development (run the PowerShell script)

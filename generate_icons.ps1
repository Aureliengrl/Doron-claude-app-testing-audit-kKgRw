param (
    [string]$sourcePath = "assets\images\doron_logo.jpg"
)

Add-Type -AssemblyName System.Drawing

function Resize-Image {
    param (
        [string]$src,
        [string]$dest,
        [int]$width,
        [int]$height
    )
    
    try {
        $img = [System.Drawing.Image]::FromFile((Resolve-Path $src).Path)
        $bmp = new-object System.Drawing.Bitmap $width, $height
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        
        # High quality interpolation
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        
        $g.DrawImage($img, 0, 0, $width, $height)
        $bmp.Save((Join-Path (Get-Location) $dest), [System.Drawing.Imaging.ImageFormat]::Png)
        
        $g.Dispose()
        $bmp.Dispose()
        $img.Dispose()
        Write-Host "Resized $dest to ${width}x${height}"
    } catch {
        Write-Host "Error resizing $dest : $_"
    }
}

# ANDROID ICONS
$androidMipmaps = @{
    "mdpi" = 48
    "hdpi" = 72
    "xhdpi" = 96
    "xxhdpi" = 144
    "xxxhdpi" = 192
}

foreach ($density in $androidMipmaps.Keys) {
    $size = $androidMipmaps[$density]
    $iconPath = "android\app\src\main\res\mipmap-$density\ic_launcher.png"
    
    if (Test-Path "android\app\src\main\res\mipmap-$density") {
        Resize-Image -src $sourcePath -dest $iconPath -width $size -height $size
    }
}

# IOS ICONS
$iosDir = "ios\Runner\Assets.xcassets\AppIcon.appiconset"
if (Test-Path $iosDir) {
    $files = Get-ChildItem -Path $iosDir -Filter "*.png"
    foreach ($file in $files) {
        $name = $file.Name
        $width = 0
        $height = 0
        
        if ($name -match "(\d+(?:\.\d+)?)x(\d+(?:\.\d+)?)") {
            $baseWidth = [double]$matches[1]
            $baseHeight = [double]$matches[2]
            
            $multiplier = 1
            if ($name -match "@(\d+)x") {
                $multiplier = [int]$matches[1]
            }
            
            $width = [math]::Round($baseWidth * $multiplier)
            $height = [math]::Round($baseHeight * $multiplier)
        } elseif ($name -match "ItunesArtwork@2x") {
            $width = 1024
            $height = 1024
        }
        
        if ($width -gt 0 -and $height -gt 0) {
            $destPath = Join-Path $iosDir $name
            Resize-Image -src $sourcePath -dest $destPath -width $width -height $height
        }
    }
}

Write-Host "Icons generated successfully!"

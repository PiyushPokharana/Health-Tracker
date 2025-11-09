# PowerShell script to create simple PNG icon files
# This creates basic placeholder icons that can be replaced later

Add-Type -AssemblyName System.Drawing

function Create-Icon {
    param(
        [string]$OutputPath,
        [bool]$WithBackground
    )
    
    $size = 1024
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Draw background if needed
    if ($WithBackground) {
        $orangeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 107, 53))
        $graphics.FillRectangle($orangeBrush, 0, 0, $size, $size)
        $orangeBrush.Dispose()
    }
    
    # Draw dumbbell (white)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $center = $size / 2
    $scale = if ($WithBackground) { 0.45 } else { 0.4 }
    
    # Bar dimensions
    $barWidth = $size * $scale * 0.8
    $barHeight = $size * 0.04
    $plateWidth = $size * 0.035
    $plateHeight = $size * $scale * 0.4
    
    # Draw center bar
    $barRect = New-Object System.Drawing.RectangleF(
        ($center - $barWidth/2),
        ($center - $barHeight/2),
        $barWidth,
        $barHeight
    )
    $graphics.FillRectangle($whiteBrush, $barRect)
    
    # Draw left plates
    $leftX = $center - $barWidth / 2
    
    # Outer left plate
    $plate1 = New-Object System.Drawing.RectangleF(
        ($leftX + $plateWidth * 0.5 - $plateWidth/2),
        ($center - $plateHeight * 1.2/2),
        $plateWidth,
        ($plateHeight * 1.2)
    )
    $graphics.FillRectangle($whiteBrush, $plate1)
    
    # Middle left plate
    $plate2 = New-Object System.Drawing.RectangleF(
        ($leftX + $plateWidth * 2 - $plateWidth/2),
        ($center - $plateHeight/2),
        $plateWidth,
        $plateHeight
    )
    $graphics.FillRectangle($whiteBrush, $plate2)
    
    # Inner left plate
    $plate3 = New-Object System.Drawing.RectangleF(
        ($leftX + $plateWidth * 3.5 - $plateWidth/2),
        ($center - $plateHeight * 0.85/2),
        $plateWidth,
        ($plateHeight * 0.85)
    )
    $graphics.FillRectangle($whiteBrush, $plate3)
    
    # Draw right plates (mirror)
    $rightX = $center + $barWidth / 2
    
    # Outer right plate
    $plate4 = New-Object System.Drawing.RectangleF(
        ($rightX - $plateWidth * 0.5 - $plateWidth/2),
        ($center - $plateHeight * 1.2/2),
        $plateWidth,
        ($plateHeight * 1.2)
    )
    $graphics.FillRectangle($whiteBrush, $plate4)
    
    # Middle right plate
    $plate5 = New-Object System.Drawing.RectangleF(
        ($rightX - $plateWidth * 2 - $plateWidth/2),
        ($center - $plateHeight/2),
        $plateWidth,
        $plateHeight
    )
    $graphics.FillRectangle($whiteBrush, $plate5)
    
    # Inner right plate
    $plate6 = New-Object System.Drawing.RectangleF(
        ($rightX - $plateWidth * 3.5 - $plateWidth/2),
        ($center - $plateHeight * 0.85/2),
        $plateWidth,
        ($plateHeight * 0.85)
    )
    $graphics.FillRectangle($whiteBrush, $plate6)
    
    $whiteBrush.Dispose()
    
    # Save
    $bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
    $graphics.Dispose()
    
    Write-Host "✓ Generated: $OutputPath" -ForegroundColor Green
}

# Create assets directory
New-Item -ItemType Directory -Force -Path "assets" | Out-Null

Write-Host "🎨 Generating app icons..." -ForegroundColor Cyan

# Generate main icon
Create-Icon -OutputPath "assets\icon.png" -WithBackground $true

# Generate foreground icon
Create-Icon -OutputPath "assets\icon_foreground.png" -WithBackground $false

Write-Host ""
Write-Host "✅ Icons generated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Run: flutter pub run flutter_launcher_icons"
Write-Host "   2. Run: flutter run"
Write-Host "   3. Check your app drawer for the new icon!"

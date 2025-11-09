"""
Simple App Icon Generator
Creates placeholder icons for the Daily Success Tracker app.
Requires: pip install pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_icon_with_background(size=1024):
    """Create the main app icon with orange background"""
    # Create image with orange gradient background
    img = Image.new('RGB', (size, size), '#FF6B35')
    draw = ImageDraw.Draw(img)
    
    # Draw simple dumbbell shape
    center = size // 2
    dumbbell_width = int(size * 0.6)
    dumbbell_height = int(size * 0.15)
    weight_radius = int(size * 0.12)
    handle_width = int(dumbbell_width * 0.4)
    
    # Draw handle (center bar)
    handle_rect = [
        center - handle_width // 2,
        center - dumbbell_height // 4,
        center + handle_width // 2,
        center + dumbbell_height // 4
    ]
    draw.rounded_rectangle(handle_rect, radius=int(size * 0.02), fill='white')
    
    # Draw left weight
    left_weight = [
        center - dumbbell_width // 2,
        center - dumbbell_height,
        center - dumbbell_width // 2 + weight_radius * 2,
        center + dumbbell_height
    ]
    draw.rounded_rectangle(left_weight, radius=int(size * 0.03), fill='white')
    
    # Draw right weight
    right_weight = [
        center + dumbbell_width // 2 - weight_radius * 2,
        center - dumbbell_height,
        center + dumbbell_width // 2,
        center + dumbbell_height
    ]
    draw.rounded_rectangle(right_weight, radius=int(size * 0.03), fill='white')
    
    # Draw checkmark accent (green)
    check_size = int(size * 0.12)
    check_x = center + dumbbell_width // 4
    check_y = center - int(dumbbell_height * 2)
    check_thickness = int(size * 0.025)
    
    # Draw checkmark using lines
    draw.line(
        [(check_x - check_size // 2, check_y),
         (check_x - check_size // 4, check_y + check_size // 2)],
        fill='#4CAF50', width=check_thickness
    )
    draw.line(
        [(check_x - check_size // 4, check_y + check_size // 2),
         (check_x + check_size // 2, check_y - check_size // 3)],
        fill='#4CAF50', width=check_thickness
    )
    
    return img

def create_icon_foreground(size=1024):
    """Create the foreground icon (transparent background) for adaptive icons"""
    # Create transparent image
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw dumbbell (same as above but white on transparent)
    center = size // 2
    dumbbell_width = int(size * 0.5)  # Slightly smaller for adaptive icon
    dumbbell_height = int(size * 0.12)
    weight_radius = int(size * 0.10)
    handle_width = int(dumbbell_width * 0.4)
    
    # Draw handle
    handle_rect = [
        center - handle_width // 2,
        center - dumbbell_height // 4,
        center + handle_width // 2,
        center + dumbbell_height // 4
    ]
    draw.rounded_rectangle(handle_rect, radius=int(size * 0.02), fill='white')
    
    # Draw left weight
    left_weight = [
        center - dumbbell_width // 2,
        center - dumbbell_height,
        center - dumbbell_width // 2 + weight_radius * 2,
        center + dumbbell_height
    ]
    draw.rounded_rectangle(left_weight, radius=int(size * 0.03), fill='white')
    
    # Draw right weight
    right_weight = [
        center + dumbbell_width // 2 - weight_radius * 2,
        center - dumbbell_height,
        center + dumbbell_width // 2,
        center + dumbbell_height
    ]
    draw.rounded_rectangle(right_weight, radius=int(size * 0.03), fill='white')
    
    # Draw checkmark
    check_size = int(size * 0.10)
    check_x = center + dumbbell_width // 4
    check_y = center - int(dumbbell_height * 2)
    check_thickness = int(size * 0.02)
    
    draw.line(
        [(check_x - check_size // 2, check_y),
         (check_x - check_size // 4, check_y + check_size // 2)],
        fill='#4CAF50', width=check_thickness
    )
    draw.line(
        [(check_x - check_size // 4, check_y + check_size // 2),
         (check_x + check_size // 2, check_y - check_size // 3)],
        fill='#4CAF50', width=check_thickness
    )
    
    return img

def main():
    print("🎨 Generating app icons...")
    
    # Create assets directory if it doesn't exist
    os.makedirs('assets', exist_ok=True)
    
    # Generate main icon
    icon = create_icon_with_background(1024)
    icon.save('assets/icon.png', 'PNG')
    print("✓ Generated: assets/icon.png")
    
    # Generate foreground icon
    icon_fg = create_icon_foreground(1024)
    icon_fg.save('assets/icon_foreground.png', 'PNG')
    print("✓ Generated: assets/icon_foreground.png")
    
    print("\n✅ Icons generated successfully!")
    print("\n🚀 Next steps:")
    print("   1. Run: flutter pub run flutter_launcher_icons")
    print("   2. Run: flutter run")
    print("   3. Check your app drawer for the new icon!")

if __name__ == '__main__':
    main()

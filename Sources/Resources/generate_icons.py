#!/usr/bin/env python3

import os
import subprocess
from pathlib import Path

# Icon sizes required for macOS
sizes = [
    (16, 1),   # 16pt
    (16, 2),   # 16pt@2x
    (32, 1),   # 32pt
    (32, 2),   # 32pt@2x
    (128, 1),  # 128pt
    (128, 2),  # 128pt@2x
    (256, 1),  # 256pt
    (256, 2),  # 256pt@2x
    (512, 1),  # 512pt
    (512, 2),  # 512pt@2x
]

script_dir = Path(__file__).parent
svg_file = script_dir / "icon.svg"
iconset_dir = script_dir / "Assets.xcassets" / "AppIcon.appiconset"

# Create iconset directory if it doesn't exist
iconset_dir.mkdir(parents=True, exist_ok=True)

# Generate PNG files using sips (macOS built-in tool)
for base_size, scale in sizes:
    pixel_size = base_size * scale
    if scale == 1:
        filename = f"icon_{base_size}x{base_size}.png"
    else:
        filename = f"icon_{base_size}x{base_size}@{scale}x.png"
    
    output_path = iconset_dir / filename
    
    # Generate PNG files using PIL
    try:
        from PIL import Image, ImageDraw
        
        # Create a gradient background
        img = Image.new('RGBA', (pixel_size, pixel_size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Draw gradient background (simplified)
        for i in range(pixel_size):
            color_b = int(0 + (86 - 0) * (i / pixel_size))
            color_r = int(122 - (122 - 86) * (i / pixel_size))
            draw.rectangle([0, i, pixel_size, i+1], fill=(color_r, color_b, 255, 255))
        
        # Draw rounded corners
        corner_radius = pixel_size // 5
        draw.pieslice([0, 0, corner_radius*2, corner_radius*2], 180, 270, fill=(0, 0, 0, 0))
        draw.pieslice([pixel_size-corner_radius*2, 0, pixel_size, corner_radius*2], 270, 360, fill=(0, 0, 0, 0))
        draw.pieslice([0, pixel_size-corner_radius*2, corner_radius*2, pixel_size], 90, 180, fill=(0, 0, 0, 0))
        draw.pieslice([pixel_size-corner_radius*2, pixel_size-corner_radius*2, pixel_size, pixel_size], 0, 90, fill=(0, 0, 0, 0))
        
        # Calculate module size for QR code pattern
        module_size = max(1, pixel_size // 16)
        
        # Draw finder patterns
        def draw_finder(x_pos, y_pos):
            # Outer white square
            draw.rectangle([x_pos, y_pos, x_pos + 7*module_size, y_pos + 7*module_size], fill='white')
            # Middle black square
            draw.rectangle([x_pos + module_size, y_pos + module_size, 
                          x_pos + 6*module_size, y_pos + 6*module_size], fill='black')
            # Inner white square
            draw.rectangle([x_pos + 2*module_size, y_pos + 2*module_size, 
                          x_pos + 5*module_size, y_pos + 5*module_size], fill='white')
            # Center black square
            draw.rectangle([x_pos + 3*module_size, y_pos + 3*module_size, 
                          x_pos + 4*module_size, y_pos + 4*module_size], fill='black')
        
        # Position finder patterns
        margin = pixel_size // 8
        draw_finder(margin, margin)  # Top-left
        draw_finder(pixel_size - margin - 7*module_size, margin)  # Top-right
        draw_finder(margin, pixel_size - margin - 7*module_size)  # Bottom-left
        
        # Draw some data modules for visual effect
        if pixel_size >= 32:
            center_x = pixel_size // 2
            center_y = pixel_size // 2
            for offset in [(-2, -2), (0, -2), (2, -2), (-2, 0), (2, 0), (-2, 2), (0, 2), (2, 2)]:
                x = center_x + offset[0] * module_size
                y = center_y + offset[1] * module_size
                if x > margin + 7*module_size and y > margin + 7*module_size:
                    draw.rectangle([x, y, x + module_size, y + module_size], fill='white')
        
        img.save(str(output_path))
        print(f"Generated {filename} ({pixel_size}x{pixel_size})")
    except ImportError:
        print(f"Warning: Could not generate {filename} - install Pillow")

print("\nIcon generation complete!")
print(f"Icons saved to: {iconset_dir}")
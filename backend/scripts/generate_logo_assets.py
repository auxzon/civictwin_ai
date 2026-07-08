import os
from PIL import Image, ImageDraw

def draw_monogram(size, transparent=False):
    # Background color: transparent or dark obsidian #070809
    bg = (0, 0, 0, 0) if transparent else (7, 8, 9, 255)
    image = Image.new("RGBA", (size, size), bg)
    draw = ImageDraw.Draw(image)
    
    # Center and scaling coordinates
    center = size / 2.0
    radius = size * 0.33
    stroke_width = max(2, int(size * 0.04))
    
    # Outer "C" arc (bounding box)
    bbox = [center - radius, center - radius, center + radius, center + radius]
    
    # Draw arc in light white/gray (similar to textPrimary)
    # Start: 144 degrees, End: 396 degrees in PIL coordinates
    # PIL arc draws counter-clockwise or clockwise depending on angle conventions.
    # To get a clean left-facing C, start at 144 and end at 396 degrees.
    draw.arc(bbox, start=135, end=405, fill=(241, 243, 245, 24), width=stroke_width + 4) # Subtle shadow glow
    draw.arc(bbox, start=135, end=405, fill=(241, 243, 245, 255), width=stroke_width)
    
    # Inner "T" shape: vertical and horizontal lines in neon cyan (0, 229, 255)
    t_width = radius * 0.5
    t_height = radius * 0.6
    y_top = center - t_width * 0.6
    
    # Glowing backdrop for T
    draw.line(
        [center - t_width, y_top, center + t_width, y_top],
        fill=(0, 229, 255, 32),
        width=stroke_width + 4
    )
    draw.line(
        [center, y_top, center, center + t_height],
        fill=(0, 229, 255, 32),
        width=stroke_width + 4
    )

    # Core T lines
    draw.line(
        [center - t_width, y_top, center + t_width, y_top],
        fill=(0, 229, 255, 255),
        width=stroke_width
    )
    draw.line(
        [center, y_top, center, center + t_height],
        fill=(0, 229, 255, 255),
        width=stroke_width
    )
    
    return image

def main():
    web_dir = r"E:\Auxzon Programming\civictwin_ai\frontend\web"
    icons_dir = os.path.join(web_dir, "icons")
    
    os.makedirs(icons_dir, exist_ok=True)
    
    # Generate favicon (32x32)
    fav = draw_monogram(32, transparent=True)
    fav.save(os.path.join(web_dir, "favicon.png"), "PNG")
    print("Generated favicon.png")
    
    # Generate standard PWA icons
    draw_monogram(192).save(os.path.join(icons_dir, "Icon-192.png"), "PNG")
    draw_monogram(512).save(os.path.join(icons_dir, "Icon-512.png"), "PNG")
    print("Generated Icon-192.png and Icon-512.png")
    
    # Generate maskable icons (with a solid background)
    draw_monogram(192, transparent=False).save(os.path.join(icons_dir, "Icon-maskable-192.png"), "PNG")
    draw_monogram(512, transparent=False).save(os.path.join(icons_dir, "Icon-maskable-512.png"), "PNG")
    print("Generated Icon-maskable-192.png and Icon-maskable-512.png")

if __name__ == "__main__":
    main()

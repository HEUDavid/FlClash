#!/usr/bin/env python3
import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw

def create_circular_icon(image: Image.Image) -> Image.Image:
    # 4x supersampled anti-aliased circular mask
    scale = 4
    mask_size = (image.size[0] * scale, image.size[1] * scale)
    mask = Image.new('L', mask_size, 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, mask_size[0], mask_size[1]), fill=255)
    mask = mask.resize(image.size, Image.Resampling.LANCZOS)
    
    result = Image.new('RGBA', image.size, (255, 255, 255, 0))
    result.paste(image, (0, 0), mask=mask)
    return result

def create_tv_banner(image: Image.Image) -> Image.Image:
    banner = Image.new('RGBA', (320, 180), (255, 255, 255, 255))
    icon_h = 140
    icon_w = int(image.size[0] * (icon_h / image.size[1]))
    resized_icon = image.resize((icon_w, icon_h), Image.Resampling.LANCZOS)
    x = (320 - icon_w) // 2
    y = (180 - icon_h) // 2
    banner.paste(resized_icon, (x, y), mask=resized_icon if resized_icon.mode == 'RGBA' else None)
    return banner

def main():
    script_dir = Path(__file__).resolve().parent
    source_path = script_dir / 'AppIcon_Flat.png'
    if not source_path.exists():
        source_path = Path('AppIcon_Flat.png')
    if not source_path.exists():
        print(f"Error: Source image not found at {source_path}")
        sys.exit(1)

    print(f"Loading master icon: {source_path}")
    master = Image.open(source_path).convert('RGBA')

    res_dir = script_dir / 'res'
    res_dir.mkdir(parents=True, exist_ok=True)

    # Standard densities for Android mipmaps
    densities = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
        'mipmap-television-mdpi': 48,
        'mipmap-television-hdpi': 72,
        'mipmap-television-xhdpi': 96,
        'mipmap-television-xxhdpi': 144,
        'mipmap-television-xxxhdpi': 192,
    }

    for folder_name, size in densities.items():
        target_folder = res_dir / folder_name
        target_folder.mkdir(parents=True, exist_ok=True)

        # Standard icon
        icon_img = master.resize((size, size), Image.Resampling.LANCZOS)
        icon_img.save(target_folder / 'ic_launcher.webp', 'WEBP', quality=95, method=6)

        # Round icon (only for standard mipmaps)
        if not folder_name.startswith('mipmap-television'):
            round_img = create_circular_icon(icon_img)
            round_img.save(target_folder / 'ic_launcher_round.webp', 'WEBP', quality=95, method=6)

        print(f"Generated {folder_name} (size: {size}x{size})")

    # Android TV Banner
    xhdpi_dir = res_dir / 'mipmap-xhdpi'
    banner = create_tv_banner(master)
    banner.save(xhdpi_dir / 'ic_banner.png', 'PNG')
    print("Generated mipmap-xhdpi/ic_banner.png (320x180)")

    # Play Store and Flutter icon assets
    master_512 = master.resize((512, 512), Image.Resampling.LANCZOS)
    master_512.save(script_dir / 'ic_launcher-playstore.png', 'PNG')
    master.save(script_dir / 'icon.png', 'PNG')
    print("Generated Play Store (512x512) and App Icon (1024x1024)")

    # XML resources
    values_dir = res_dir / 'values'
    values_dir.mkdir(parents=True, exist_ok=True)
    (values_dir / 'ic_launcher_background.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#FFFFFF</color>\n'
        '</resources>\n',
        encoding='utf-8',
    )

    drawable_dir = res_dir / 'drawable'
    drawable_dir.mkdir(parents=True, exist_ok=True)
    
    foreground_xml = (
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    xmlns:aapt="http://schemas.android.com/aapt"\n'
        '    android:width="108dp"\n'
        '    android:height="108dp"\n'
        '    android:viewportWidth="1024"\n'
        '    android:viewportHeight="1024">\n'
        '    <group\n'
        '        android:translateX="96"\n'
        '        android:translateY="127"\n'
        '        android:scaleX="26"\n'
        '        android:scaleY="26">\n'
        '        <path\n'
        '            android:pathData="M16.0001,1.14819 C10.5835,1.14819 5.55144,2.74857 1.37676,5.48949 C1.09039,10.4753 2.22047,15.6334 4.92875,20.3243 C7.63144,25.0055 11.5229,28.5582 15.9725,30.8039 L16.0001,30.8518 L16.0277,30.8039 C20.4772,28.5582 24.3687,25.0055 27.0714,20.3243 C29.7797,15.6335 30.9098,10.4754 30.6234,5.48949 C26.4487,2.74857 21.4166,1.14819 16.0001,1.14819 Z">\n'
        '            <aapt:attr name="android:fillColor">\n'
        '                <gradient\n'
        '                    android:startX="16"\n'
        '                    android:startY="1.14"\n'
        '                    android:endX="16"\n'
        '                    android:endY="30.85"\n'
        '                    android:type="linear">\n'
        '                    <item android:offset="0" android:color="#10B981" />\n'
        '                    <item android:offset="1" android:color="#059669" />\n'
        '                </gradient>\n'
        '            </aapt:attr>\n'
        '        </path>\n'
        '        <path\n'
        '            android:fillColor="#FFFFFF"\n'
        '            android:pathData="M20.6147,11.921 C21.0632,12.4218 21.062,13.2323 20.6119,13.7314 L17.1768,17.5409 C16,18.9704 15.2574,18.9704 14.0336,17.5409 L11.8825,15.1554 C11.4324,14.6563 11.4312,13.8457 11.8797,13.345 C12.3283,12.8442 13.0567,12.8428 13.5068,13.3419 L15.6052,15.669 L18.9876,11.9179 C19.4377,11.4188 20.1661,11.4202 20.6147,11.921 Z" />\n'
        '    </group>\n'
        '</vector>\n'
    )
    (drawable_dir / 'ic_launcher_foreground.xml').write_text(foreground_xml, encoding='utf-8')
    (drawable_dir / 'ic_launcher_foreground_tv.xml').write_text(foreground_xml, encoding='utf-8')
    print("Generated values and drawable XML resources")
    print("All icon assets generated successfully in lib/custom/branding!")

if __name__ == '__main__':
    main()

import skia

def create_shield_path():
    p = skia.Path()
    # M16.0001 1.14819
    p.moveTo(16.0001, 1.14819)
    # C10.5835 1.14819 5.55144 2.74857 1.37676 5.48949
    p.cubicTo(10.5835, 1.14819, 5.55144, 2.74857, 1.37676, 5.48949)
    # C1.09039 10.4753 2.22047 15.6334 4.92875 20.3243
    p.cubicTo(1.09039, 10.4753, 2.22047, 15.6334, 4.92875, 20.3243)
    # C7.63144 25.0055 11.5229 28.5582 15.9725 30.8039
    p.cubicTo(7.63144, 25.0055, 11.5229, 28.5582, 15.9725, 30.8039)
    # L16.0001 30.8518
    p.lineTo(16.0001, 30.8518)
    # L16.0277 30.8039
    p.lineTo(16.0277, 30.8039)
    # C20.4772 28.5582 24.3687 25.0055 27.0714 20.3243
    p.cubicTo(20.4772, 28.5582, 24.3687, 25.0055, 27.0714, 20.3243)
    # C29.7797 15.6335 30.9098 10.4754 30.6234 5.48949
    p.cubicTo(29.7797, 15.6335, 30.9098, 10.4754, 30.6234, 5.48949)
    # C26.4487 2.74857 21.4166 1.14819 16.0001 1.14819
    p.cubicTo(26.4487, 2.74857, 21.4166, 1.14819, 16.0001, 1.14819)
    # Z
    p.close()
    return p

def create_check_path():
    p = skia.Path()
    # M20.6147 11.921
    p.moveTo(20.6147, 11.921)
    # C21.0632 12.4218 21.062 13.2323 20.6119 13.7314
    p.cubicTo(21.0632, 12.4218, 21.062, 13.2323, 20.6119, 13.7314)
    # L17.1768 17.5409
    p.lineTo(17.1768, 17.5409)
    # C16 18.9704 15.2574 18.9704 14.0336 17.5409
    p.cubicTo(16, 18.9704, 15.2574, 18.9704, 14.0336, 17.5409)
    # L11.8825 15.1554
    p.lineTo(11.8825, 15.1554)
    # C11.4324 14.6563 11.4312 13.8457 11.8797 13.345
    p.cubicTo(11.4324, 14.6563, 11.4312, 13.8457, 11.8797, 13.345)
    # C12.3283 12.8442 13.0567 12.8428 13.5068 13.3419
    p.cubicTo(12.3283, 12.8442, 13.0567, 12.8428, 13.5068, 13.3419)
    # L15.6052 15.669
    p.lineTo(15.6052, 15.669)
    # L18.9876 11.9179
    p.lineTo(18.9876, 11.9179)
    # C19.4377 11.4188 20.1661 11.4202 20.6147 11.921
    p.cubicTo(19.4377, 11.4188, 20.1661, 11.4202, 20.6147, 11.921)
    # Z
    p.close()
    return p

# Canvas dimensions
SIZE = 1024
surface = skia.Surface(SIZE, SIZE)
with surface as canvas:
    # 1. Fill opaque white background
    canvas.drawColor(skia.ColorWHITE)
    
    # 2. Translate and scale
    canvas.save()
    # Increase scale to 26 and shift down slightly for visual centering (X: 96, Y: 127)
    canvas.translate(96, 127)
    canvas.scale(26, 26)
    
    # 3. Draw Shield
    shield_path = create_shield_path()
    shield_paint = skia.Paint(
        Shader=skia.GradientShader.MakeLinear(
            points=[skia.Point(16, 1.14), skia.Point(16, 30.85)],
            colors=[skia.ColorSetARGB(255, 0x10, 0xB9, 0x81), skia.ColorSetARGB(255, 0x05, 0x96, 0x69)]
        ),
        Style=skia.Paint.kFill_Style,
        AntiAlias=True
    )
    canvas.drawPath(shield_path, shield_paint)
    
    # 4. Draw Checkmark
    check_path = create_check_path()
    check_paint = skia.Paint(
        Color=skia.ColorWHITE,
        Style=skia.Paint.kFill_Style,
        AntiAlias=True
    )
    canvas.drawPath(check_path, check_paint)
    
    canvas.restore()

# Export to PNG
image = surface.makeImageSnapshot()
image.save("AppIcon_Flat.png", skia.kPNG)
print("Saved AppIcon_Flat.png")

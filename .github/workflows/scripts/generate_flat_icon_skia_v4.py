#!/usr/bin/env python3
"""
generate_flat_icon_skia_v4.py
纯净高锐矢量版应用图标生成器：
- 饱满比例 (SCALE=26.0) 与斐波那契黄金分割下移校准 (TRANS_Y=126.0)
- 高对比白底与高饱和翡翠通透三段渐变 (#18D293 -> #10B981 -> #059669)
- 刀锋般锐利的矢量边缘，无多余模糊阴影
"""

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

def render_icon(output_path="AppIcon_Flat_v4.png"):
    SIZE = 1024
    surface = skia.Surface(SIZE, SIZE)

    with surface as canvas:
        canvas.drawColor(skia.ColorWHITE)

        SCALE = 26.0
        TRANS_X = 96.0
        TRANS_Y = 126.0

        canvas.save()
        canvas.translate(TRANS_X, TRANS_Y)
        canvas.scale(SCALE, SCALE)

        shield_path = create_shield_path()
        check_path = create_check_path()

        shield_paint = skia.Paint(
            Shader=skia.GradientShader.MakeLinear(
                points=[skia.Point(16, 1.14), skia.Point(16, 30.85)],
                colors=[
                    skia.ColorSetRGB(0x18, 0xD2, 0x93),
                    skia.ColorSetRGB(0x10, 0xB9, 0x81),
                    skia.ColorSetRGB(0x05, 0x96, 0x69),
                ],
                positions=[0.0, 0.45, 1.0]
            ),
            Style=skia.Paint.kFill_Style,
            AntiAlias=True
        )
        canvas.drawPath(shield_path, shield_paint)

        check_paint = skia.Paint(
            Color=skia.ColorWHITE,
            Style=skia.Paint.kFill_Style,
            AntiAlias=True
        )
        canvas.drawPath(check_path, check_paint)

        canvas.restore()

    image = surface.makeImageSnapshot()
    image.save(output_path, skia.kPNG)
    print(f"Saved: {output_path}")

def main():
    render_icon(output_path="AppIcon_Flat_v4.png")

if __name__ == '__main__':
    main()

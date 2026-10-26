"""
Rage Tap Store Assets and Launcher Icon Generator
Generates:
1. store_assets/icon_512.png (512x512 Play Store icon)
2. store_assets/feature_graphic_1024x500.png (1024x500 Play Store feature banner)
3. android/app/src/main/res/mipmap-*/ic_launcher.png (Android launcher icons)

Uses clean geometric vector rendering via Pillow with supersampling.
"""

import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

# ---- Palette Colors ----
BG_DEEP = (11, 16, 38)          # #0B1026
BG_PURPLE = (26, 17, 64)        # #1A1140
BG_DARK = (7, 10, 24)           # #070A18
CYAN = (34, 227, 255)           # #22E3FF
CYAN_DARK = (15, 163, 184)      # #0FA3B8
MAGENTA = (255, 46, 147)        # #FF2E93
MAGENTA_DARK = (158, 26, 99)    # #9E1A63
ORANGE = (255, 138, 31)         # #FF8A1F
YELLOW = (255, 210, 63)         # #FFD23F
WHITE = (244, 247, 255)         # #F4F7FF
MUTED = (138, 147, 184)         # #8A93B8


def get_font(size: int, bold: bool = True):
    font_paths = [
        "C:\\Windows\\Fonts\\arialbd.ttf" if bold else "C:\\Windows\\Fonts\\arial.ttf",
        "C:\\Windows\\Fonts\\seguiui.ttf",
        "C:\\Windows\\Fonts\\trebucbd.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                pass
    return ImageFont.load_default()


def create_radial_gradient(width: int, height: int, c_center, c_outer, cx_ratio=0.5, cy_ratio=0.5):
    img = Image.new("RGBA", (width, height), (c_outer[0], c_outer[1], c_outer[2], 255))
    draw = ImageDraw.Draw(img)
    cx = width * cx_ratio
    cy = height * cy_ratio
    max_radius = math.hypot(max(cx, width - cx), max(cy, height - cy))

    steps = 120
    for i in range(steps, -1, -1):
        ratio = i / steps
        r = int(c_center[0] * (1 - ratio) + c_outer[0] * ratio)
        g = int(c_center[1] * (1 - ratio) + c_outer[1] * ratio)
        b = int(c_center[2] * (1 - ratio) + c_outer[2] * ratio)
        rad = max_radius * ratio
        draw.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(r, g, b, 255))
    return img


def render_zap_sprite(size: int, with_feet: bool = False, in_air: bool = False) -> Image.Image:
    """
    Renders Zap as a standalone transparent RGBA sprite of size x size
    with 100% accurate rounded corner geometry.
    """
    s = size / 40.0
    corner_radius = int(10.0 * s)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Optional running feet (behind body)
    if with_feet and not in_air:
        f_draw = ImageDraw.Draw(canvas)
        foot_w = int(10.0 * s)
        foot_h = int(5.0 * s)
        foot_r = int(2.5 * s)
        # Left and right feet
        f_draw.rounded_rectangle(
            [int(9.0 * s), int(36.0 * s), int(9.0 * s) + foot_w, int(36.0 * s) + foot_h],
            radius=foot_r, fill=CYAN_DARK
        )
        f_draw.rounded_rectangle(
            [int(21.0 * s), int(36.0 * s), int(21.0 * s) + foot_w, int(36.0 * s) + foot_h],
            radius=foot_r, fill=CYAN_DARK
        )

    # Base body rounded rectangle
    body = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(body)
    b_draw.rounded_rectangle([0, 0, size, size], radius=corner_radius, fill=CYAN)

    # Dark bottom strip clipped to the exact rounded corners
    body_mask = Image.new("L", (size, size), 0)
    m_draw = ImageDraw.Draw(body_mask)
    m_draw.rounded_rectangle([0, 0, size, size], radius=corner_radius, fill=255)
    # Clear the upper portion so only bottom 4 units remain masked
    m_draw.rectangle([0, 0, size, int(36.0 * s)], fill=0)

    dark_layer = Image.new("RGBA", (size, size), CYAN_DARK)
    body.paste(dark_layer, (0, 0), body_mask)

    # Highlight gloss on top left (6, 5, 10, 4)
    hl_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hl_draw = ImageDraw.Draw(hl_layer)
    hl_draw.rounded_rectangle(
        [int(6.0 * s), int(5.0 * s), int(16.0 * s), int(9.0 * s)],
        radius=int(2.0 * s),
        fill=(255, 255, 255, 120)
    )
    body.alpha_composite(hl_layer)

    # Face details (eyes, pupils, brows, mouth)
    f_draw = ImageDraw.Draw(body)

    eye_w = 10.0 * s if in_air else 9.0 * s
    eye_h = 12.0 * s if in_air else 11.0 * s
    pupil_w = 4.5 * s if in_air else 4.0 * s
    pupil_h = 6.5 * s if in_air else 6.0 * s
    pupil_shift = 2.5 * s

    left_center = (13.5 * s, 18.5 * s)
    right_center = (26.5 * s, 18.5 * s)

    # Eyes (white ovals)
    f_draw.ellipse([
        left_center[0] - eye_w / 2, left_center[1] - eye_h / 2,
        left_center[0] + eye_w / 2, left_center[1] + eye_h / 2
    ], fill=WHITE)
    f_draw.ellipse([
        right_center[0] - eye_w / 2, right_center[1] - eye_h / 2,
        right_center[0] + eye_w / 2, right_center[1] + eye_h / 2
    ], fill=WHITE)

    # Pupils (dark navy)
    f_draw.ellipse([
        left_center[0] + pupil_shift - pupil_w / 2, left_center[1] - pupil_h / 2,
        left_center[0] + pupil_shift + pupil_w / 2, left_center[1] + pupil_h / 2
    ], fill=BG_DEEP)
    f_draw.ellipse([
        right_center[0] + pupil_shift - pupil_w / 2, right_center[1] - pupil_h / 2,
        right_center[0] + pupil_shift + pupil_w / 2, right_center[1] + pupil_h / 2
    ], fill=BG_DEEP)

    # Tiny catchlight in pupils
    cl_w = max(1, int(1.2 * s))
    f_draw.ellipse([
        left_center[0] + pupil_shift - cl_w, left_center[1] - cl_w * 2,
        left_center[0] + pupil_shift + cl_w, left_center[1]
    ], fill=(255, 255, 255, 220))
    f_draw.ellipse([
        right_center[0] + pupil_shift - cl_w, right_center[1] - cl_w * 2,
        right_center[0] + pupil_shift + cl_w, right_center[1]
    ], fill=(255, 255, 255, 220))

    # Brows: determined angled lines
    brow_w = max(2, int(3.2 * s))
    f_draw.line([
        (7.0 * s, 11.0 * s),
        (17.0 * s, 14.5 * s)
    ], fill=BG_DEEP, width=brow_w)
    f_draw.line([
        (23.0 * s, 14.5 * s),
        (33.0 * s, 11.0 * s)
    ], fill=BG_DEEP, width=brow_w)

    # Mouth: flat determined line
    f_draw.line([
        (15.0 * s, 29.0 * s),
        (25.0 * s, 29.0 * s)
    ], fill=BG_DEEP, width=brow_w)

    canvas.alpha_composite(body)
    return canvas


def render_icon_512() -> Image.Image:
    """Renders 512x512 Play Store app icon using 4x supersampling (2048x2048)."""
    scale = 4
    dim = 512 * scale
    canvas = Image.new("RGBA", (dim, dim), (BG_DARK[0], BG_DARK[1], BG_DARK[2], 255))

    # 1. Background gradient: Deep space purple to dark navy, full bleed
    bg = create_radial_gradient(dim, dim, (32, 22, 78), BG_DARK, cx_ratio=0.5, cy_ratio=0.45)
    canvas.paste(bg, (0, 0))

    # 2. Large soft ambient cyan glow behind Zap
    ambient_glow = Image.new("RGBA", (dim, dim), (0, 0, 0, 0))
    ag_draw = ImageDraw.Draw(ambient_glow)
    center = (dim // 2, int(dim * 0.52))
    ag_rad = int(dim * 0.36)
    ag_draw.ellipse([
        center[0] - ag_rad, center[1] - ag_rad,
        center[0] + ag_rad, center[1] + ag_rad
    ], fill=(34, 227, 255, 80))
    ambient_glow = ambient_glow.filter(ImageFilter.GaussianBlur(radius=40 * scale))
    canvas.alpha_composite(ambient_glow)

    # 3. Zap character
    zap_size = int(dim * 0.60)
    zap_x = (dim - zap_size) // 2
    zap_y = (dim - zap_size) // 2 + int(6 * scale)

    # Outer Zap bloom
    bloom = Image.new("RGBA", (dim, dim), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(bloom)
    b_radius = int(zap_size * 0.25)
    b_draw.rounded_rectangle([
        zap_x - 12 * scale, zap_y - 12 * scale,
        zap_x + zap_size + 12 * scale, zap_y + zap_size + 12 * scale
    ], radius=b_radius, fill=(34, 227, 255, 160))
    bloom = bloom.filter(ImageFilter.GaussianBlur(radius=16 * scale))
    canvas.alpha_composite(bloom)

    # Paste Zap sprite
    zap_sprite = render_zap_sprite(zap_size)
    canvas.alpha_composite(zap_sprite, (zap_x, zap_y))

    # Downsample cleanly with Lanczos to 512x512
    return canvas.resize((512, 512), Image.Resampling.LANCZOS)


def render_feature_graphic_1024x500() -> Image.Image:
    """Renders 1024x500 Google Play Feature Graphic using 2x supersampling (2048x1000)."""
    scale = 2
    w = 1024 * scale
    h = 500 * scale

    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    # 1. Dark atmospheric backdrop
    bg = create_radial_gradient(w, h, (36, 24, 85), BG_DARK, cx_ratio=0.68, cy_ratio=0.45)
    canvas.paste(bg, (0, 0))

    draw = ImageDraw.Draw(canvas)

    # 2. Ground and horizon
    ground_y = int(h * 0.78)

    # Ambient ground glow
    ground_glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gg_draw = ImageDraw.Draw(ground_glow)
    gg_draw.rectangle([0, ground_y - 10 * scale, w, ground_y + 10 * scale], fill=(34, 227, 255, 100))
    ground_glow = ground_glow.filter(ImageFilter.GaussianBlur(radius=12 * scale))
    canvas.alpha_composite(ground_glow)

    # Solid ground
    draw.rectangle([0, ground_y, w, h], fill=(12, 17, 42))
    draw.line([(0, ground_y), (w, ground_y)], fill=CYAN, width=int(3.5 * scale))

    # 3. Orange Danger Spikes
    def draw_spike(sx, sw, sh):
        pts = [(sx, ground_y), (sx + sw / 2, ground_y - sh), (sx + sw, ground_y)]
        draw.polygon(pts, fill=ORANGE)
        draw.line([pts[0], pts[1], pts[2]], fill=(255, 220, 100), width=int(2 * scale))

    spike_x = int(w * 0.75)
    draw_spike(spike_x, int(42 * scale), int(54 * scale))
    draw_spike(spike_x + int(46 * scale), int(42 * scale), int(54 * scale))
    draw_spike(spike_x + int(120 * scale), int(48 * scale), int(64 * scale))

    # 4. Zap leaping in mid-air
    zap_w = int(125 * scale)
    zap_x = int(w * 0.53)
    zap_y = ground_y - zap_w - int(45 * scale)

    # Soft Zap jump bloom
    zg_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    zg_draw = ImageDraw.Draw(zg_layer)
    zg_draw.ellipse([
        zap_x - 18 * scale, zap_y - 18 * scale,
        zap_x + zap_w + 18 * scale, zap_y + zap_w + 18 * scale
    ], fill=(34, 227, 255, 130))
    zg_layer = zg_layer.filter(ImageFilter.GaussianBlur(radius=20 * scale))
    canvas.alpha_composite(zg_layer)

    zap_sprite = render_zap_sprite(zap_w, in_air=True)
    canvas.alpha_composite(zap_sprite, (zap_x, zap_y))

    # Motion streaks behind Zap
    for i in range(1, 4):
        alpha = int(90 / i)
        y_pos = zap_y + int(zap_w * (0.35 + i * 0.18))
        draw.line([
            (zap_x - int(25 * scale * i), y_pos),
            (zap_x - int(8 * scale), y_pos)
        ], fill=(34, 227, 255, alpha), width=int(3 * scale))

    # 5. Bold Typography: "RAGE TAP"
    font_logo = get_font(int(84 * scale), bold=True)
    font_sub = get_font(int(22 * scale), bold=True)
    font_pills = get_font(int(15 * scale), bold=True)

    text_x = int(w * 0.08)
    text_y_rage = int(h * 0.18)
    text_y_tap = text_y_rage + int(76 * scale)

    # Text glow
    text_glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    tg_draw = ImageDraw.Draw(text_glow)
    tg_draw.text((text_x, text_y_rage), "RAGE", font=font_logo, fill=(34, 227, 255, 170))
    tg_draw.text((text_x, text_y_tap), "TAP", font=font_logo, fill=(255, 46, 147, 170))
    text_glow = text_glow.filter(ImageFilter.GaussianBlur(radius=16 * scale))
    canvas.alpha_composite(text_glow)

    # Solid crisp letters
    draw.text((text_x, text_y_rage), "RAGE", font=font_logo, fill=CYAN)
    draw.text((text_x, text_y_tap), "TAP", font=font_logo, fill=MAGENTA)

    # Subtitle Badge
    badge_x = text_x
    badge_y = text_y_tap + int(100 * scale)
    badge_w = int(340 * scale)
    badge_h = int(36 * scale)
    draw.rounded_rectangle(
        [badge_x, badge_y, badge_x + badge_w, badge_y + badge_h],
        radius=int(18 * scale),
        fill=(26, 17, 64, 220),
        outline=(255, 46, 147, 180),
        width=int(1.5 * scale)
    )
    draw.text(
        (badge_x + int(22 * scale), badge_y + int(6 * scale)),
        "ONE TAP. ZERO EXCUSES.",
        font=font_sub,
        fill=WHITE
    )

    # Feature tags below
    tags_y = badge_y + int(50 * scale)
    draw.text((text_x, tags_y), "OFFLINE ARCADE  •  60 FPS  •  PURE SKILL", font=font_pills, fill=MUTED)

    # Downsample to 1024x500
    return canvas.resize((1024, 500), Image.Resampling.LANCZOS)


def main():
    os.makedirs("store_assets", exist_ok=True)

    print("Generating 512x512 Store Icon...")
    icon_512 = render_icon_512()
    icon_512.save("store_assets/icon_512.png", "PNG")
    print("Saved store_assets/icon_512.png")

    print("Generating 1024x500 Feature Graphic...")
    feature_graphic = render_feature_graphic_1024x500()
    feature_graphic.save("store_assets/feature_graphic_1024x500.png", "PNG")
    print("Saved store_assets/feature_graphic_1024x500.png")

    # Mipmap launcher icons
    mipmaps = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }

    res_dir = os.path.join("android", "app", "src", "main", "res")
    for folder, target_dim in mipmaps.items():
        folder_path = os.path.join(res_dir, folder)
        os.makedirs(folder_path, exist_ok=True)
        out_file = os.path.join(folder_path, "ic_launcher.png")
        resized_icon = icon_512.resize((target_dim, target_dim), Image.Resampling.LANCZOS)
        resized_icon.save(out_file, "PNG")
        print(f"Saved {out_file} ({target_dim}x{target_dim})")

    print("\nAll store and launcher graphics successfully generated!")


if __name__ == "__main__":
    main()

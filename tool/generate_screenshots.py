"""
Generates 5 High-Resolution (1080x1920) Google Play Store Phone Screenshots
per Spec Appendix C and Play Console guidelines:
1. screenshot_1_home.png: "ONE-TAP ADDICTIVE ARCADE" (Home Screen with glowing logo & best score)
2. screenshot_2_action.png: "LEAP OVER LETHAL HAZARDS" (Mid-air Zap over orange spikes & barriers)
3. screenshot_3_close_call.png: "RISK IT FOR NEAR-MISS POINTS" ("CLOSE! +5" near-miss arcade popup)
4. screenshot_4_charging_block.png: "SURVIVE LIGHTNING CHARGERS" (Telegraph warning & incoming charger)
5. screenshot_5_results.png: "INSTANT RETRY • BEAT YOUR BEST" (Results overlay with NEW BEST badge)
"""

import os
import sys
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
from generate_store_art import (
    BG_DEEP, BG_PURPLE, BG_DARK, CYAN, CYAN_DARK,
    MAGENTA, MAGENTA_DARK, ORANGE, YELLOW, WHITE, MUTED,
    get_font, create_radial_gradient, render_zap_sprite
)

WIDTH = 1080
HEIGHT = 1920
GROUND_Y = 1420


def draw_hud(draw, font_score, font_label, score=124, best=350):
    # Score in top center
    score_str = str(score)
    bbox = draw.textbbox((0, 0), score_str, font=font_score)
    sw = bbox[2] - bbox[0]
    draw.text(((WIDTH - sw) // 2, 280), score_str, font=font_score, fill=WHITE)

    # Best score in top right
    best_str = f"BEST {best}"
    bbox_b = draw.textbbox((0, 0), best_str, font=font_label)
    bw = bbox_b[2] - bbox_b[0]
    draw.text((WIDTH - bw - 60, 290), best_str, font=font_label, fill=MUTED)


def draw_ground(canvas, draw):
    # Ambient ground glow
    ground_glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    gg_draw = ImageDraw.Draw(ground_glow)
    gg_draw.rectangle([0, GROUND_Y - 20, WIDTH, GROUND_Y + 20], fill=(34, 227, 255, 110))
    ground_glow = ground_glow.filter(ImageFilter.GaussianBlur(radius=25))
    canvas.alpha_composite(ground_glow)

    # Solid ground
    draw.rectangle([0, GROUND_Y, WIDTH, HEIGHT], fill=(12, 17, 42))
    draw.line([(0, GROUND_Y), (WIDTH, GROUND_Y)], fill=CYAN, width=6)


def draw_top_banner(draw, headline: str, subtext: str):
    font_head = get_font(52, bold=True)
    font_sub = get_font(28, bold=True)

    # Decorative pill banner
    bbox_h = draw.textbbox((0, 0), headline, font=font_head)
    hw = bbox_h[2] - bbox_h[0]
    draw.text(((WIDTH - hw) // 2, 100), headline, font=font_head, fill=CYAN)

    bbox_s = draw.textbbox((0, 0), subtext, font=font_sub)
    sw = bbox_s[2] - bbox_s[0]
    draw.text(((WIDTH - sw) // 2, 175), subtext, font=font_sub, fill=MAGENTA)


def draw_spikes(draw, sx, count=1):
    sw = 80
    sh = 95
    for i in range(count):
        x = sx + i * 85
        pts = [(x, GROUND_Y), (x + sw // 2, GROUND_Y - sh), (x + sw, GROUND_Y)]
        draw.polygon(pts, fill=ORANGE)
        draw.line([pts[0], pts[1], pts[2]], fill=(255, 230, 140), width=4)


# =========================================================================
# Screenshot 1: Home Screen
# =========================================================================
def make_screenshot_1_home() -> Image.Image:
    canvas = create_radial_gradient(WIDTH, HEIGHT, (34, 22, 75), BG_DARK, cx_ratio=0.5, cy_ratio=0.4)
    draw = ImageDraw.Draw(canvas)

    draw_top_banner(draw, "ONE-TAP ARCADE RUNNER", "EASY TO LEARN • HARD TO MASTER")
    draw_ground(canvas, draw)

    # Central Zap on ground
    zap_size = 180
    zap_x = (WIDTH - zap_size) // 2
    zap_y = GROUND_Y - zap_size
    zap_sprite = render_zap_sprite(zap_size, with_feet=True)
    canvas.alpha_composite(zap_sprite, (zap_x, zap_y))

    # Glowing Logo
    font_logo = get_font(120, bold=True)
    draw.text((270, 500), "RAGE", font=font_logo, fill=CYAN)
    draw.text((580, 500), "TAP", font=font_logo, fill=MAGENTA)

    font_sub = get_font(32, bold=True)
    draw.text((360, 650), "ONE TAP. ZERO EXCUSES.", font=font_sub, fill=MUTED)

    # Best score card
    draw.rounded_rectangle([320, 780, 760, 900], radius=24, fill=(26, 17, 64, 230), outline=CYAN, width=3)
    font_score = get_font(42, bold=True)
    draw.text((380, 815), "BEST SCORE: 350", font=font_score, fill=WHITE)

    # PLAY Button
    draw.rounded_rectangle([290, 980, 790, 1120], radius=32, fill=(34, 227, 255, 230))
    font_btn = get_font(52, bold=True)
    draw.text((470, 1020), "PLAY", font=font_btn, fill=BG_DARK)

    # SETTINGS Button
    draw.rounded_rectangle([340, 1160, 740, 1270], radius=28, fill=(26, 17, 64, 200), outline=MUTED, width=2)
    font_btn_sec = get_font(36, bold=True)
    draw.text((450, 1195), "SETTINGS", font=font_btn_sec, fill=WHITE)

    return canvas


# =========================================================================
# Screenshot 2: Leap Over Lethal Hazards (Action)
# =========================================================================
def make_screenshot_2_action() -> Image.Image:
    canvas = create_radial_gradient(WIDTH, HEIGHT, (38, 20, 80), BG_DARK, cx_ratio=0.5, cy_ratio=0.45)
    draw = ImageDraw.Draw(canvas)

    draw_top_banner(draw, "TIMING IS EVERYTHING", "TAP TO HOP • HOLD TO LEAP HIGH")
    draw_ground(canvas, draw)

    font_score = get_font(90, bold=True)
    font_lbl = get_font(30, bold=True)
    draw_hud(draw, font_score, font_lbl, score=148, best=350)

    # Zap high in mid-air over double spikes
    zap_size = 170
    zap_x = 280
    zap_y = GROUND_Y - zap_size - 240

    # Jump aura
    zg_layer = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    zg_draw = ImageDraw.Draw(zg_layer)
    zg_draw.ellipse([zap_x - 30, zap_y - 30, zap_x + zap_size + 30, zap_y + zap_size + 30], fill=(34, 227, 255, 120))
    zg_layer = zg_layer.filter(ImageFilter.GaussianBlur(radius=25))
    canvas.alpha_composite(zg_layer)

    zap_sprite = render_zap_sprite(zap_size, in_air=True)
    canvas.alpha_composite(zap_sprite, (zap_x, zap_y))

    # Hazards approaching
    draw_spikes(draw, 340, count=2)
    draw_spikes(draw, 720, count=1)

    # Wall obstacle on right
    draw.rounded_rectangle([860, GROUND_Y - 210, 940, GROUND_Y], radius=12, fill=CYAN_DARK, outline=CYAN, width=4)

    return canvas


# =========================================================================
# Screenshot 3: Near Miss Close Call
# =========================================================================
def make_screenshot_3_close_call() -> Image.Image:
    canvas = create_radial_gradient(WIDTH, HEIGHT, (45, 20, 90), BG_DARK, cx_ratio=0.45, cy_ratio=0.4)
    draw = ImageDraw.Draw(canvas)

    draw_top_banner(draw, "HEART-POUNDING NEAR-MISSES", "GRAZE OBSTACLES FOR HUGE BONUS POINTS")
    draw_ground(canvas, draw)

    font_score = get_font(90, bold=True)
    font_lbl = get_font(30, bold=True)
    draw_hud(draw, font_score, font_lbl, score=215, best=350)

    # Zap clearing spike by 8 pixels!
    zap_size = 170
    zap_x = 360
    zap_y = GROUND_Y - 95 - zap_size - 10

    zap_sprite = render_zap_sprite(zap_size, in_air=True)
    canvas.alpha_composite(zap_sprite, (zap_x, zap_y))

    # Spike directly beneath
    draw_spikes(draw, 380, count=1)

    # "CLOSE! +5" floating badge
    font_close = get_font(68, bold=True)
    draw.rounded_rectangle([320, zap_y - 120, 680, zap_y - 20], radius=24, fill=(255, 46, 147, 230), outline=WHITE, width=4)
    draw.text((360, zap_y - 108), "CLOSE! +5", font=font_close, fill=WHITE)

    # Edge vignette shockwave
    edge_glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    eg_draw = ImageDraw.Draw(edge_glow)
    eg_draw.rectangle([0, 0, WIDTH, HEIGHT], outline=(255, 46, 147, 90), width=35)
    edge_glow = edge_glow.filter(ImageFilter.GaussianBlur(radius=20))
    canvas.alpha_composite(edge_glow)

    return canvas


# =========================================================================
# Screenshot 4: Charging Block & Telegraph Warning
# =========================================================================
def make_screenshot_4_charging_block() -> Image.Image:
    canvas = create_radial_gradient(WIDTH, HEIGHT, (50, 18, 70), BG_DARK, cx_ratio=0.5, cy_ratio=0.5)
    draw = ImageDraw.Draw(canvas)

    draw_top_banner(draw, "RAPID TELEGRAPH ALERTS", "REACT FAST TO INCOMING THREATS")
    draw_ground(canvas, draw)

    font_score = get_font(90, bold=True)
    font_lbl = get_font(30, bold=True)
    draw_hud(draw, font_score, font_lbl, score=284, best=350)

    # Red dashed telegraph line across the screen
    for x in range(0, WIDTH, 40):
        draw.line([(x, GROUND_Y - 60), (x + 20, GROUND_Y - 60)], fill=(255, 50, 80, 220), width=4)

    # Warning alert badge
    draw.rounded_rectangle([WIDTH - 380, GROUND_Y - 260, WIDTH - 60, GROUND_Y - 170], radius=16, fill=(255, 46, 90, 220))
    font_alert = get_font(34, bold=True)
    draw.text((WIDTH - 350, GROUND_Y - 235), "⚡ CHARGER!", font=font_alert, fill=WHITE)

    # Incoming Charger Block
    ch_x = 750
    ch_y = GROUND_Y - 120
    draw.rounded_rectangle([ch_x, ch_y, ch_x + 120, ch_y + 120], radius=20, fill=ORANGE, outline=YELLOW, width=5)

    # Zap running on ground preparing to jump
    zap_size = 170
    zap_x = 220
    zap_y = GROUND_Y - zap_size
    zap_sprite = render_zap_sprite(zap_size, with_feet=True)
    canvas.alpha_composite(zap_sprite, (zap_x, zap_y))

    return canvas


# =========================================================================
# Screenshot 5: Results & New Best
# =========================================================================
def make_screenshot_5_results() -> Image.Image:
    canvas = create_radial_gradient(WIDTH, HEIGHT, (35, 18, 70), BG_DARK, cx_ratio=0.5, cy_ratio=0.45)
    draw = ImageDraw.Draw(canvas)

    draw_top_banner(draw, "BEAT YOUR HIGH SCORE", "NO MENUS • RETRY IN A MILLISECOND")
    draw_ground(canvas, draw)

    # Modal Card
    card_x1, card_y1, card_x2, card_y2 = 140, 520, 940, 1320
    draw.rounded_rectangle([card_x1, card_y1, card_x2, card_y2], radius=36, fill=(22, 16, 52, 245), outline=CYAN, width=4)

    # "NEW BEST!" Badge
    draw.rounded_rectangle([370, 480, 710, 560], radius=24, fill=(255, 210, 63), outline=WHITE, width=3)
    font_badge = get_font(36, bold=True)
    draw.text((410, 500), "★ NEW BEST! ★", font=font_badge, fill=BG_DARK)

    # Score Text
    font_card_title = get_font(38, bold=True)
    font_big_score = get_font(120, bold=True)
    draw.text((460, 620), "SCORE", font=font_card_title, fill=MUTED)
    draw.text((415, 680), "382", font=font_big_score, fill=CYAN)

    # Stats: Near misses & time survived
    font_stat = get_font(32, bold=True)
    draw.text((260, 860), "Near Misses: 12", font=font_stat, fill=WHITE)
    draw.text((600, 860), "Time: 48.6s", font=font_stat, fill=WHITE)

    # RETRY Button (Primary Neon)
    draw.rounded_rectangle([220, 980, 860, 1110], radius=28, fill=CYAN)
    font_btn = get_font(48, bold=True)
    draw.text((450, 1020), "RETRY", font=font_btn, fill=BG_DARK)

    # HOME Button (Secondary)
    draw.rounded_rectangle([280, 1150, 800, 1260], radius=24, fill=(26, 17, 64, 200), outline=MUTED, width=2)
    font_btn_sec = get_font(36, bold=True)
    draw.text((480, 1180), "HOME", font=font_btn_sec, fill=WHITE)

    return canvas


def main():
    out_dir = os.path.join("store_assets", "screenshots")
    os.makedirs(out_dir, exist_ok=True)

    print("Generating Store Screenshot 1 (Home)...")
    s1 = make_screenshot_1_home()
    s1.save(os.path.join(out_dir, "1_home.png"), "PNG")

    print("Generating Store Screenshot 2 (Action)...")
    s2 = make_screenshot_2_action()
    s2.save(os.path.join(out_dir, "2_action.png"), "PNG")

    print("Generating Store Screenshot 3 (Close Call)...")
    s3 = make_screenshot_3_close_call()
    s3.save(os.path.join(out_dir, "3_close_call.png"), "PNG")

    print("Generating Store Screenshot 4 (Charging Block)...")
    s4 = make_screenshot_4_charging_block()
    s4.save(os.path.join(out_dir, "4_charging_block.png"), "PNG")

    print("Generating Store Screenshot 5 (Results)...")
    s5 = make_screenshot_5_results()
    s5.save(os.path.join(out_dir, "5_results.png"), "PNG")

    print(f"\nAll 5 store screenshots (1080x1920) generated in {out_dir}/!")


if __name__ == "__main__":
    main()

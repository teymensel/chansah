import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def make_circle_mask(size):
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse([0, 0, size, size], fill=255)
    return mask

# 1. 8-Directional Ottoman D-Pad (Yön Butonları Tableti - Resim 1, 2, 5)
def generate_dpad():
    size = 256
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size / 2.0
    
    # Outer dark brass/gold border with gradient bevel
    for r in range(120, 108, -1):
        ratio = (r - 108) / 12.0
        r_col = int(180 + ratio * 60)
        g_col = int(120 + ratio * 50)
        b_col = int(30 + ratio * 20)
        draw.ellipse([center - r, center - r, center + r, center + r], outline=(r_col, g_col, b_col, 255), width=2)
        
    # Aged ivory / parchment center disc
    inner_r = 108
    for r in range(inner_r, 0, -1):
        ratio = r / float(inner_r)
        # Vignette parchment
        base_r = int(215 - (1.0 - ratio) * 45)
        base_g = int(195 - (1.0 - ratio) * 55)
        base_b = int(150 - (1.0 - ratio) * 65)
        draw.ellipse([center - r, center - r, center + r, center + r], fill=(base_r, base_g, base_b, 255))
        
    # Draw ornate 8 directional arrows (4 cardinal, 4 diagonal)
    # Cardinal arrows
    cardinal_angles = [0, 90, 180, 270] # Right, Down, Left, Up
    gold_fill = (195, 140, 30, 255)
    gold_border = (120, 80, 15, 255)
    gold_light = (245, 210, 80, 255)
    
    arrow_dist = 78
    arrow_size = 22
    
    def draw_triangle(angle_deg, dist, sz, is_diag=False):
        rad = math.radians(angle_deg)
        cos_a = math.cos(rad)
        sin_a = math.sin(rad)
        # Tip point
        tip_x = center + cos_a * (dist + sz * 0.7)
        tip_y = center + sin_a * (dist + sz * 0.7)
        # Base points
        base_x = center + cos_a * (dist - sz * 0.3)
        base_y = center + sin_a * (dist - sz * 0.3)
        
        perp_x = -sin_a * (sz * 0.55 if not is_diag else sz * 0.4)
        perp_y = cos_a * (sz * 0.55 if not is_diag else sz * 0.4)
        
        p1 = (tip_x, tip_y)
        p2 = (base_x + perp_x, base_y + perp_y)
        p3 = (base_x - perp_x, base_y - perp_y)
        
        fill_col = gold_light if not is_diag else gold_fill
        draw.polygon([p1, p2, p3], fill=fill_col, outline=gold_border)

    # 4 Cardinal
    for ang in [270, 90, 180, 0]: # Up, Down, Left, Right
        draw_triangle(ang, arrow_dist, arrow_size, is_diag=False)
        
    # 4 Diagonals
    for ang in [315, 45, 135, 225]:
        draw_triangle(ang, arrow_dist - 6, arrow_size * 0.75, is_diag=True)
        
    # Center brass button hub
    hub_r = 26
    for r in range(hub_r, 0, -1):
        ratio = r / float(hub_r)
        r_c = int(230 - (1.0 - ratio) * 80)
        g_c = int(170 - (1.0 - ratio) * 80)
        b_c = int(50 - (1.0 - ratio) * 20)
        draw.ellipse([center - r, center - r, center + r, center + r], fill=(r_c, g_c, b_c, 255))
    draw.ellipse([center - hub_r, center - hub_r, center + hub_r, center + hub_r], outline=gold_border, width=2)
    # Inner ring
    draw.ellipse([center - 10, center - 10, center + 10, center + 10], outline=(140, 90, 20, 255), width=2)

    img.save('assets/ui/zaptiye_dpad.png')
    print("Saved zaptiye_dpad.png")

# 2. Revolver Cylinder Action Button (Resim 1 & 5)
def generate_revolver_cylinder():
    size = 180
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size / 2.0
    
    # Outer gold bezel
    outer_r = 84
    for r in range(outer_r, outer_r - 10, -1):
        ratio = (r - (outer_r - 10)) / 10.0
        draw.ellipse([center - r, center - r, center + r, center + r], outline=(int(210 + ratio*40), int(160 + ratio*40), int(40 + ratio*20), 255), width=2)
        
    # Cylinder disc (ivory/silver steel with brass highlights)
    inner_r = outer_r - 10
    draw.ellipse([center - inner_r, center - inner_r, center + inner_r, center + inner_r], fill=(225, 215, 190, 255), outline=(130, 90, 30, 255), width=3)
    
    # 6 bullet chambers
    chamber_dist = 42
    chamber_r = 14
    for i in range(6):
        ang = math.radians(i * 60)
        cx = center + math.cos(ang) * chamber_dist
        cy = center + math.sin(ang) * chamber_dist
        # Brass cartridge rim
        draw.ellipse([cx - chamber_r, cy - chamber_r, cx + chamber_r, cy + chamber_r], fill=(195, 155, 45, 255), outline=(90, 65, 20, 255), width=2)
        # Primer center
        draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(235, 205, 80, 255), outline=(110, 80, 25, 255))
        
    # Center ratchet pin
    draw.ellipse([center - 16, center - 16, center + 16, center + 16], fill=(120, 85, 25, 255), outline=(70, 45, 15, 255), width=2)
    draw.ellipse([center - 8, center - 8, center + 8, center + 8], fill=(220, 180, 60, 255))
    
    img.save('assets/ui/zaptiye_revolver_btn.png')
    print("Saved zaptiye_revolver_btn.png")

# 3. Sprint / Koşma Butonu (Gold Circle with Running Silhouette - Resim 1, 2, 5)
def generate_sprint_button():
    size = 180
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size / 2.0
    
    # Warm amber / gold radial glowing disc
    r_max = 84
    for r in range(r_max, 0, -1):
        ratio = r / float(r_max)
        red = int(220 * (1.0 - ratio * 0.3))
        green = int(140 * (1.0 - ratio * 0.45))
        blue = int(15 * (1.0 - ratio * 0.5))
        draw.ellipse([center - r, center - r, center + r, center + r], fill=(red, green, blue, 255))
    draw.ellipse([center - r_max, center - r_max, center + r_max, center + r_max], outline=(255, 215, 60, 255), width=4)
    
    # Golden running man silhouette
    # Head
    draw.ellipse([center + 2, center - 46, center + 24, center - 24], fill=(255, 240, 120, 255))
    # Body torso (slanted forward)
    draw.polygon([
        (center + 6, center - 22),
        (center + 18, center - 20),
        (center - 6, center + 14),
        (center - 18, center + 12)
    ], fill=(255, 240, 120, 255))
    # Front leg (bent forward)
    draw.line([(center - 6, center + 14), (center + 18, center + 26)], fill=(255, 240, 120, 255), width=8)
    draw.line([(center + 18, center + 26), (center + 24, center + 48)], fill=(255, 240, 120, 255), width=7)
    # Back leg (kicking back)
    draw.line([(center - 14, center + 12), (center - 32, center + 24)], fill=(255, 240, 120, 255), width=8)
    draw.line([(center - 32, center + 24), (center - 48, center + 16)], fill=(255, 240, 120, 255), width=7)
    # Front arm (swinging forward)
    draw.line([(center + 14, center - 16), (center + 32, center - 4)], fill=(255, 240, 120, 255), width=6)
    draw.line([(center + 32, center - 4), (center + 42, center - 16)], fill=(255, 240, 120, 255), width=5)
    # Back arm
    draw.line([(center + 4, center - 16), (center - 16, center - 8)], fill=(255, 240, 120, 255), width=6)
    draw.line([(center - 16, center - 8), (center - 28, center + 4)], fill=(255, 240, 120, 255), width=5)
    
    img.save('assets/ui/zaptiye_sprint_btn.png')
    print("Saved zaptiye_sprint_btn.png")

# 4. Melee / Fist Button (Yumruk & Tokat - Resim 1 & 5)
def generate_melee_button():
    size = 150
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size / 2.0
    
    r_max = 70
    draw.ellipse([center - r_max, center - r_max, center + r_max, center + r_max], fill=(225, 215, 190, 255), outline=(180, 130, 35, 255), width=4)
    draw.ellipse([center - r_max + 5, center - r_max + 5, center + r_max - 5, center + r_max - 5], outline=(120, 85, 20, 255), width=2)
    
    # Fist engraving
    # Wrist
    draw.rectangle([center - 14, center + 10, center + 14, center + 45], fill=(95, 75, 45, 255))
    # Fist body
    draw.ellipse([center - 25, center - 25, center + 25, center + 20], fill=(95, 75, 45, 255))
    # Knuckles / fingers
    for i in range(4):
        kx = center - 18 + i * 12
        draw.ellipse([kx - 5, center - 32, kx + 5, center - 16], fill=(130, 105, 65, 255), outline=(60, 45, 25, 255), width=2)
    # Thumb folded
    draw.ellipse([center - 28, center - 10, center - 10, center + 15], fill=(120, 95, 55, 255), outline=(60, 45, 25, 255), width=2)
    
    img.save('assets/ui/zaptiye_melee_btn.png')
    print("Saved zaptiye_melee_btn.png")

# 5. Throwing Daggers Fan Button (Fırlatma Bıçakları - Resim 1 & 5)
def generate_knives_button():
    size = 150
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size / 2.0
    
    r_max = 70
    draw.ellipse([center - r_max, center - r_max, center + r_max, center + r_max], fill=(225, 215, 190, 255), outline=(180, 130, 35, 255), width=4)
    
    # Draw 3 fanned throwing daggers
    for ang_deg in [-22, 0, 22]:
        rad = math.radians(ang_deg - 90)
        cos_a = math.cos(rad)
        sin_a = math.sin(rad)
        tip_x = center + cos_a * 45
        tip_y = center + sin_a * 45
        base_x = center - cos_a * 25
        base_y = center - sin_a * 25
        
        perp_x = -sin_a * 6
        perp_y = cos_a * 6
        
        # Blade
        draw.polygon([
            (tip_x, tip_y),
            (base_x + perp_x, base_y + perp_y),
            (base_x - perp_x, base_y - perp_y)
        ], fill=(185, 190, 200, 255), outline=(60, 65, 75, 255), width=1)
        # Center fuller line
        draw.line([(tip_x, tip_y), (base_x, base_y)], fill=(120, 125, 135, 255), width=1)
        # Hilt guard
        draw.line([(base_x + perp_x * 1.5, base_y + perp_y * 1.5), (base_x - perp_x * 1.5, base_y - perp_y * 1.5)], fill=(180, 140, 40, 255), width=3)
        # Handle
        handle_end_x = base_x - cos_a * 15
        handle_end_y = base_y - sin_a * 15
        draw.line([(base_x, base_y), (handle_end_x, handle_end_y)], fill=(100, 60, 30, 255), width=4)

    img.save('assets/ui/zaptiye_knife_btn.png')
    print("Saved zaptiye_knife_btn.png")

# 6. Pocket Watch / Time Focus Button (Köstekli Saat - Resim 1 & 5)
def generate_watch_button():
    size = 150
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    center = size / 2.0
    
    r_max = 70
    draw.ellipse([center - r_max, center - r_max, center + r_max, center + r_max], fill=(45, 30, 15, 255), outline=(215, 165, 45, 255), width=4)
    # Inner clock face
    draw.ellipse([center - 48, center - 48, center + 48, center + 48], fill=(235, 225, 185, 255), outline=(135, 95, 30, 255), width=2)
    # Clock ticks
    for i in range(12):
        ang = math.radians(i * 30)
        x1 = center + math.cos(ang) * 42
        y1 = center + math.sin(ang) * 42
        x2 = center + math.cos(ang) * 36
        y2 = center + math.sin(ang) * 36
        draw.line([(x1, y1), (x2, y2)], fill=(80, 55, 20, 255), width=2)
    # Hands
    draw.line([(center, center), (center + 18, center - 18)], fill=(40, 25, 10, 255), width=3)
    draw.line([(center, center), (center, center - 30)], fill=(40, 25, 10, 255), width=2)
    draw.ellipse([center - 4, center - 4, center + 4, center + 4], fill=(180, 130, 35, 255))
    
    img.save('assets/ui/zaptiye_watch_btn.png')
    print("Saved zaptiye_watch_btn.png")

# 7. Parchment Health Bar Frame (Resim 1, 2, 5 Sol Üst)
def generate_health_frame():
    w, h = 320, 60
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Ornate scroll / parchment border
    draw.rectangle([8, 8, w - 8, h - 8], fill=(235, 220, 185, 255), outline=(145, 105, 35, 255), width=3)
    # Outer trim
    draw.rectangle([4, 4, w - 4, h - 4], outline=(195, 155, 55, 255), width=2)
    # Corner curls
    for cx in [8, w - 8]:
        for cy in [8, h - 8]:
            draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(175, 130, 45, 255), outline=(100, 70, 20, 255), width=2)
            
    img.save('assets/ui/zaptiye_health_frame.png')
    print("Saved zaptiye_health_frame.png")

# 8. Main Menu Background (Sepia Wallpaper - Resim 3 & 4)
def generate_menu_bg():
    w, h = 1280, 720
    img = Image.new('RGB', (w, h), (210, 185, 135))
    draw = ImageDraw.Draw(img)
    
    # Sepia atmospheric gradient
    for y in range(h):
        ratio = y / float(h)
        r = int(225 - ratio * 45)
        g = int(195 - ratio * 55)
        b = int(140 - ratio * 55)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
        
    # Silhouette of Istanbul skyline & minarets
    # City wall
    draw.polygon([(0, 420), (w * 0.45, 480), (w, 440), (w, h), (0, h)], fill=(175, 150, 105))
    
    # Minarets
    minarets = [w * 0.12, w * 0.18, w * 0.28, w * 0.35]
    for mx in minarets:
        draw.rectangle([mx - 6, 180, mx + 6, 430], fill=(160, 135, 95))
        draw.polygon([(mx - 8, 180), (mx, 120), (mx + 8, 180)], fill=(150, 125, 85))
        draw.ellipse([mx - 10, 240, mx + 10, 252], fill=(150, 125, 85)) # Serefe
        
    # Large Dome
    draw.ellipse([w * 0.15 - 60, 320, w * 0.15 + 60, 440], fill=(165, 140, 100))
    
    # Right side: Heroic Zaptiye Officer Silhouettes (Sepia tint)
    officers = [
        {"cx": w * 0.75, "h": 520, "w": 180, "col": (120, 95, 65)},
        {"cx": w * 0.62, "h": 460, "w": 150, "col": (135, 110, 75)},
        {"cx": w * 0.88, "h": 480, "w": 160, "col": (130, 105, 70)}
    ]
    for off in officers:
        cx = off["cx"]
        # Torso
        draw.rectangle([cx - off["w"]*0.35, h - off["h"], cx + off["w"]*0.35, h], fill=off["col"])
        # Head
        draw.ellipse([cx - 32, h - off["h"] - 75, cx + 32, h - off["h"] - 15], fill=off["col"])
        # Fez
        draw.polygon([
            (cx - 24, h - off["h"] - 75),
            (cx + 24, h - off["h"] - 75),
            (cx + 20, h - off["h"] - 120),
            (cx - 20, h - off["h"] - 120)
        ], fill=(100, 75, 50))
        
    # Vignette & parchment grain
    img = img.filter(ImageFilter.GaussianBlur(radius=1.2))
    img.save('assets/ui/zaptiye_menu_bg.jpg', quality=92)
    print("Saved zaptiye_menu_bg.jpg")

if __name__ == '__main__':
    generate_dpad()
    generate_revolver_cylinder()
    generate_sprint_button()
    generate_melee_button()
    generate_knives_button()
    generate_watch_button()
    generate_health_frame()
    generate_menu_bg()

import math
import random
from PIL import Image, ImageDraw, ImageFilter

def clamp(val, low, high):
    return max(low, min(val, high))

# 1. Warm Polished Walnut Wood Texture (512x512)
def generate_wood():
    w, h = 512, 512
    img = Image.new('RGB', (w, h), (115, 65, 36))
    pixels = img.load()
    random.seed(42)
    
    for y in range(h):
        for x in range(w):
            # Rich wood grain streaks & subtle rings
            streak1 = math.sin(x * 0.04 + math.sin(y * 0.01) * 6.0) * 16.0
            streak2 = math.cos(x * 0.12 + y * 0.02) * 8.0
            fiber = (random.random() - 0.5) * 14.0
            tot = streak1 + streak2 + fiber
            
            r = int(clamp(126 + tot * 1.35, 60, 195))
            g = int(clamp(72 + tot * 0.85, 30, 125))
            b = int(clamp(40 + tot * 0.5, 15, 75))
            pixels[x, y] = (r, g, b)
            
    img = img.filter(ImageFilter.GaussianBlur(radius=0.6))
    img.save('assets/textures/mahfil_wood.png')
    print("Saved mahfil_wood.png")

# 2. Ornate Islamic Geometric Lattice (Seljuk 8-pointed star & fretwork matching Image 2 & 3)
def generate_lattice():
    w, h = 1024, 512
    # Super-sampling for razor sharp anti-aliased lattice
    scale = 2
    sw, sh = w * scale, h * scale
    img = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    wood_col = (130, 72, 38, 255)
    wood_hi = (165, 98, 55, 255)
    wood_dark = (85, 45, 22, 255)
    
    cell_w = 128 * scale
    cell_h = 128 * scale
    
    cols = sw // cell_w + 2
    rows = sh // cell_h + 2
    
    line_w = int(10 * scale)
    
    # Draw geometric interlocking lattice grid
    for r in range(-1, rows):
        for c in range(-1, cols):
            cx = c * cell_w + (cell_w // 2 if r % 2 == 1 else 0)
            cy = r * (cell_h * 0.75)
            
            # Draw 8-pointed star strapwork
            rad_outer = cell_w * 0.42
            rad_inner = rad_outer * 0.52
            
            pts1 = []
            pts2 = []
            for i in range(8):
                ang = i * (math.pi / 4.0)
                px1 = cx + math.cos(ang) * rad_outer
                py1 = cy + math.sin(ang) * rad_outer
                pts1.append((px1, py1))
                
                ang2 = ang + (math.pi / 8.0)
                px2 = cx + math.cos(ang2) * rad_inner
                py2 = cy + math.sin(ang2) * rad_inner
                pts2.append((px2, py2))
                
            star_pts = []
            for i in range(8):
                star_pts.append(pts1[i])
                star_pts.append(pts2[i])
                
            # Interconnecting ribbons between stars
            for i in range(8):
                p_next = pts1[(i + 3) % 8]
                draw.line([pts1[i], p_next], fill=wood_dark, width=line_w + 4)
                draw.line([pts1[i], p_next], fill=wood_col, width=line_w)
                draw.line([pts1[i], p_next], fill=wood_hi, width=max(1, line_w - 6))
                
            # Star outline
            for i in range(len(star_pts)):
                p_curr = star_pts[i]
                p_nxt = star_pts[(i + 1) % len(star_pts)]
                draw.line([p_curr, p_nxt], fill=wood_dark, width=line_w + 3)
                draw.line([p_curr, p_nxt], fill=wood_col, width=line_w)
                draw.line([p_curr, p_nxt], fill=wood_hi, width=max(1, line_w - 6))
                
            # Carved wooden center boss
            boss_r = 12 * scale
            draw.ellipse([cx - boss_r, cy - boss_r, cx + boss_r, cy + boss_r], fill=wood_hi, outline=wood_dark, width=2*scale)
            draw.ellipse([cx - boss_r*0.4, cy - boss_r*0.4, cx + boss_r*0.4, cy + boss_r*0.4], fill=wood_dark)

    # Frame rails (top and bottom border of the lattice panel)
    f_thick = 24 * scale
    draw.rectangle([0, 0, sw, f_thick], fill=wood_col)
    draw.rectangle([0, sh - f_thick, sw, sh], fill=wood_col)
    draw.line([(0, f_thick), (sw, f_thick)], fill=wood_hi, width=4*scale)
    draw.line([(0, sh - f_thick), (sw, sh - f_thick)], fill=wood_dark, width=4*scale)

    # Side end frames
    draw.rectangle([0, 0, f_thick, sh], fill=wood_col)
    draw.rectangle([sw - f_thick, 0, sw, sh], fill=wood_col)

    # Downscale for crisp smooth anti-aliased edges
    img = img.resize((w, h), Image.Resampling.LANCZOS)
    img.save('assets/textures/mahfil_lattice.png')
    print("Saved updated mahfil_lattice.png")

# 3. Base Carving Frieze (Diamond Faceted Molding as seen in Image 3)
def generate_base_frieze():
    w, h = 512, 128
    img = Image.new('RGB', (w, h), (120, 68, 38))
    draw = ImageDraw.Draw(img)
    
    step = 32
    for x in range(0, w, step):
        mid_x = x + step // 2
        # Upper facet (illuminated)
        draw.polygon([(x, 0), (mid_x, h//2), (x + step, 0)], fill=(155, 92, 52))
        # Lower facet (shaded)
        draw.polygon([(x, h), (mid_x, h//2), (x + step, h)], fill=(85, 45, 24))
        # Left facet
        draw.polygon([(x, 0), (mid_x, h//2), (x, h)], fill=(105, 58, 32))
        # Right facet
        draw.polygon([(x + step, 0), (mid_x, h//2), (x + step, h)], fill=(132, 76, 42))
        # Edges
        draw.line([(x, 0), (mid_x, h//2)], fill=(175, 110, 65), width=2)
        draw.line([(mid_x, h//2), (x, h)], fill=(65, 32, 16), width=2)
        draw.line([(x + step, 0), (mid_x, h//2)], fill=(165, 100, 58), width=2)
        draw.line([(mid_x, h//2), (x + step, h)], fill=(65, 32, 16), width=2)
        
    img = img.filter(ImageFilter.GaussianBlur(radius=0.4))
    img.save('assets/textures/mahfil_base_frieze.png')
    print("Saved mahfil_base_frieze.png")

if __name__ == '__main__':
    generate_wood()
    generate_lattice()
    generate_base_frieze()

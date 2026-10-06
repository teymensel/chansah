import math
import random
from PIL import Image, ImageDraw, ImageFilter

def clamp(val, low, high):
    return max(low, min(val, high))

def generate_seamless_grass(w=1024, h=1024):
    print("Generating 1024x1024 seamless grass texture...")
    random.seed(1337)
    
    # Base image
    img = Image.new('RGB', (w, h), (45, 95, 32))
    pixels = img.load()
    
    # Generate multi-frequency seamless base color noise
    for y in range(h):
        ny = y / h * 2.0 * math.pi
        sin_y1 = math.sin(ny * 4.0)
        cos_y1 = math.cos(ny * 4.0)
        sin_y2 = math.sin(ny * 12.0)
        sin_y3 = math.sin(ny * 32.0)
        
        for x in range(w):
            nx = x / w * 2.0 * math.pi
            sin_x1 = math.sin(nx * 4.0)
            cos_x1 = math.cos(nx * 4.0)
            sin_x2 = math.sin(nx * 12.0)
            sin_x3 = math.sin(nx * 32.0)
            
            # Toroidal seamless noise
            val1 = (sin_x1 * cos_y1 + cos_x1 * sin_y1) * 0.5
            val2 = (sin_x2 + sin_y2) * 0.25
            val3 = (sin_x3 * sin_y3) * 0.15
            dirt_speck = (random.random() - 0.5) * 0.18
            
            combined = val1 + val2 + val3 + dirt_speck
            
            # Rich Ottoman garden lawn palette: deep emerald base, vibrant sunlit olive/yellow-green tips, dark loam undertones
            r = int(clamp(52 + combined * 42, 28, 120))
            g = int(clamp(118 + combined * 55, 65, 185))
            b = int(clamp(38 + combined * 32, 18, 85))
            pixels[x, y] = (r, g, b)
            
    # Now draw fine grass blades seamlessly
    draw = ImageDraw.Draw(img)
    num_blades = 25000
    
    for _ in range(num_blades):
        bx = random.randint(0, w - 1)
        by = random.randint(0, h - 1)
        
        # Blade length & angle
        length = random.uniform(8.0, 22.0)
        angle = random.uniform(-0.5, 0.5) + (math.pi * 0.5) # mostly upright
        curve = random.uniform(-0.4, 0.4)
        
        col_type = random.random()
        if col_type < 0.35:
            # Bright yellow-green sunlit blade
            blade_col = (random.randint(95, 145), random.randint(155, 205), random.randint(35, 65))
        elif col_type < 0.75:
            # Lush vibrant green
            blade_col = (random.randint(45, 75), random.randint(125, 165), random.randint(30, 50))
        elif col_type < 0.92:
            # Deep shadow forest green
            blade_col = (random.randint(25, 45), random.randint(75, 110), random.randint(18, 35))
        else:
            # Subtle golden dry blade / chamomile fleck
            blade_col = (random.randint(140, 180), random.randint(145, 175), random.randint(50, 80))
            
        x0 = bx
        y0 = by
        x1 = bx + math.cos(angle) * (length * 0.5)
        y1 = by - math.sin(angle) * (length * 0.5)
        x2 = bx + math.cos(angle + curve) * length
        y2 = by - math.sin(angle + curve) * length
        
        # Seamless draw (draw wrapped on edges)
        for ox in [0, -w, w]:
            for oy in [0, -h, h]:
                draw.line([(x0+ox, y0+oy), (x1+ox, y1+oy)], fill=blade_col, width=2)
                draw.line([(x1+ox, y1+oy), (x2+ox, y2+oy)], fill=blade_col, width=1)
                
    # Add scattered tiny white/yellow chamomile flowers for realism
    for _ in range(350):
        fx = random.randint(0, w - 1)
        fy = random.randint(0, h - 1)
        fr = random.uniform(2.0, 4.0)
        for ox in [0, -w, w]:
            for oy in [0, -h, h]:
                draw.ellipse([fx+ox-fr, fy+oy-fr, fx+ox+fr, fy+oy+fr], fill=(245, 245, 230))
                draw.ellipse([fx+ox-fr*0.4, fy+oy-fr*0.4, fx+ox+fr*0.4, fy+oy+fr*0.4], fill=(240, 195, 40))

    img = img.filter(ImageFilter.GaussianBlur(radius=0.4))
    img.save('assets/textures/grass.png', quality=95)
    print("Saved assets/textures/grass.png")

def generate_grass_tuft_atlas(w=512, h=512):
    print("Generating 512x512 3D grass tuft billboard atlas...")
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    random.seed(999)
    
    # 2 tufts in atlas: left half (dense lush tuft), right half (flowering tuft)
    for half in [0, 1]:
        cx = 128 if half == 0 else 384
        base_y = h - 30
        
        num_blades = 220
        for _ in range(num_blades):
            bx = cx + random.gauss(0, 40)
            by = base_y + random.uniform(-10, 10)
            
            height = random.uniform(220, 420)
            spread = (bx - cx) / 80.0
            angle = spread * 0.45 + random.uniform(-0.15, 0.15)
            
            # Gradient color from dark root to bright tip
            c_val = random.random()
            if c_val < 0.4:
                col_tip = (120, 195, 45, 255)
            elif c_val < 0.8:
                col_tip = (65, 160, 40, 255)
            else:
                col_tip = (175, 185, 60, 255)
            col_root = (25, 75, 20, 255)
            
            tip_x = bx + math.sin(angle) * height + math.sin(angle * 2.0) * 40.0
            tip_y = by - math.cos(angle) * height
            mid_x = (bx + tip_x) * 0.5 + spread * 20.0
            mid_y = (by + tip_y) * 0.5
            
            w_root = random.randint(4, 7)
            draw.line([(bx, by), (mid_x, mid_y)], fill=col_root, width=w_root)
            draw.line([(mid_x, mid_y), (tip_x, tip_y)], fill=col_tip, width=max(1, w_root - 3))
            
            if half == 1 and random.random() < 0.08:
                # Small white/yellow wildflower at tip
                fl_r = random.uniform(5, 9)
                draw.ellipse([tip_x-fl_r, tip_y-fl_r, tip_x+fl_r, tip_y+fl_r], fill=(250, 248, 235, 255))
                draw.ellipse([tip_x-fl_r*0.4, tip_y-fl_r*0.4, tip_x+fl_r*0.4, tip_y+fl_r*0.4], fill=(245, 190, 30, 255))
                
    img.save('assets/textures/grass_tuft.png')
    print("Saved assets/textures/grass_tuft.png")

if __name__ == '__main__':
    generate_seamless_grass()
    generate_grass_tuft_atlas()

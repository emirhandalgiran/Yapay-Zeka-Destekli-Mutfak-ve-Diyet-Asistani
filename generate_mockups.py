import os
from PIL import Image, ImageDraw, ImageFilter

def create_gradient(width, height, top_color, bottom_color):
    """Creates a beautiful vertical gradient image."""
    base = Image.new("RGB", (width, height), top_color)
    top_r, top_g, top_b = top_color
    bot_r, bot_g, bot_b = bottom_color
    
    draw = ImageDraw.Draw(base)
    for y in range(height):
        # Linear interpolation
        ratio = y / float(height)
        r = int(top_r + (bot_r - top_r) * ratio)
        g = int(top_g + (bot_g - top_g) * ratio)
        b = int(top_b + (bot_b - top_b) * ratio)
        draw.line((0, y, width, y), fill=(r, g, b))
        
    return base

def draw_phone_mockup(base_img, screenshot_path, phone_w, phone_h, phone_y):
    """Draws a premium smartphone frame and overlays the screenshot inside it with a shadow."""
    phone_center_x = 400
    
    # Outer frame coordinates
    left = phone_center_x - phone_w // 2
    right = phone_center_x + phone_w // 2
    top = phone_y
    bottom = phone_y + phone_h
    
    # 1. Soft Shadow Layer
    shadow_layer = Image.new("RGBA", (800, 1200), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_layer)
    # Draw dark shadow shape offset by +15px vertically for depth
    s_draw.rounded_rectangle(
        [left, top + 15, right, bottom + 15],
        radius=46,
        fill=(0, 0, 0, 95)
    )
    # Blur the shadow layer
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(25))
    base_img.paste(shadow_layer, (0, 0), shadow_layer)
    
    # 2. Bezel and Metallic Border
    draw = ImageDraw.Draw(base_img)
    
    # Outer metallic border (silver-emerald glossy feel)
    draw.rounded_rectangle(
        [left, top, right, bottom],
        radius=46,
        fill=None,
        outline=(26, 82, 40),
        width=4
    )
    
    # Main black bezel
    draw.rounded_rectangle(
        [left + 2, top + 2, right - 2, bottom - 2],
        radius=44,
        fill=(13, 13, 13)
    )
    
    # 3. Resize and Paste Screen
    screen_w = phone_w - 28 # 14px bezel on each side
    screen_h = phone_h - 28 # 14px bezel on top/bottom
    screen_left = left + 14
    screen_top = top + 14
    
    if os.path.exists(screenshot_path):
        screen_img = Image.open(screenshot_path).convert("RGBA")
        screen_img = screen_img.resize((screen_w, screen_h), Image.Resampling.LANCZOS)
        
        # Clip screen with rounded corners
        mask = Image.new("L", (screen_w, screen_h), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([0, 0, screen_w, screen_h], radius=32, fill=255)
        
        screen_layer = Image.new("RGBA", (800, 1200), (0, 0, 0, 0))
        screen_layer.paste(screen_img, (screen_left, screen_top), mask)
        base_img.paste(screen_layer, (0, 0), screen_layer)
        
        # 4. Thin bezel separator border for premium rendering
        draw.rounded_rectangle(
            [screen_left, screen_top, screen_left + screen_w, screen_top + screen_h],
            radius=32,
            fill=None,
            outline=(39, 174, 96, 40), # very subtle green outline
            width=1
        )
        
        # 5. Dynamic Island (centered inside screen, near the top)
        island_w = 100
        island_h = 24
        island_left = 400 - island_w // 2
        island_top = screen_top + 16
        
        draw.rounded_rectangle(
            [island_left, island_top, island_left + island_w, island_top + island_h],
            radius=12,
            fill=(10, 10, 10)
        )
        
        # Tiny lens reflection shine inside dynamic island
        lens_r = 4
        lens_x = island_left + 16
        lens_y = island_top + island_h // 2
        draw.ellipse(
            [lens_x - lens_r, lens_y - lens_r, lens_x + lens_r, lens_y + lens_r],
            fill=(17, 34, 27)
        )
        
        print(f"Rendered screen mockup successfully for {screenshot_path}")
    else:
        print(f"Warning: Screenshot not found: {screenshot_path}")

def generate_all_mockups():
    print("Generating professional, text-free smartphone mockups...")
    
    # Output images mapping
    mockups = [
        {"raw": "screenshot_onboarding.png", "out": "auracook_promo_onboarding.png"},
        {"raw": "screenshot_fridge.png", "out": "auracook_promo_smart_fridge.png"},
        {"raw": "screenshot_chef.png", "out": "auracook_promo_ai_chef.png"},
        {"raw": "screenshot_social.png", "out": "auracook_promo_social.png"},
        {"raw": "screenshot_profile.png", "out": "auracook_promo_eco_impact.png"}
    ]
    
    img_dir = os.path.join("assets", "images")
    os.makedirs(img_dir, exist_ok=True)
    
    # Premium vertical gradient top and bottom colors
    top_color = (6, 28, 14)       # Deep dark forest green
    bottom_color = (25, 90, 43)    # Glowing emerald/forest green
    
    for m in mockups:
        raw_path = os.path.join(img_dir, m["raw"])
        out_path = os.path.join(img_dir, m["out"])
        
        # 1. Base gradient
        base_img = create_gradient(800, 1200, top_color, bottom_color)
        
        # 2. Glowing green background aura orb
        aura_layer = Image.new("RGBA", (800, 1200), (0, 0, 0, 0))
        draw_aura = ImageDraw.Draw(aura_layer)
        draw_aura.ellipse(
            [400 - 250, 600 - 250, 400 + 250, 600 + 250],
            fill=(46, 204, 113, 30) # Soft emerald green with ~12% opacity
        )
        aura_layer = aura_layer.filter(ImageFilter.GaussianBlur(100)) # severe blur for smooth glow
        base_img.paste(aura_layer, (0, 0), aura_layer)
        
        # 3. Draw phone mockup frame (Fits nicely with 66px padding)
        # Width: 496px, Height: 1068px, centered (exact 9:20 aspect ratio)
        draw_phone_mockup(base_img, raw_path, phone_w=496, phone_h=1068, phone_y=66)
        
        # 4. Save final mockup
        base_img.save(out_path, "PNG")
        print(f"Saved premium mockup: {out_path}")

if __name__ == "__main__":
    generate_all_mockups()
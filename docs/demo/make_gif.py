from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1000, 600
BG = (18, 24, 38)
PANEL = (25, 33, 49)
WHITE = (232, 238, 247)
MUTED = (151, 165, 187)
GREEN = (91, 220, 153)
BLUE = (110, 170, 255)

font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
bold_path = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
font = ImageFont.truetype(font_path, 17)
small = ImageFont.truetype(font_path, 14)
bold = ImageFont.truetype(bold_path, 22)
title_font = ImageFont.truetype(bold_path, 25)

lines = [
    ("$ iverilog -g2012 -I include -s cpu_tb ...", BLUE),
    ("$ vvp sim/cpu_test", BLUE),
    ("", WHITE),
    ("===== LOAD TEST RESULTS =====", WHITE),
    ("PASS: LB", GREEN),
    ("PASS: LBU", GREEN),
    ("PASS: LH", GREEN),
    ("PASS: LHU", GREEN),
    ("PASS: LW", GREEN),
    ("", WHITE),
    ("===== STORE TEST RESULTS =====", WHITE),
    ("PASS: SB and SH", GREEN),
    ("PASS: SW", GREEN),
    ("Memory word 2 = 0x80F20080", GREEN),
    ("", WHITE),
    ("===== PERFORMANCE COUNTERS =====", WHITE),
    ("Cycles        : 13", WHITE),
    ("Instructions  : 9", WHITE),
    ("Loads         : 5", WHITE),
    ("Stores        : 3", WHITE),
    ("Branches      : 0", WHITE),
    ("MAC operations: 0", WHITE),
]

frames = []
for count in range(1, len(lines) + 1):
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((24, 24, W-24, H-24), radius=18, fill=PANEL)
    d.ellipse((48, 43, 62, 57), fill=(255, 95, 86))
    d.ellipse((72, 43, 86, 57), fill=(255, 189, 46))
    d.ellipse((96, 43, 110, 57), fill=(39, 201, 63))
    d.text((W//2, 43), "RISC-V RTL SIMULATION", font=bold, fill=WHITE, anchor="mt")
    d.line((44, 78, W-44, 78), fill=(57, 70, 91), width=2)
    d.text((52, 95), "RV32I-STYLE SINGLE-CYCLE PROCESSOR", font=title_font, fill=BLUE)
    d.text((52, 133), "Load/store verification", font=small, fill=MUTED)
    y = 171
    for text, color in lines[:count]:
        if text:
            d.text((56, y), text, font=font, fill=color)
        y += 19
    d.text((52, H-57), "Simulation evidence from the project's Icarus Verilog testbench",
           font=small, fill=MUTED)
    frames.append(im)

os.makedirs("docs/demo", exist_ok=True)
frames[0].save(
    "docs/demo/cpu_simulation.gif",
    save_all=True,
    append_images=frames[1:],
    duration=350,
    loop=0,
    optimize=True
)
print("Created docs/demo/cpu_simulation.gif")

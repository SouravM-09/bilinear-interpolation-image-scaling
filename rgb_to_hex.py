from PIL import Image
import os

# --- Configuration (Must match your Verilog Testbench!) ---
# --- Configuration (Must match your Verilog Testbench!) ---
IMAGE_PATH = r"D:\USER\Downloads\input.jpg.jpeg"  # Added 'r' here
HEX_PATH = r"D:\USER\Downloads\input_image.hex"   # Added 'r' here
W_IN = 500
H_IN = 500
CHANNELS = 3 # 1 for Grayscale, 3 for RGB

def generate_hex():
    try:
        # 1. Load and resize the image
        img = Image.open(IMAGE_PATH)
        img = img.resize((W_IN, H_IN), Image.Resampling.NEAREST)
        
        # 2. Convert to correct color mode
        if CHANNELS == 1:
            img = img.convert('L') # Convert to grayscale
        else:
            img = img.convert('RGB')
            
        pixels = img.load()
        
        # 3. Write to hex file
        with open(HEX_PATH, 'w') as f:
            for y in range(H_IN):
                for x in range(W_IN):
                    if CHANNELS == 1:
                        # Grayscale: 1 byte (e.g., "a4")
                        val = pixels[x, y]
                        f.write(f"{val:02x}\n")
                    else:
                        # RGB: 3 bytes packed as RRGGBB (e.g., "ff00a4")
                        r, g, b = pixels[x, y]
                        # R is MSB [23:16], G is [15:8], B is LSB [7:0]
                        f.write(f"{r:02x}{g:02x}{b:02x}\n")
                        
        print(f"Success! Generated {HEX_PATH} ({W_IN}x{H_IN}, {CHANNELS} channels)")
        
    except Exception as e:
        print(f"Error: {e}")
        print("Make sure you have an image named 'test_image.png' in this folder.")

if __name__ == "__main__":
    generate_hex()

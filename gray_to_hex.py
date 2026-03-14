from PIL import Image

def image_to_gray_hex(input_path, output_path):
    # Open image and convert to 8-bit grayscale ('L' mode)
    img = Image.open(input_path).convert('L')
    
    # Get pixel data as a list of integers (0-255)
    pixels = list(img.getdata())
    
    with open(output_path, 'w') as f:
        for i, pixel in enumerate(pixels):
            # Convert integer to 2-digit uppercase Hex
            hex_val = f"{pixel:02X}"
            
            # Write hex value; usually one per line for $readmemh
            f.write(hex_val + '\n')

    print(f"Success! Hex file saved to: {output_path}")
    print(f"Total pixels processed: {len(pixels)}")

# Usage
# Ensure you use the correct path for your system
image_to_gray_hex("C:/Users/Devraj/Downloads/gray_input.jpeg", 
                   "C:/Users/Devraj/Downloads/gray_input.hex")
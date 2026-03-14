from PIL import Image

def hex_to_png(input_file, output_file, width, height):
    # Create a new RGB image
    img = Image.new("RGB", (width, height))
    pixels = img.load()

    try:
        with open(input_file, 'r') as f:
            # Read lines and strip whitespace/newlines
            hex_data = [line.strip() for line in f if line.strip()]
            
        # Fill the image pixel by pixel
        for y in range(height):
            for x in range(width):
                idx = y * width + x
                if idx < len(hex_data):
                    # Convert hex string (RRGGBB) to integer tuple (R, G, B)
                    hex_val = hex_data[idx]
                    r = int(hex_val[0:2], 16)
                    g = int(hex_val[2:4], 16)
                    b = int(hex_val[4:6], 16)
                    pixels[x, y] = (r, g, b)
                else:
                    # If file is shorter than expected, fill with black
                    pixels[x, y] = (0, 0, 0)

        img.save(output_file)
        print(f"Success! Image saved as {output_file}")

    except FileNotFoundError:
        print("Error: Hex file not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Parameters matching your Verilog module (W_OUT, H_OUT)
W_OUT = 1000
H_OUT = 1000

hex_to_png(r"C:\Users\Devraj\Downloads\output_rgb1.hex", r"C:\Users\Devraj\Downloads\scaled_output.png", W_OUT, H_OUT)
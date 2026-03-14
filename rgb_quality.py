import numpy as np
import cv2
from skimage.metrics import structural_similarity as ssim

# =====================================================
# CONFIGURATION — CHANGE ONLY THESE PATHS
# =====================================================

INPUT_IMAGE_PATH = r"C:\Users\Devraj\Downloads\input.jpg"
HEX_OUTPUT_PATH  = r"C:\Users\Devraj\Downloads\output_rgb.hex"

W_OUT = 1000
H_OUT = 1000
CHANNELS = 3   # 3 for RGB, 1 for grayscale

# =====================================================
# READ VERILOG HEX IMAGE
# =====================================================

def read_hex_image(filename, width, height, channels):
    values = []

    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            if line.startswith('@'):  # skip address markers
                continue

            values.append(int(line, 16))

    data = np.array(values, dtype=np.uint32)

    expected_pixels = width * height

    if len(data) < expected_pixels:
        raise ValueError("Hex file does not contain enough pixel data")

    data = data[:expected_pixels]  # trim extra values

    if channels == 3:
        R = (data >> 16) & 0xFF
        G = (data >> 8) & 0xFF
        B = data & 0xFF

        img = np.stack([R, G, B], axis=1)
        img = img.reshape((height, width, 3)).astype(np.uint8)
    else:
        img = data.reshape((height, width)).astype(np.uint8)

    return img

# =====================================================
# LOAD INPUT IMAGE
# =====================================================

input_img = cv2.imread(INPUT_IMAGE_PATH)

if CHANNELS == 3:
    input_img = cv2.cvtColor(input_img, cv2.COLOR_BGR2RGB)
else:
    input_img = cv2.cvtColor(input_img, cv2.COLOR_BGR2GRAY)

# =====================================================
# GENERATE FLOATING-POINT REFERENCE (GOLDEN OUTPUT)
# =====================================================

reference_img = cv2.resize(
    input_img,
    (W_OUT, H_OUT),
    interpolation=cv2.INTER_LINEAR
)

# =====================================================
# LOAD VERILOG OUTPUT
# =====================================================

verilog_img = read_hex_image(HEX_OUTPUT_PATH, W_OUT, H_OUT, CHANNELS)

# =====================================================
# COMPUTE PSNR
# =====================================================

psnr_value = cv2.PSNR(reference_img, verilog_img)

# =====================================================
# COMPUTE SSIM
# =====================================================

if CHANNELS == 3:
    ssim_value = ssim(reference_img, verilog_img, channel_axis=2, data_range=255)
else:
    ssim_value = ssim(reference_img, verilog_img, data_range=255)

# =====================================================
# PRINT RESULTS
# =====================================================

print("=================================")
print("PSNR :", round(psnr_value, 4), "dB")
print("SSIM :", round(ssim_value, 6))
print("=================================")

# =====================================================
# OPTIONAL: SHOW DIFFERENCE MAP
# =====================================================

diff = cv2.absdiff(reference_img, verilog_img)

if CHANNELS == 3:
    diff_show = cv2.cvtColor(diff, cv2.COLOR_RGB2BGR)
else:
    diff_show = diff

cv2.imshow("Reference", cv2.cvtColor(reference_img, cv2.COLOR_RGB2BGR))
cv2.imshow("Verilog Output", cv2.cvtColor(verilog_img, cv2.COLOR_RGB2BGR))


cv2.waitKey(0)
cv2.destroyAllWindows()
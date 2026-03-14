import numpy as np
import cv2
from skimage.metrics import structural_similarity as ssim

# =====================================================
# CONFIGURATION
# =====================================================

INPUT_IMAGE_PATH = r"C:\Users\Devraj\Downloads\gray_input.jpeg"
HEX_OUTPUT_PATH  = r"C:\Users\Devraj\Downloads\output_gray.hex"

W_OUT = 1000
H_OUT = 1000
CHANNELS = 1

# =====================================================
# READ GRAYSCALE HEX IMAGE
# =====================================================

def read_hex_image_gray(filename, width, height):
    values = []

    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            if line.startswith('@'):
                continue

            values.append(int(line, 16) & 0xFF)

    data = np.array(values, dtype=np.uint8)

    expected_pixels = width * height

    if len(data) < expected_pixels:
        raise ValueError("Hex file does not contain enough pixel data")

    data = data[:expected_pixels]

    img = data.reshape((height, width))
    return img

# =====================================================
# LOAD INPUT IMAGE AS GRAYSCALE
# =====================================================

input_img = cv2.imread(INPUT_IMAGE_PATH, cv2.IMREAD_GRAYSCALE)

# =====================================================
# GENERATE FLOATING-POINT REFERENCE
# =====================================================

reference_img = cv2.resize(
    input_img,
    (W_OUT, H_OUT),
    interpolation=cv2.INTER_LINEAR
)

# =====================================================
# LOAD VERILOG OUTPUT
# =====================================================

verilog_img = read_hex_image_gray(HEX_OUTPUT_PATH, W_OUT, H_OUT)

# =====================================================
# COMPUTE PSNR
# =====================================================

psnr_value = cv2.PSNR(reference_img, verilog_img)

# =====================================================
# COMPUTE SSIM
# =====================================================

ssim_value = ssim(reference_img, verilog_img, data_range=255)

# =====================================================
# PRINT RESULTS
# =====================================================

print("=================================")
print("PSNR :", round(psnr_value, 4), "dB")
print("SSIM :", round(ssim_value, 6))
print("=================================")

# =====================================================
# SHOW RESULTS
# =====================================================

diff = cv2.absdiff(reference_img, verilog_img)

cv2.imshow("Reference", reference_img)
cv2.imshow("Verilog Output", verilog_img)
cv2.imshow("Absolute Difference", diff)

cv2.waitKey(0)
cv2.destroyAllWindows()
import cv2
import numpy as np
from skimage.metrics import structural_similarity as ssim
from skimage.metrics import peak_signal_noise_ratio as psnr

# --- Configuration ---
# Ensure these paths point to your actual files
ORIGINAL_IMAGE = r"D:\USER\Downloads\input.jpg.jpeg"
HARDWARE_OUTPUT = r"D:\USER\Downloads\scaled_result.png"

# The final resolution your hardware generated
W_OUT = 1000
H_OUT = 1000

def evaluate_quality():
    print("Loading images...")
    
    # 1. Load the original input image
    img_orig = cv2.imread(ORIGINAL_IMAGE)
    if img_orig is None:
        print(f"Error: Could not load original image at {ORIGINAL_IMAGE}")
        return

    # 2. Create the "Golden Reference" using perfect software floating-point math
    reference_img = cv2.resize(img_orig, (W_OUT, H_OUT), interpolation=cv2.INTER_LINEAR)

    # 3. Load your Verilog hardware's fixed-point output
    hw_img = cv2.imread(HARDWARE_OUTPUT)
    if hw_img is None:
        print(f"Error: Could not load hardware output at {HARDWARE_OUTPUT}")
        return

    # Safety check
    if reference_img.shape != hw_img.shape:
        print(f"Error: Dimension mismatch! Reference is {reference_img.shape}, Hardware is {hw_img.shape}")
        return

    print("Calculating metrics (this might take a moment)...")

    # 4. Calculate PSNR
    psnr_value = psnr(reference_img, hw_img)

    # 5. Calculate SSIM (channel_axis=2 tells it we are using RGB images)
    ssim_value = ssim(reference_img, hw_img, channel_axis=2)

    # 6. Display Results
    print("\n========== SCALE-X EVALUATION ==========")
    print(f"Resolution : {W_OUT} x {H_OUT}")
    print(f"PSNR Score : {psnr_value:.2f} dB")
    print(f"SSIM Score : {ssim_value:.4f}")
    print("========================================")
    
    # Interpretation Guide
    print("\nHow to read these scores:")
    print("- PSNR: Above 30 dB is generally acceptable. Above 40 dB is excellent.")
    print("- SSIM: Ranges from 0 to 1.0. A score above 0.95 is virtually identical to the human eye.")

if __name__ == "__main__":
    evaluate_quality()

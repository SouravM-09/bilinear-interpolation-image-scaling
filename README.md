# bilinear-interpolation-image-scaling

# Hardware Image Scaler using Bilinear Interpolation (Verilog HDL)

This project implements a **hardware-based image scaling module using bilinear interpolation** in Verilog HDL.  
The design focuses on building a **digital architecture capable of resizing images efficiently using fixed-point arithmetic**, making it suitable for FPGA and hardware acceleration applications.

---

## Project Overview

Image scaling is widely used in image processing systems such as cameras, displays, and embedded vision devices.  
Bilinear interpolation provides smoother results than nearest-neighbour interpolation by considering the **four nearest pixels surrounding a target pixel**.

This project implements the interpolation process completely in **hardware using Verilog HDL**.

---

## Key Features

- Hardware implementation of **bilinear interpolation algorithm**
- **FSM-based control architecture**
- Uses **fixed-point arithmetic (Q8.8 format)** to avoid floating point computation
- Supports **both grayscale and RGB images**
- **Parameterized design** allowing configurable input and output resolutions
- Designed for **FPGA and hardware accelerator applications**

---

## Hardware Architecture

The system architecture consists of the following components:

### 1. Control FSM
Controls the scaling process, manages memory addressing and coordinates interpolation operations.

### 2. Memory Address Generator
Fetches the four neighbouring pixels required for interpolation:

p00, p10, p01, p11

### 3. Interpolation Unit
Computes the output pixel value using bilinear interpolation formula.

### 4. Fixed-Point Arithmetic Unit
Implements interpolation calculations using **Q8.8 fixed-point representation** for efficient hardware execution.

---

## Bilinear Interpolation Concept

For a target pixel located between four neighbouring pixels:

P(x,y) is computed using a weighted average of:

- P00
- P10
- P01
- P11

This produces smoother scaling compared to nearest neighbour interpolation.

---

## Tools Used

- **Verilog HDL**
- **Vivado** (for simulation and synthesis)
- **MATLAB / Python** (optional image preprocessing)

---

## Repository Structure


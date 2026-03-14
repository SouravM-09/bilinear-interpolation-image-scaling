# bilinear-interpolation-image-scaling

# Hardware Image Scaler using Bilinear Interpolation (Verilog HDL)

This project implements a **hardware-based image scaling system using bilinear interpolation** in **Verilog HDL**. All modules (`top-level scaler`, `interpolation unit`, and `control FSM`) are combined in a single file: `image.v`. The design demonstrates how image processing algorithms can be implemented directly in hardware using digital architecture.

The system computes interpolated pixel values by considering the **four neighbouring pixels** around a target pixel and generating a smooth scaled image output. The architecture is designed to be **efficient, parameterized, and suitable for FPGA-based image processing applications**.

---

## Project Overview

Image scaling is an important operation in many digital systems such as:

* Digital cameras
* Display controllers
* Video processing units
* Embedded vision systems

Bilinear interpolation provides better image quality compared to nearest-neighbour interpolation by using a **weighted average of surrounding pixels**.

This project implements the bilinear interpolation algorithm in **hardware using Verilog HDL**, making it suitable for **real-time and hardware-accelerated image processing**.

---

## Key Features

* Hardware implementation of **bilinear interpolation algorithm**
* **FSM-based control architecture**
* Uses **fixed-point arithmetic (Q8.8)** to avoid floating-point computation
* Fetches **four neighbouring pixels (p00, p10, p01, p11)** for interpolation
* **Parameterized architecture** supporting multiple image resolutions
* Supports **both grayscale and RGB image scaling**
* Designed for **FPGA and hardware accelerator applications**

---

## Hardware Architecture

The system is composed of several digital blocks:

### 1. Control FSM

Controls the scaling process and manages the sequence of interpolation operations.

### 2. Memory Address Generator

Generates addresses required to fetch the four neighbouring pixels from memory.

### 3. Interpolation Unit

Performs bilinear interpolation to compute the scaled pixel value.

### 4. Fixed-Point Arithmetic Unit

Implements the interpolation calculations using **Q8.8 fixed-point representation** to reduce hardware complexity.

---

## Bilinear Interpolation Concept

For a pixel located between four neighbouring pixels:

* p00
* p10
* p01
* p11

The output pixel value is computed using a weighted average of these four pixels.

This method provides **smoother image scaling results compared to nearest-neighbour interpolation**.

---

## Tools Used

* **Verilog HDL** – Hardware description and design
* **Vivado / ModelSim / Icarus Verilog** – Simulation and synthesis
* **MATLAB / Python** – Image preprocessing (optional)

---

## Repository Structure
verilog-bilinear-image-scaler/
│
├── src/
│ └── image.v # All Verilog modules combined in one file
│
├── testbench/
│ └── tb_image_scaler.v # Testbench for simulation
│
├── images/
│ └── input_image.png # Example input image
│
└── README.md


---

## Simulation

1. Open your preferred **Verilog simulator** (Vivado, ModelSim, Icarus Verilog).  
2. Add the source file `src/image.v` and the testbench `testbench/tb_image_scaler.v`.  
3. Compile the design and run the simulation.  
4. Observe the scaled output in the waveform or export the processed image from simulation output.

---

## Applications

* FPGA-based image processing systems  
* Real-time video scaling  
* Embedded multimedia devices  
* Hardware accelerators for image processing  

---

## Future Improvements

* FPGA implementation and hardware testing  
* Pipeline optimization for higher throughput  
* Integration with video processing pipeline  

---

## Author

**Sourav Mandal**  
B.Tech Electronics Engineering  
IIT (BHU) Varanasi  
[LinkedIn](https://www.linkedin.com/in/sourav-mandal-91517b320) | [Email](mailto:sourav.mandal.ece24@itbhu.ac.in)

# Image Processing on FPGA

## Implementation of Sobel Filter for Edge Detection

This project implements the Sobel filter for edge detection on a 1280x720 image using an FPGA. The project is developed on the **PYNQ development board by TUL**, which is based on the **AMD (Xilinx) Zynq 7020 SoC (FPGA + ARM processor)**. The hardware IP is written in **Verilog**, while **Python** is used to manage the process.

### Author: Adir Ohayon

---

## Introduction

### Image Processing

Image processing is a field in computer science and engineering that involves representing an image as a matrix and manipulating it through mathematical operations. For grayscale images, the representation is a **2D matrix**, where:
- Each cell is called a **pixel**.
- Each pixel contains a value between **0 and 255**, where **0** represents black and **255** represents white.

#### Goals of Image Processing
- **Enhance visual quality**
- **Feature detection**
- **Region segmentation**
- **Content interpretation**

#### Types of Image Processing
1. **Point Operations**: Operations applied to each pixel independently, e.g., brightness adjustment.
2. **Image Filters**: Operations that consider neighboring pixels using convolution.

---

## Edge Detection

Edge detection is a fundamental technique in image processing that helps identify object boundaries within an image. It detects areas with significant intensity changes and is crucial for applications such as:
- **Object recognition**
- **Image segmentation**
- **Computer vision**

<p align="center">
  <img src="https://github.com/user-attachments/assets/9d9b3c3c-2056-482d-a68e-aded1098abed" width="600">
</p>
<p align="center">1. Example of edge detection</p>

#### Objectives of Edge Detection
- **Highlight Boundaries**: Emphasizes the borders between different regions.
- **Simplify Images**: Reduces complexity while maintaining critical details.
- **Prepare for Further Analysis**: Provides a basis for object tracking and detection.

---

## Sobel Filter

The **Sobel filter** is a widely used edge detection technique that calculates the gradient of image intensity at each pixel to highlight rapid changes in intensity (edges of objects).

### Operating Principle
1. **Convolution with Kernels**
   - The Sobel filter applies two convolution kernels:
     - **Horizontal Kernel (Sobel-X)**: Detects vertical edges.
       
       ![image](https://github.com/user-attachments/assets/c3f598c5-1e25-49f9-b230-30f31a8535ee)

     - **Vertical Kernel (Sobel-Y)**: Detects horizontal edges.
    
       ![image](https://github.com/user-attachments/assets/9cf43b55-05fd-4079-9e08-55684d19e893)

3. **Gradient Calculation**
   - The gradients in the **X** (horizontal) and **Y** (vertical) directions are computed.

4. **Magnitude Calculation**
   - The gradient magnitude is calculated as:
  
     ![image](https://github.com/user-attachments/assets/cc8d3fe1-8357-4c15-9182-0ae257fa2175)

   - If the magnitude **G** is greater than a threshold value, the pixel is set to **white**; otherwise, it is set to **black**.

---

## Application

In this project the Sobel filter is implemented in hardware using Verilog RTL code and then package as IP in Vivado design software.
The IP contain 3 components under Top_AXIS.v that suitable for AXI4 Stream protocol.

### Verilog code explain 

#### 1. Line_Buffer.v

The Line_Buffer module implements a single-row memory buffer used in FPGA-based image processing systems. Its purpose is to store one full image row and provide neighboring pixels required for convolution. The module supports continuous streaming operation by simultaneously writing incoming pixels and generating a 3-pixel horizontal output window. The design also includes simple zero-padding at the image boundaries to support edge processing.

The module operates using the system clock `clk` and reset signal `rst`. The input `wr_in` enables writing incoming pixels into the buffer, while `rd_in` enables reading data from the buffer. The input `data_in[7:0]` represents an 8-bit grayscale pixel. The output `data_out[23:0]` contains three adjacent pixels concatenated together into a 24-bit bus. The design contains a memory array called `line_B` with 1282 storage locations, each storing one 8-bit pixel. Two internal pointers are used to manage memory access: `wrPntr` controls the write position and `rdPntr` controls the read position. The first memory location `(line_B[0])` and the last memory location `(line_B[1281])` are initialized to zero. These additional locations are used for zero padding at the image edges.

**Module Operation:**

During operation, incoming pixels are continuously written into the line buffer whenever `wr_in` is asserted. The pixel is stored at the memory location indexed by `wrPntr + 1`. This means that actual image pixels are stored between memory locations 1 and 1280, while the first and last locations remain fixed at zero.
When `rd_in` assert, the reading data from the buffer process start. The module continuously generates a 3-pixel output window using the current read pointer position. The output consists of three consecutive pixels from memory: the current pixel, the next pixel, and the following pixel. This creates the horizontal 3×3 window that required for convolution processing. The write pointer `wrPntr` increments whenever a new pixel is written into memory, and the read pointer `rdPntr` increments whenever data is read. Both pointers wrap around to zero when they reach pixel index 1279, enabling continuous circular buffering for streaming image processing. Both are synchornices to `clk`. This mechanism supports uninterrupted real-time operation. The reset signal `rst` is synchornices to `clk`, when `rst = '1'`, `wrPntr` and `rdPntr` set to '0'.

#### 2. Control.v

The Control module is the main controller of the Sobel FPGA architecture. It manages the image-stream flow between the DMA interface, the line buffers, and the convolution module. The controller is responsible for:

 - Writing incoming pixels into line buffers.
 - Reading neighboring rows for convolution.
 - Generating the 3×3 Sobel window.
 - Synchronizing streaming operation.
 - Managing frame processing.
 - Generating AXI-style handshake signals.
 - Detecting the last pixel in the frame.
 - Handling image boundary conditions using zero padding.

**Inputs**
 - `clk` — Main system clock controlling all synchronous operations.
 - `rst` — Global reset signal used to initialize counters, FSM states, and synchronization logic.
 - `data_valid_in` — Indicates valid incoming pixel data from DMA.
 - `data_in[7:0]` — Incoming grayscale pixel stream.
 - `valid_after_conv` — Indicates valid processed output from convolution module.
 - `ready_from_DMA` — Handshake signal indicating downstream DMA can accept data.

**Outputs**
 - `data_valid_to_conv` — Indicates valid 3×3 convolution window output.
 - `data_out[71:0]` — Complete 3×3 pixel window sent to convolution engine.
 - `last_bit` — Indicates last processed pixel in frame.
 - `ready_to_DMA` — Indicates controller can accept more incoming pixels.
   
**Module Operation:**




#### 3. Conv.v

This module receives 3 rows of 3 neighboring pixels (72-bit) and performs convolution between the pixels and the X-kernel and Y-kernel of the Sobel filter, calculates the gradient magnitude of the two convolution results and compares the result to a threshold value to determine if the detected edge is significant.

**Compute Gradients (Gx and Gy):**

For each pixel in the 3×3 window:
 - The pixel value is extracted from `pixel_data_in`.
 - The extracted pixel is multiplied by the corresponding Sobel kernel coefficient.
 - The results are stored in `mul_Data_x` (for `Gx`) and `mul_Data_y` (for `Gy`).
 - After multiplication, the `mul_Valid` signal is set to indicate that multiplication is complete.

**Sum the Gradient Components:**

The results stored in `mul_Data_x` and `mul_Data_y` are summed separately to get:
 - `sum_Data_x`: Total weighted sum in the X direction.
 - `sum_Data_y`: Total weighted sum in the Y direction.
 - The `sum_Valid` signal is updated to indicate that summation is complete.

**Compute Gradient Magnitude:**

The summed gradient values are squared:
 - `Gx_sqr` = `sum_Data_x` * `sum_Data_x`.
 - `Gy_sqr` = `sum_Data_y` * `sum_Data_y`.
 - `Gt` = `Gx_sqr` + `Gy_sqr`.
 - The `conv_data_temp_valid` signal is updated to indicate that summation is complete.

**Thresholding and Output Assignment:**

 - If the total gradient (`Gt`) exceeds the squared threshold, the output pixel is classified as an edge (`0xFF`).
 - Otherwise, it is classified as non-edge (`0x00`).
 - `conv_data_valid_out` is updated to indicate that the output is valid.

**Summary:**

1. Extract the 9 pixels from the 3×3 window.
2. Multiply them with the Sobel filters (`Gx` and `Gy`).
3. Sum the weighted values to compute gradient components.
4. Square and sum `Gx` and `Gy` to compute gradient magnitude.
5. Compare against the threshold to classify as edge (`0xFF`) or non-edge (`0x00`).
6. This module enables real-time edge detection in FPGA-based image processing pipelines.

#### 4. Top_AXIS.v

This module is a high-level integration of a data processing pipeline that takes in streaming 8-bit pixel data, processes it, and outputs the transformed data.

---

## Simulation

This Verilog testbench (`Top_TB`) is designed to simulate and verify the behavior of a module named Top.

1. #### Sets up signals that connect to the Top module:

 - Inputs like clock (`Clk`), input validity (`Valid_in`), data to be sent (`Data_in`), and a signal that mimics readiness of a DMA engine (`Ready_from_dma`).
 - Outputs like processed data (`Data_out`), its validity (`Valid_out`), end-of-packet indicator (`Last_out`), and a signal that tells whether the downstream IP is ready (`Ready_from_IP`).

2. #### Creates a clock
 - 100 MHz clock (`Clk`).

3. Starts with all input signals inactive to ensure a clean initial state.

4. #### Begins sending data after 10 nanoseconds:

 - It sets `Valid_in` to 1, meaning that sending data valid now.
 - Sends the byte `00000001` repeatedly as the input.
 - Sets `Ready_from_dma` to 1, telling the module that the upstream (DMA) is ready to send data.

5. Waits for 9.216 ms, which corresponds to the time it would take to send a full HD image (1280×720 pixels), assuming 1 pixel is sent every 10 ns.

6. #### After sending the image:

 - It stops sending (`Valid_in` = 0)
 - Then disables DMA readiness.
 - Finally, stops the simulation.

<p align="center">
  <img src="https://github.com/user-attachments/assets/a26e2bb3-3bb8-42df-93a7-05299f657de3" width="800">
</p>
<p align="center">2. The beginning of the process </p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/20117a52-b86d-42ce-850b-7b812c0d30c9" width="800">
</p>
<p align="center">3. The ending of the process </p>

---

### IP creation

After writing the RTL code, it is packed into an IP to be used later in building a system by blocks designing in Vivado.

**Packaging process:**

<p align="center">
  <img src="https://github.com/user-attachments/assets/901cb2f6-118a-42c0-a8cf-f2c118863a62" width="600">
</p>
<p align="center">4. Package IP</p>

1. Creating master and slave interfaces for AXI4 stream protocol and port mapping the appropriate signals.

**MASTER:**

<p align="center">
  <img src="https://github.com/user-attachments/assets/1ad32281-874a-44a5-8cb2-478bb085724e" width="600">
</p>
<p align="center">5. Master interface signals</p>


**SLAVE:**

<p align="center">
  <img src="https://github.com/user-attachments/assets/6be9315d-6a7d-48d1-a04e-5f4d63ca38d1" width="600">
</p>
<p align="center">6. Slave interface signals</p>


2.	Adding the master and slave signals to the BUS.

3.	Review and package.

<p align="center">
  <img src="https://github.com/user-attachments/assets/2c7da8eb-610c-4d85-8569-9b542b832b6f" width="600">
</p>
<p align="center">7. Review and package the IP</p>

---

### Sobel filter system

This project features an image processing system that integrates a hardware Sobel filter IP, AXI Direct Memory Access (DMA), AXI GPIO, and a processor. It is developed using PYNQ on the AMD (Xilinx) Zynq 7020 SoC, which combines an FPGA and an ARM processor. The system is designed in Vivado using a block-based approach, incorporating all necessary IPs.

**1.	Processing system:**

<p align="center">
  <img src="https://github.com/user-attachments/assets/858d96d8-40f7-4a9f-ae63-9bfb6f799727" width="400">
</p>
<p align="center">8. PS IP</p>

The Zynq-7000 Processing System (PS) combines a dual-core ARM Cortex-A9 processor with programmable logic (FPGA) to create a highly flexible and powerful platform for a wide range of applications, from embedded systems to complex signal processing. The PS including DDR3/DDR2 SDRAM memory interface for high-speed data storage. The communication between the PS and FPGA is done through a AXI communication protocol.

**2. AXI DMA:**

<p align="center">
  <img src="https://github.com/user-attachments/assets/b4cd7e68-5810-4290-9253-53bb39aa42c0" width="400">
</p>
<p align="center">9. AXI DMA IP</p>

The AXI Direct Memory Access IP core is for optimizing data transfer in systems using the AXI protocol. The AXI DMA can perform transfers between memory locations (memory-to-memory) or between peripherals and memory (peripheral-to-memory), offering versatility in data handling. The DMA in this project moving pixel data between memory to the Sobel IP and from the Sobel IP to memory.

**3. AXI GPIO:**

<p align="center">
  <img src="https://github.com/user-attachments/assets/db1838e7-4ff4-4176-bfc2-5f4f33405632" width="400">
</p>
<p align="center">10. AXI GPIO IP</p>

The AXI GPIO (General Purpose Input/Output) IP core is a versatile component in the architecture that provides a simple way to interface with general-purpose I/O pins on FPGA devices. The IP provides simple register access for reading the state of input pins or writing to output pins, making it easy to control the FPGA hardware. The GPIO in this project allows to set the threshold value.

**4. Sobel filter IP:**

<p align="center">
  <img src="https://github.com/user-attachments/assets/b1ebf941-03a3-4ef2-9bf8-aacd0207cdf2" width="400">
</p>
<p align="center">11. Sobel filter IP</p>

This IP doing hardware processing of a Sobel filter on 1280x720 image for edge detection. 

**Connection between the IPs:**

 - The PS is master to DMA and GPIO for control.
 - The DMA is mater to DDR by using HP0 and HP1 interfaces in the PS.
 - The Sobel filter is slave to DMA in the read image process and master to DMA in the write image process.
 - All IPs get 100MHz clock signal, and reset signal from PS.

<p align="center">
  <img src="https://github.com/user-attachments/assets/a59a6ec4-1ff7-432d-adf0-1537c5ca8371" width="900">
</p>
<p align="center">12. Sobel filter system</p>

When the system is ready the block design translated to RTL code by the software and ready to synthesis and implementation to generate Bitstream.

---

### Sobel filter operation

This project utilizes an SD card with an Ubuntu-based Linux operating system, preloaded with Python drivers and libraries specifically designed for the PYNQ-Z2 development board.
The code is written in Jupyter Notebook, a browser-based development environment that supports live coding, visualization, and the use of open-source libraries.

**Project Directory: "Sobel Filter System"**

The directory contains the following key files:

 - Sobel_V.bit – The FPGA bitstream file implementing the Sobel filter system.
 - Sobel_V.tcl – A script for automating design setup in Vivado.
 - Sobel_V.hwh – The hardware handoff file describing the FPGA design.
 - Example images – Sample images for processing.
 - Python code – The main script for executing the Sobel filter operation.

**Python Code Overview**

1. Import Libraries – Loads required libraries for image processing.
2. Load Bitstream – Implements the Sobel filter system in the FPGA.
3. Define DMA and AXI GPIO –
 - DMA (Direct Memory Access) handles data transfer.
 - AXI GPIO is used to apply the threshold value.
4. Image Preprocessing –
 - Reads an image.
 - Converts it to grayscale.
 - Resizes it to 1280x720.
 - Saves the resized image.
 - Sets up memory buffers for processing.
5. Processing with Sobel Filter –
 - Resets the DMA.
 - Sends the image to the Sobel filter IP.
 - Waits for processing completion.
 - Saves the processed image.
 - Deletes memory buffers to free resources.

This workflow enables efficient hardware-accelerated edge detection using the FPGA-based Sobel filter.

**results** 

Image1:

<p align="center">
  <img src="https://github.com/user-attachments/assets/1d951a61-4c06-47dc-b909-710bd73d1984" width="800">
</p>
<p align="center">13. Image 1</p>

Image1 after process with threshold = 90:

<p align="center">
  <img src="https://github.com/user-attachments/assets/bae37540-41fb-48cc-85c8-00c3b2af13b9" width="800">
</p>
<p align="center">14. Image 1 after sobel filter with threshold = 90</p>

Image1 after process with threshold = 150:

<p align="center">
  <img src="https://github.com/user-attachments/assets/b6e44384-8612-464e-9b23-049790cae1be" width="800">
</p>
<p align="center">15. Image 1 after sobel filter with threshold = 150</p>


Image2:

<p align="center">
  <img src="https://github.com/user-attachments/assets/3b273740-d6b1-44c4-be4c-8668a457f2fc" width="800">
</p>
<p align="center">16. Image 2</p>

Image2 after process with threshold = 90:

<p align="center">
  <img src="https://github.com/user-attachments/assets/a8c18ffe-c710-40e7-b8d8-af96db8f8228" width="800">
</p>
<p align="center">17. Image 2 after sobel filter with threshold = 90</p>

Image2 after process with threshold = 150:

<p align="center">
  <img src="https://github.com/user-attachments/assets/bb182088-c895-4bbc-b02c-447ff5ae7c5f" width="800">
</p>
<p align="center">18. Image 2 after sobel filter with threshold = 150</p>

---

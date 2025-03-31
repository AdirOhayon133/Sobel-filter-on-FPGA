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

![image](https://github.com/user-attachments/assets/9d9b3c3c-2056-482d-a68e-aded1098abed)

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
The IP contain 4 components under Top.v that suitable for AXI4 Stream protocol.

### Verilog code explain 

#### 1. Line_Buffer.v

The Line_Buffer module in Verilog is a simple memory buffer designed to store a sequence of 8-bit values (pixel data length). It maintains a line buffer with a total length of 1280 bytes (width of an image).
The output is vector of 24-bit, three neighboring pixels.
The Line_Buffer module is synchronous to the rising edge of the clock signal (`Clk`).

 - The module uses an internal memory array `line_B` that can hold 1280 bytes.
 - A write pointer `wrPntr` keeps track of where new data is written.
 - A read pointer `rdPntr` keeps track of which data is being read.

**Writing Data:**

 - When the `data_valid_in` signal is high, new data (`data_in`) is written to the location indexed by `wrPntr`.
 - The `wrPntr` increments after every write operation.
 - If `wrPntr` reaches the end of the buffer (index 1279), it wraps around to 0.

**Reading Data:**

The module outputs 3 consecutive bytes from the buffer, starting at the location indexed by `rdPntr`.
This is useful in image processing where three consecutive pixels may be needed at once.
When `rd_data_in` is high, `rdPntr` increments to move to the next set of pixels.
Like the write pointer, `rdPntr` wraps around when reaching the end of the buffer.

**Reset Behavior:**

If `rst` is high, both the `wrPntr` and `rdPntr` are reset to 0, clearing the buffer state.

**Summary:**

This module is useful in edge detection application when multiple pixels from a single line are required at a time. The Line Buffer efficiently manages this by providing three adjacent pixels for processing.

#### 2. control.v

The control module manages the buffering and transfer of pixel data using four instances of the Line_Buffer module. This module coordinates writing and reading of pixel data while ensuring proper sequencing of buffered lines.
It then outputs a 72-bit concatenation of pixel values from three consecutive buffers.
The control module is synchronous to the rising edge of the clock signal (`Clk`).

**Writing Data to Line Buffers:**

**Key Writing Logic**
 - If `pixel_data_valid_in` is high, data is written to the selected buffer.
 - When `wr_pixel_c` reaches 1280, it resets to 0, and `wr_buffer` moves to the next buffer.
 - The total written pixels (`total_wr_pixel`) counter keeps track of the total data stored.

**Process**
 - Incoming pixel data (`pixel_data_in`) is written to one of the four Line Buffers (`lB0` to `lB3`).
 - The write pointer (`wr_pixel_c`) tracks where data is being written in the buffer.
 - After 1280 pixels (one full image width), writing switches to the next buffer (`wr_buffer` increments).
 - `wr_en_lb` determines which buffer is currently receiving data:
    - `wr_buffer` = 0 → Write to `lB0`
    - `wr_buffer` = 1 → Write to `lB1`
    - `wr_buffer` = 2 → Write to `lB2`
    - `wr_buffer` = 3 → Write to `lB3`

**Reading Data from Line Buffers:**

**Key Reading Logic**
 - Reading is enabled only when `dma_ready_in` is high (ensuring the receiver is ready).
 - `rd_pixel_c` increments after each read.
 - When `rd_pixel_c` reaches 1280, it resets, and `rd_buffer` moves to the next set of three buffers.

**Process**
 - Output pixels are generated by reading from three adjacent line buffers.
 - The read pointer (`rd_pixel_c`) tracks the current read position.
 - Once 3 rows of the image has been written (`total_wr_pixel` > 3840), reading starts (`rd_en` is enabled).
 - Data is read in overlapping rows, cycling through the buffers:
   - `rd_buffer` = 0 → `{lB2, lB1, lB0}`
   - `rd_buffer` = 1 → `{lB3, lB2, lB1}`
   - `rd_buffer` = 2 → `{lB0, lB3, lB2}`
   - `rd_buffer` = 3 → `{lB1, lB0, lB3}`
 - The output concatenates 3 consecutive pixel values, forming a 72-bit output (`pixel_data_out`).


**Synchronization and Control:**

 - Reading starts only when sufficient data has been written (`total_wr_pixel` > 3840).
 - Reading stops when all required pixels are read (`total_rd_pixel` < 921599).
 - `rd_en_lb` determines which buffers are being read based on `rd_buffer`.

**Summary:**

The module buffers pixel data line by line.
It reads and outputs three lines at a time to form a 72-bit pixel window.
It cycles through four buffers to maintain continuous data flow.

#### 3. conv.v

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

#### 4. stream.v

This module implements a streamlined data processor. Since the convolution process takes multiple clock cycles to generate an output data stream, this component is designed for buffering and seamless compatibility with the AXI4-Stream interface.

**Data Capture & Transfer:**

 - When `Valid_in` is asserted, the `Data_in` value is stored in `Temp_Data`.
 - `Rd_en` (read enable) is set high to indicate data capture.
 - The stored data is assigned to `Data_out`, and `Valid_out` is asserted.

**End of Stream Indication:**

 - `Last_out` is asserted when `Rd_count` reaches 921599, indicating the last data in the sequence.
 - After reaching 921600, `Last_out` is de-asserted.

**Ready Signal:**

 - The module remains ready to receive new data until `Rd_count` reaches 921600.
 - Once 921600 is reached, `Ready_from_IP` is de-asserted, preventing further data intake.

**Summary:**

1. This module buffering between the convolution process to streaming out the data.
2. This module is adapted to the AXI4-Stream interface with valid, ready, data and t_last signals.

#### 5. Top.v

This module is a high-level integration of a data processing pipeline that takes in streaming 8-bit pixel data, processes it, and outputs the transformed data.

---

### IP creation

After writing the RTL code, it is packed into an IP to be used later in building a system by blocks designing in Vivado.

**Packaging process:**

![image](https://github.com/user-attachments/assets/901cb2f6-118a-42c0-a8cf-f2c118863a62)

1. Creating master and slave interfaces for AXI4 stream protocol and port mapping the appropriate signals.

**MASTER:**

![image](https://github.com/user-attachments/assets/57a4092c-85ea-4896-94f2-cb757c0550c3)

**SLAVE:**

![image](https://github.com/user-attachments/assets/6be9315d-6a7d-48d1-a04e-5f4d63ca38d1)


2.	Adding the master and slave signals to the BUS.

3.	Review and package.
   
![image](https://github.com/user-attachments/assets/2c7da8eb-610c-4d85-8569-9b542b832b6f)

---

### Sobel filter system

This project features an image processing system that integrates a hardware Sobel filter IP, AXI Direct Memory Access (DMA), AXI GPIO, and a processor. It is developed using PYNQ on the AMD (Xilinx) Zynq 7020 SoC, which combines an FPGA and an ARM processor. The system is designed in Vivado using a block-based approach, incorporating all necessary IPs.

**1.	Processing system:**

![image](https://github.com/user-attachments/assets/858d96d8-40f7-4a9f-ae63-9bfb6f799727)

The Zynq-7000 Processing System (PS) combines a dual-core ARM Cortex-A9 processor with programmable logic (FPGA) to create a highly flexible and powerful platform for a wide range of applications, from embedded systems to complex signal processing. The PS including DDR3/DDR2 SDRAM memory interface for high-speed data storage. The communication between the PS and FPGA is done through a AXI communication protocol.

**2. AXI DMA:**

![image](https://github.com/user-attachments/assets/b4cd7e68-5810-4290-9253-53bb39aa42c0)

The AXI Direct Memory Access IP core is for optimizing data transfer in systems using the AXI protocol. The AXI DMA can perform transfers between memory locations (memory-to-memory) or between peripherals and memory (peripheral-to-memory), offering versatility in data handling. The DMA in this project moving pixel data between memory to the Sobel IP and from the Sobel IP to memory.

**3. AXI GPIO:**

![image](https://github.com/user-attachments/assets/db1838e7-4ff4-4176-bfc2-5f4f33405632)

The AXI GPIO (General Purpose Input/Output) IP core is a versatile component in the architecture that provides a simple way to interface with general-purpose I/O pins on FPGA devices. The IP provides simple register access for reading the state of input pins or writing to output pins, making it easy to control the FPGA hardware. The GPIO in this project allows to set the threshold value.

**4. Sobel filter IP:**

![image](https://github.com/user-attachments/assets/b1ebf941-03a3-4ef2-9bf8-aacd0207cdf2)

This IP doing hardware processing of a Sobel filter on 1280x720 image for edge detection. 

**Connection between the IPs:**

 - The PS is master to DMA and GPIO for control.
 - The DMA is mater to DDR by using HP0 and HP1 interfaces in the PS.
 - The Sobel filter is slave to DMA in the read image process and master to DMA in the write image process.
 - All IPs get 100MHz clock signal, and reset signal from PS.

![image](https://github.com/user-attachments/assets/a59a6ec4-1ff7-432d-adf0-1537c5ca8371)

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

![Ronaldo](https://github.com/user-attachments/assets/1d951a61-4c06-47dc-b909-710bd73d1984)

Image1 after process with threshold = 90:

![Ronaldo_edges(th=90)](https://github.com/user-attachments/assets/bae37540-41fb-48cc-85c8-00c3b2af13b9)


Image1 after process with threshold = 150:

![Ronaldo_edges(th=150)](https://github.com/user-attachments/assets/b6e44384-8612-464e-9b23-049790cae1be)

Image2:

![Carry](https://github.com/user-attachments/assets/3b273740-d6b1-44c4-be4c-8668a457f2fc)

Image2 after process with threshold = 90:

![Carry_edges(th=90)](https://github.com/user-attachments/assets/a8c18ffe-c710-40e7-b8d8-af96db8f8228)

Image2 after process with threshold = 150:

![Carry_edges(th=150)](https://github.com/user-attachments/assets/bb182088-c895-4bbc-b02c-447ff5ae7c5f)


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




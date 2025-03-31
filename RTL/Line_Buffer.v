`timescale 1ns / 1ps

module Line_Buffer (

input  Clk,
input  rst,
input  data_valid_in,
input  rd_data_in,
input  [7:0] data_in,
output  [23:0] data_out

);

// Declare internal signals
reg [7:0] line_B [1279:0];   
reg [10:0] wrPntr = 11'd0;    
reg [10:0] rdPntr = 11'd0;    

 
// Generate data_out based on read pointer
assign data_out = {line_B[rdPntr], line_B[rdPntr+1], line_B[rdPntr+2]};  // Concatenate 3 consecutive bytes
    
// Write data to the line buffer when data_valid_in is high
always @(posedge Clk) begin
if (data_valid_in) begin
line_B[wrPntr] <= data_in;  // Write data to the line buffer
end
end

// Increment write pointer
always @(posedge Clk) begin
if (rst) begin
wrPntr <= 11'd0;
end
else if (data_valid_in) begin
if (wrPntr == 11'd1279) begin
wrPntr <= 11'd0;  // Wrap around if the write pointer reaches the maximum value
end else begin
wrPntr <= wrPntr + 1;  // Increment write pointer
end
end
end

// Increment read pointer
always @(posedge Clk) begin
if (rst) begin
rdPntr <= 11'd0;
end
else if (rd_data_in) begin
if (rdPntr == 11'd1279) begin
rdPntr <= 11'd0;  // Wrap around if the read pointer reaches the maximum value
end else begin
rdPntr <= rdPntr + 1;  // Increment read pointer
end
end
end

endmodule

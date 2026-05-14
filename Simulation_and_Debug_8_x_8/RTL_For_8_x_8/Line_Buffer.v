`timescale 1ns / 1ps

module Line_Buffer (

input  clk,
input  rst,
input  wr_in,
input  rd_in,
input  [7:0] data_in,
output [23:0] data_out

);

reg [7:0] line_B [9:0];   
reg [2:0] wrPntr = 3'd0;    
reg [2:0] rdPntr = 3'd0;

initial begin
line_B [0] = 8'b00000000;  
line_B [9] = 8'b00000000;  
end

assign data_out = {line_B[rdPntr], line_B[rdPntr+1], line_B[rdPntr+2]}; 
    
always @(posedge clk) begin
if (wr_in) begin
line_B[wrPntr+1] <= data_in;  
end
end

always @(posedge clk) begin
if (rst) begin
wrPntr <= 3'd0;
end
else if (wr_in) begin
if (wrPntr == 3'd7) begin
wrPntr <= 3'd0;  
end else begin
wrPntr <= wrPntr + 1;  
end
end
end

always @(posedge clk) begin
if (rst) begin
rdPntr <= 3'd0;
end
else if (rd_in) begin
if (rdPntr == 3'd7) begin
rdPntr <= 3'd0;  
end else begin
rdPntr <= rdPntr + 1;  
end
end
end

endmodule
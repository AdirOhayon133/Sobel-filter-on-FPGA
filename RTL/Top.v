`timescale 1ns / 1ps

module Top(

input Clk,
input rst,
input [7:0] Threshhold_in,
input Valid_in,
input [7:0] Data_in,
input Ready_from_dma,
output  Valid_out,
output  [7:0] Data_out,
output  Last_out,
output  Ready_from_IP

    );
 
wire rst_high ;   
wire [71:0] pixel_data ;
wire pixel_data_valid ;
wire [7:0] conv_data ;
wire conv_data_valid ;

assign rst_high = !rst;

control control1 (
.Clk(Clk),
.rst(rst_high),
.pixel_data_valid_in(Valid_in),
.pixel_data_in(Data_in),
.pixel_data_out(pixel_data),
.pixel_data_valid_out( pixel_data_valid),
.dma_ready_in(Ready_from_dma)
    );   
 
conv conv1 (
.Clk(Clk),
.Threshhold_in(Threshhold_in),
.pixel_data_valid_in(pixel_data_valid),
.pixel_data_in(pixel_data),
.conv_data_out(conv_data),
.conv_data_valid_out(conv_data_valid)
    );  
    
 stream stream1 (
 .Clk(Clk),
 .rst(rst_high),
 .Valid_in(conv_data_valid),
 .Data_in(conv_data),
 .Valid_out(Valid_out),
 .Data_out(Data_out),
 .Last_out(Last_out),
 .Ready_from_IP(Ready_from_IP) 
    );   
    
endmodule

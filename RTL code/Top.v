`timescale 1ns / 1ps

module Top(

input Clk,
input Valid_in,
input [7:0] Data_in,
input Ready_from_dma,
output  Valid_out,
output  [7:0] Data_out,
output  Last_out,
output  Ready_from_IP

    );
    
wire [71:0] pixel_data ;
wire pixel_data_valid ;

assign Ready_from_IP = pixel_data_valid;

control control1 (
.Clk(Clk),
.pixel_data_valid_in(Valid_in),
.pixel_data_in(Data_in),
.pixel_data_out(pixel_data),
.pixel_data_valid_out( pixel_data_valid),
.T_last(Last_out),
.dma_ready_in(Ready_from_dma)
    );
    
conv conv1 (
.i_clk(Clk),
.i_pixel_data_valid(pixel_data_valid),
.i_pixel_data(pixel_data),
.o_convolved_data(Data_out),
.o_convolved_data_valid(Valid_out)
    );
    
    
endmodule

`timescale 1ns / 1ps

module Top_AXIS(

input  clk,
input  n_rst,
input [7:0] Threshhold_in,
input  T_Valid_in,
input  [7:0] T_Data_in,
input  T_Ready_in,
output T_Valid_out,
output [7:0] T_Data_out,
output  T_Last_out,
output  T_Ready_out

    );

wire rst = !n_rst;
wire data_valid_to_conv;
wire [71:0]data_to_conv;
wire valid_after_conv;

assign T_Valid_out = valid_after_conv;

Control Control1 (
.clk(clk),
.rst(rst),
.data_valid_in(T_Valid_in),
.data_in(T_Data_in),
.valid_after_conv(valid_after_conv),
.data_valid_to_conv(data_valid_to_conv),
.ready_from_DMA(T_Ready_in),
.data_out(data_to_conv),
.last_bit(T_Last_out),
.ready_to_DMA(T_Ready_out)
);    
    
Conv Conv1 (
.clk(clk),
.Threshhold_in(Threshhold_in),
.data_in(data_to_conv),
.data_valid_in(data_valid_to_conv),
.conv_data_out(T_Data_out),
.conv_data_valid_out(valid_after_conv)
);   
        
endmodule


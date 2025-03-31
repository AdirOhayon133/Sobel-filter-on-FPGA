`timescale 1ns / 1ps

module conv(
input Clk,
input [7:0] Threshhold_in,       
input [71:0] pixel_data_in,
input pixel_data_valid_in,
output reg [7:0] conv_data_out,
output reg  conv_data_valid_out
    );
    
integer i; 
reg [7:0] Gx [8:0];
reg [7:0] Gy [8:0];
reg [10:0] mul_Data_x[8:0];
reg [10:0] mul_Data_y[8:0];
reg [10:0] sum_Data_temp_x;
reg [10:0] sum_Data_temp_y;
reg [10:0] sum_Data_x;
reg [10:0] sum_Data_y;
reg mul_Valid;
reg sum_Valid;
reg [20:0] Gx_sqr;
reg [20:0] Gy_sqr;
wire [21:0] Gt;
reg conv_data_temp_valid;

initial
begin
Gx[0] =  1; Gx[1] =  0; Gx[2] = -1;
Gx[3] =  2; Gx[4] =  0; Gx[5] = -2;
Gx[6] =  1; Gx[7] =  0; Gx[8] = -1;  
 
Gy[0] =  1; Gy[1] =  2; Gy[2] = 1;
Gy[3] =  0; Gy[4] =  0; Gy[5] = 0;
Gy[6] =  -1; Gy[7] =  -2; Gy[8] = -1;   
end    
    
always @(posedge Clk)
begin
for(i=0;i<9;i=i+1)
begin
mul_Data_x[i] <= $signed(Gx[i])*$signed({1'b0,pixel_data_in[i*8+:8]});
mul_Data_y[i] <= $signed(Gy[i])*$signed({1'b0,pixel_data_in[i*8+:8]});
end
mul_Valid <= pixel_data_valid_in;
end

always @(*)
begin
sum_Data_temp_x = 0;
sum_Data_temp_y = 0;
for(i=0;i<9;i=i+1)
begin
sum_Data_temp_x = $signed(sum_Data_temp_x) + $signed(mul_Data_x[i]);
sum_Data_temp_y = $signed(sum_Data_temp_y) + $signed(mul_Data_y[i]);
end
end

always @(posedge Clk)
begin
sum_Data_x <= sum_Data_temp_x;
sum_Data_y <= sum_Data_temp_y;
sum_Valid <= mul_Valid;
end

always @(posedge Clk)
begin
Gx_sqr <= $signed(sum_Data_x)*$signed(sum_Data_x);
Gy_sqr <= $signed(sum_Data_y)*$signed(sum_Data_y);
conv_data_temp_valid <= sum_Valid;
end

assign Gt = Gx_sqr + Gy_sqr;
   
always @(posedge Clk)
begin
if(Gt > ($signed(Threshhold_in)*$signed(Threshhold_in)))
conv_data_out <= 8'hff;
else
conv_data_out <= 8'h00;
conv_data_valid_out <= conv_data_temp_valid;
end
    
endmodule

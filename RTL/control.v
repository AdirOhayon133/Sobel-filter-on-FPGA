`timescale 1ns / 1ps

module Control(

input  clk,
input  rst,
input  data_valid_in,
input  [7:0] data_in,
input  valid_after_conv,
input  ready_from_DMA,
output data_valid_to_conv,
output reg [71:0] data_out,
output reg last_bit,
output reg ready_to_DMA

    );
    
reg [10:0] wr_pixel_c = 11'd0;
reg [3:0] wr_en_lb = 4'b0000;
reg [1:0] wr_buffer = 2'b00;
reg [19:0] total_wr_pixel = 20'd0;
reg wr_en = 1'b0 ;
reg rd_en = 1'b0 ;
reg [9:0] line_c = 10'd0;
reg [10:0] rd_pixel_c = 11'd0;
reg [3:0] rd_en_lb = 4'b0000;
reg [1:0] rd_buffer = 2'b00;
reg [19:0] total_rd_pixel = 20'd0;
reg [19:0] total_rd_pixel_after_cov = 20'd0;
wire [23:0] lb0_data, lb1_data, lb2_data, lb3_data;    

localparam  Idle = 2'b00, 
Write = 2'b01,
Write_Read = 2'b10, 
Read = 2'b11; 
reg [2:0] present_state, next_state;

always @(posedge clk)
begin
if(rst==1) 
present_state <= Idle;
else
present_state <= next_state; 
end 

always @(*)
begin
case(present_state) 
Idle:begin
wr_en = 1'b0 ;
rd_en = 1'b0 ;
if(data_valid_in) begin
next_state = Write;
wr_en = 1'b1 ;
end
else
next_state = Idle;
end
Write:begin
wr_en = 1'b1 ;
rd_en = 1'b0 ;
if(total_wr_pixel == 20'd2560)begin
next_state = Write_Read;
rd_en = 1'b1;
end
else
next_state = Write;
end
Write_Read:begin
wr_en = 1'b1 ;
rd_en = 1'b1 ;
if(total_wr_pixel == 20'd921599) begin
next_state = Read;
end
else
next_state = Write_Read;
end
Read:begin
wr_en = 1'b0 ;
rd_en = 1'b1 ;
if(total_rd_pixel == 20'd921599) begin
next_state = Idle;
end
else
next_state = Read;
end
endcase
end
   
Line_Buffer lB0 (
.clk(clk),
.rst(rst),
.data_in(data_in),
.wr_in(wr_en_lb[0]),
.data_out(lb0_data),
.rd_in(rd_en_lb[0])
    );

Line_Buffer lB1 (
.clk(clk),
.rst(rst),
.data_in(data_in),
.wr_in(wr_en_lb[1]),
.data_out(lb1_data),
.rd_in(rd_en_lb[1])
    );

Line_Buffer lB2 (
.clk(clk),
.rst(rst),
.data_in(data_in),
.wr_in(wr_en_lb[2]),
.data_out(lb2_data),
 .rd_in(rd_en_lb[2])
    );

Line_Buffer lB3 (
.clk(clk),
.rst(rst),
.data_in(data_in),
.wr_in(wr_en_lb[3]),
.data_out(lb3_data),
.rd_in(rd_en_lb[3])
    ); 
 
assign data_valid_to_conv = rd_en && ready_from_DMA;   

always @(posedge clk) begin
if (rst) begin
wr_pixel_c <= 11'd0;
wr_buffer <= 2'b00;
end
else if (wr_en) begin
if (wr_pixel_c == 11'd1279) begin
wr_buffer <= wr_buffer +1;
wr_pixel_c <= 11'd0;
end
else begin
wr_pixel_c <= wr_pixel_c + 1;
end
end
end  
  
always @(posedge clk) begin
if (rst) begin
total_wr_pixel <= 20'd0;
end
else if (wr_en) begin
if (total_wr_pixel == 20'd921599) begin 
total_wr_pixel <= 20'd0;
end
else
total_wr_pixel <= total_wr_pixel +1;
end
end 

always @(*) begin
if (wr_en) begin
case (wr_buffer)
0: begin 
wr_en_lb = 4'b0001;
end
1: begin 
wr_en_lb = 4'b0010;
end   
2: begin 
wr_en_lb = 4'b0100;
end   
3: begin 
wr_en_lb = 4'b1000;
end  
endcase
end
else begin
wr_en_lb = 4'b0000;
end
end  
  
always @(posedge clk) begin
if (rst) begin
rd_pixel_c <= 11'd0;
rd_buffer <= 2'b00;
line_c <= 10'd0;
end
else if (rd_en && ready_from_DMA) begin
if (rd_pixel_c == 11'd1279) begin
rd_buffer <= rd_buffer +1;
rd_pixel_c <= 11'd0;
if (line_c == 10'd719) begin
line_c <= 10'd0;
end
else begin
line_c <= line_c +1;
end
end
else begin
rd_pixel_c <= rd_pixel_c + 1;
end
end
end 

always @(posedge clk) begin
if (rst) begin
total_rd_pixel <= 20'd0;
end
else if (rd_en && ready_from_DMA) begin
if (total_rd_pixel == 20'd921599) begin
total_rd_pixel <= 20'd0;
end
else begin
total_rd_pixel <= total_rd_pixel +1;
end
end  
end

always @(*) begin
if (rd_en && ready_from_DMA) begin
case (rd_buffer)
0: begin 
rd_en_lb = 4'b1011;
end
1: begin 
rd_en_lb = 4'b0111;
end   
2: begin 
rd_en_lb = 4'b1110;
end   
3: begin 
rd_en_lb = 4'b1101;
end  
endcase
end
else begin
rd_en_lb = 4'b0000;
end
end

always @(*)
begin
if(line_c== 10'd0) begin
data_out = {lb1_data,lb0_data,24'd0};
end
else if (line_c == 10'd719) begin
case(rd_buffer)
0:begin
data_out = {24'd0,lb0_data,lb3_data};
end
1:begin
data_out = {24'd0,lb1_data,lb0_data};
end
2:begin
data_out = {24'd0,lb2_data,lb1_data};
end
3:begin
data_out = {24'd0,lb3_data,lb2_data};
end
endcase
end
else begin
case(rd_buffer)
0:begin
data_out = {lb1_data,lb0_data,lb3_data};
end
1:begin
data_out = {lb2_data,lb1_data,lb0_data};
end
2:begin
data_out = {lb3_data,lb2_data,lb1_data};
end
3:begin
data_out = {lb0_data,lb3_data,lb2_data};
end
endcase
end
end

always @(posedge clk) begin
if (total_wr_pixel == 20'd921599) begin
ready_to_DMA <= 1'b0;
end
else begin
ready_to_DMA <= 1'b1;
end
end

always @(posedge clk) begin
if (rst) begin
total_rd_pixel_after_cov <= 20'd0;
end
else if (total_rd_pixel_after_cov == 20'd921599) begin
total_rd_pixel_after_cov <= 20'd0;
end
else if (valid_after_conv) begin
total_rd_pixel_after_cov <= total_rd_pixel_after_cov +1;
end
end  

always @(*) begin
if (total_rd_pixel_after_cov == 20'd921599) begin
last_bit <= 1'b1;
end
else begin
last_bit <= 1'b0;
end
end

endmodule
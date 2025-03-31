`timescale 1ns / 1ps


module control(

input  Clk,
input  pixel_data_valid_in,
input dma_ready_in,
output pixel_data_valid_out,
output reg T_last = 1'b0,
input  [7:0] pixel_data_in,
output reg [71:0] pixel_data_out

    );
    
// Declare internal signals
reg [8:0] wr_pixel_c = 9'd0;
reg [3:0] wr_en_lb = 4'b0000;
reg [1:0] wr_buffer = 2'b00;
reg [18:0] total_wr_pixel = 19'd0;
reg rd_en = 1'b0 ;
reg [8:0] rd_pixel_c = 9'd0;
reg [3:0] rd_en_lb = 4'b0000;
reg [1:0] rd_buffer = 2'b00;
reg [18:0] total_rd_pixel = 19'd0;
wire [23:0] lb0_data, lb1_data, lb2_data, lb3_data;    
    
Line_Buffer lB0 (
.Clk(Clk),
.data_in(pixel_data_in),
.data_valid_in(wr_en_lb[0]),
.data_out(lb0_data),
.rd_data_in(rd_en_lb[0])
    );

Line_Buffer lB1 (
.Clk(Clk),
.data_in(pixel_data_in),
.data_valid_in(wr_en_lb[1]),
.data_out(lb1_data),
.rd_data_in(rd_en_lb[1])
    );

Line_Buffer lB2 (
.Clk(Clk),
.data_in(pixel_data_in),
.data_valid_in(wr_en_lb[2]),
.data_out(lb2_data),
 .rd_data_in(rd_en_lb[2])
    );

Line_Buffer lB3 (
.Clk(Clk),
.data_in(pixel_data_in),
.data_valid_in(wr_en_lb[3]),
.data_out(lb3_data),
.rd_data_in(rd_en_lb[3])
    ); 
    
assign pixel_data_valid_out = rd_en;    
    
always @(posedge Clk) begin
if (pixel_data_valid_in) begin
if (wr_pixel_c == 9'd511) begin
wr_buffer <= wr_buffer +1;
wr_pixel_c <= 9'd0;
end
else begin
wr_pixel_c <= wr_pixel_c + 1;
end
end
end

always @(posedge Clk) begin
if (pixel_data_valid_in) begin
total_wr_pixel <= total_wr_pixel +1;
end
end

always @(posedge Clk) begin
if (total_wr_pixel > 1535 && total_rd_pixel < 262143) begin
rd_en <= 1'b1;
end
else 
rd_en <= 1'b0;
end

always @(posedge Clk) begin
if (total_rd_pixel == 262142) begin
T_last <= 1'b1;
end
else 
T_last <= 1'b0;
end

always @(*) begin
if (pixel_data_valid_in) begin
case (wr_buffer)
0: begin 
wr_en_lb <= 4'b0001;
end
1: begin 
wr_en_lb <= 4'b0010;
end   
2: begin 
wr_en_lb <= 4'b0100;
end   
3: begin 
wr_en_lb <= 4'b1000;
end  
endcase
end
else begin
wr_en_lb <= 4'b0000;
end
end
    
always @(posedge Clk) begin
if (rd_en && dma_ready_in) begin
if (rd_pixel_c == 9'd511) begin
rd_buffer <= rd_buffer +1;
rd_pixel_c <= 9'd0;
end
else begin
rd_pixel_c <= rd_pixel_c + 1;
end
end
end

always @(posedge Clk) begin
if (rd_en && dma_ready_in) begin
total_rd_pixel <= total_rd_pixel +1;
end
end

always @(*) begin
if (rd_en) begin
case (rd_buffer)
0: begin 
rd_en_lb <= 4'b0111;
end
1: begin 
rd_en_lb <= 4'b1110;
end   
2: begin 
rd_en_lb <= 4'b1101;
end   
3: begin 
rd_en_lb <= 4'b1011;
end  
endcase
end
else begin
rd_en_lb <= 4'b0000;
end
end

always @(*)
begin
case(rd_buffer)
0:begin
pixel_data_out = {lb2_data,lb1_data,lb0_data};
end
1:begin
pixel_data_out = {lb3_data,lb2_data,lb1_data};
end
2:begin
pixel_data_out = {lb0_data,lb3_data,lb2_data};
end
3:begin
pixel_data_out = {lb1_data,lb0_data,lb3_data};
end
endcase
end


endmodule

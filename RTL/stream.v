`timescale 1ns / 1ps

module stream(
input Clk,
input rst,
input Valid_in,
input [7:0] Data_in,
output reg Valid_out,
output reg [7:0] Data_out,
output reg Last_out,
output reg Ready_from_IP

    );
    
reg Rd_en = 1'b0; 
reg [19:0] Rd_count = 20'd0;   
reg [7:0] Temp_Data;  
    
always@(posedge Clk) begin
if (rst) begin
Rd_en <= 1'b0;
end
else if (Valid_in) begin
Temp_Data <= Data_in;
Rd_en <= 1'b1;
end
else begin
Rd_en <= 1'b0;
end
end

always@(posedge Clk) begin
if (rst) begin
Valid_out <= 1'b0;
end
else if (Rd_en) begin
Data_out <= Temp_Data; 
Valid_out <= 1'b1;
end
else begin
Valid_out <= 1'b0;
end    
end

always@(posedge Clk) begin
if (rst) begin
Rd_count <= 20'd0;
end
else if (Rd_count == 921600) begin
Rd_count <= 20'd0;
end
else if (Rd_en) begin
Rd_count <= Rd_count +1;
end  
end


always@(posedge Clk) begin
if (rst) begin
Last_out <= 1'b0;
end
else if (Rd_count == 921599) begin   
Last_out <= 1'b1;
end
else begin
Last_out <= 1'b0;  
end 
end

always@(posedge Clk) begin
if (Rd_count < 921600) begin   
Ready_from_IP <= 1'b1; 
end
else begin
Ready_from_IP <= 1'b0; 
end 
end 
 
endmodule




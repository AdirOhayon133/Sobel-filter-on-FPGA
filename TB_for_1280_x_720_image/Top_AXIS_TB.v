`timescale 1ns / 1ps

module Top_AXIS_TB;

parameter WIDTH  = 1280;
parameter HEIGHT = 720;
parameter FRAME_SIZE = WIDTH * HEIGHT; 

reg clk;
reg n_rst;
reg [7:0] Threshhold_in;
reg        T_Valid_in;
reg [7:0]  T_Data_in;
reg        T_Ready_in;
wire       T_Valid_out;
wire [7:0] T_Data_out;
wire       T_Last_out;
wire       T_Ready_out;

reg [7:0] image_mem [0:FRAME_SIZE-1];

integer infile;
integer outfile;

integer r;
integer i;

integer out_pixel_count;

Top_AXIS DUT (
    .clk(clk),
    .n_rst(n_rst),
    .Threshhold_in(Threshhold_in),

    .T_Valid_in(T_Valid_in),
    .T_Data_in(T_Data_in),
    .T_Ready_in(T_Ready_in),

    .T_Valid_out(T_Valid_out),
    .T_Data_out(T_Data_out),
    .T_Last_out(T_Last_out),
    .T_Ready_out(T_Ready_out)
);

initial begin
clk = 1'b0;
forever #5 clk = ~clk; 
end

initial begin
infile = $fopen("Ronaldo_1280x720_bin.txt","r");
if(infile == 0) begin
$display("ERROR: Cannot open input image file");
$finish;
end

for(i=0; i<FRAME_SIZE; i=i+1) begin
r = $fscanf(infile,"%b\n",image_mem[i]);
end

$fclose(infile);

$display("IMAGE LOADED");
end

initial begin

n_rst = 1'b0;
T_Valid_in = 1'b0;
T_Data_in  = 8'd0;
T_Ready_in = 1'b1;
Threshhold_in = 8'd90;

#100;

n_rst = 1'b1;

end

initial begin

wait(n_rst);

@(posedge clk);

$display("START SENDING IMAGE");

for(i=0; i<FRAME_SIZE; i=i+1) begin

@(posedge clk);

while(T_Ready_out == 1'b0) begin
@(posedge clk);
end

T_Valid_in <= 1'b1;
T_Data_in  <= image_mem[i];

end

@(posedge clk);

T_Valid_in <= 1'b0;
T_Data_in  <= 8'd0;

$display("IMAGE SEND DONE");

end

initial begin

outfile = $fopen("Ronaldo_Output_1280x720_bin_th=90.txt","w");

if(outfile == 0) begin
$display("ERROR: Cannot open output file");
$finish;
end

out_pixel_count = 0;
wait(n_rst);

forever begin

@(posedge clk);
if(T_Valid_out) begin

$fwrite(outfile,"%08b\n",T_Data_out);
out_pixel_count = out_pixel_count + 1;
end

if(T_Last_out) begin

$display("FRAME DONE");
$display("OUTPUT PIXELS = %d", out_pixel_count);

$fclose(outfile);

#1000;

$finish;
end
end
end

endmodule
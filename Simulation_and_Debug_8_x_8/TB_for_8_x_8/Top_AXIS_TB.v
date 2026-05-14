`timescale 1ns / 1ps

module Top_AXIS_TB;

parameter WIDTH      = 8;
parameter HEIGHT     = 8;
parameter FRAME_SIZE = WIDTH * HEIGHT;

reg clk;
reg n_rst;
reg T_Valid_in;
reg [7:0] T_Data_in;
reg T_Ready_in;
reg [7:0] Threshhold_in;
wire T_Valid_out;
wire [7:0] T_Data_out;
wire T_Last_out;
wire T_Ready_out;

Top_AXIS dut (
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
clk = 0;
forever #5 clk = ~clk;
end

reg [7:0] image_mem [0:FRAME_SIZE-1];
integer infile, outfile;
integer i, r;
integer out_pixel_count = 0;

initial begin
infile = $fopen("8_x_8_txt.txt", "r");
if (infile == 0) begin
$display("ERROR: Cannot open 8_on_8_txt.txt");
$finish;
end

for (i = 0; i < FRAME_SIZE; i = i + 1) begin
r = $fscanf(infile, "%b\n", image_mem[i]);
end
$fclose(infile);
$display("SUCCESS: Input image loaded.");
end

always @(posedge clk) begin
if (T_Valid_out && T_Ready_in) begin
$fwrite(outfile, "%b\n", T_Data_out);
out_pixel_count = out_pixel_count + 1;

$display("Captured Pixel #%0d: Value = %b", out_pixel_count, T_Data_out);
if (out_pixel_count == FRAME_SIZE) begin
$display("=== SUCCESS: Captured all 64 pixels ===");
$fclose(outfile);
#50;
$finish;
end
end
end

initial begin
n_rst = 0;
T_Valid_in = 0;
T_Data_in  = 0;
T_Ready_in = 1;
Threshhold_in = 8'd90; 

#100;
n_rst = 1;

outfile = $fopen("Result.txt", "w");
if (outfile == 0) begin
$display("ERROR: Cannot create Result.txt");
$finish;
end

$display("=== STARTING DATA STREAM ===");

i = 0;
while (i < FRAME_SIZE) begin
@(posedge clk);
if (T_Ready_out) begin
T_Valid_in <= 1;
T_Data_in  <= image_mem[i];
i = i + 1;
end else begin
T_Valid_in <= 1;
end
end

@(posedge clk);
T_Valid_in <= 0;
$display("=== ALL INPUT DATA SENT ===");

#2000;
$display("ERROR: Simulation timed out. Only received %0d pixels.", out_pixel_count);
$fclose(outfile);
$finish;
end

endmodule
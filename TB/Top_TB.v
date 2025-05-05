`timescale 1ns / 1ps

module Top_TB;

// Declare signals to connect to the Top module
reg Clk;
reg Valid_in;
reg [7:0] Data_in;
reg Ready_from_dma;
wire Valid_out;
wire [7:0] Data_out;
wire Last_out;
wire Ready_from_IP;
    
 // Instantiate the Top module
Top CH1 (
.Clk(Clk),
.Valid_in(Valid_in),
.Data_in(Data_in),
.Ready_from_dma(Ready_from_dma),
.Valid_out(Valid_out),
.Data_out(Data_out),
.Last_out(Last_out),
.Ready_from_IP(Ready_from_IP)
    );

// Generate clock signal with 10ns period (100MHz clock)
always begin
Clk = 0; #5 Clk = 1; #5;
end
    
// Testbench stimulus
initial begin
// Initialize inputs
Valid_in = 0;
Data_in = 8'b00000000;
Ready_from_dma = 0;
            
// Send first Imaget to the IP
#10;

Valid_in = 1;
Data_in = 8'b00000001; // input data
Ready_from_dma = 1; // DMA is ready
#9216000; // The sendind time for HD image (720*1280*10ns)
Valid_in = 0;
#100000;
Ready_from_dma = 0;

#10
$stop; // Stop simulation to check the waveforms
end
   
endmodule
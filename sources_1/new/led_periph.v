`timescale 1ns / 1ps

module led_periph(
    input clk,
    input we,              // write enable
    input [31:0] addr,
    input [31:0] wdata,
    
    output reg [15:0] led
);

always @(posedge clk) begin
    if (we && addr == 10'h100) begin
        led <= wdata[15:0];
    end
end

endmodule
`timescale 1ns / 1ps

// Switch Peripheral (read-only)
// Read addr 0x10C:
//   rdata[15:0] = sw[15:0]
module sw_periph(
    input  [15:0] sw,

    output [31:0] rdata
);

assign rdata = {16'd0, sw};

endmodule

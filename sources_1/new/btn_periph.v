`timescale 1ns / 1ps

// Button Peripheral (read-only)
// Read addr 0x108:
//   rdata[4:0] = {btnD, btnR, btnL, btnU, btnC}
module btn_periph(
    input  btnC,
    input  btnU,
    input  btnL,
    input  btnR,
    input  btnD,

    output [31:0] rdata
);

assign rdata = {27'd0, btnD, btnR, btnL, btnU, btnC};

endmodule

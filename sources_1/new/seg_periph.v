`timescale 1ns / 1ps

// 7-Segment Display Peripheral
// Write addr 0x104:
//   wdata[6:0]  = seg[6:0]  (active low: a,b,c,d,e,f,g)
//   wdata[7]    = dp        (decimal point, active low)
//   wdata[11:8] = an[3:0]   (digit select, active low)
module seg_periph(
    input         clk,
    input         we,
    input  [9:0]  addr,
    input  [31:0] wdata,

    output reg [6:0] seg,
    output wire      dp,
    output reg [3:0] an
);

    reg [15:0] seg_data = 16'h0000;
    reg [16:0] refresh_cnt = 17'd0;
    reg [1:0]  scan_sel = 2'd0;
    reg [3:0]  hex_digit;

    assign dp = 1'b1;   // decimal point OFF (active-low)

    always @(posedge clk) begin
        if (we && (addr == 10'h104))
            seg_data <= wdata[15:0];
    end

    always @(posedge clk) begin
        refresh_cnt <= refresh_cnt + 1'b1;
        scan_sel <= refresh_cnt[16:15];
    end

    always @(*) begin
        case (scan_sel)
            2'b00: begin
                an = 4'b1110;
                hex_digit = seg_data[3:0];
            end
            2'b01: begin
                an = 4'b1101;
                hex_digit = seg_data[7:4];
            end
            2'b10: begin
                an = 4'b1011;
                hex_digit = seg_data[11:8];
            end
            default: begin
                an = 4'b0111;
                hex_digit = seg_data[15:12];
            end
        endcase
    end

    always @(*) begin
        case (hex_digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
//            4'hA: seg = 7'b0001000;
//            4'hB: seg = 7'b0000011;
//            4'hC: seg = 7'b1000110;
//            4'hD: seg = 7'b0100001;
//            4'hE: seg = 7'b0000110;
//            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end

endmodule
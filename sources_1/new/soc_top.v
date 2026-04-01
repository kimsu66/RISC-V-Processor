module soc_top(
    input clk,

    // LED
    output [15:0] led,

    // 7-Segment
    output [6:0]  seg,
    output        dp,
    output [3:0]  an,

    // Buttons (read by CPU)
    input  btnC,
    input  btnU,
    input  btnL,
    input  btnR,
    input  btnD,

    // Switches (read by CPU)
    input  [15:0] sw
);

    wire [9:0]  pc;
    wire [31:0] i_instr;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] rdata;

    wire [9:0]  data_addr;
    wire        data_cen;
    wire        data_wen;
    wire [31:0] wdata;
    wire        reg_wen;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [4:0]  rd;
    wire [31:0] rd_data;

    wire [31:0] mem_rdata;
    wire [31:0] btn_rdata;
    wire [31:0] sw_rdata;

    // =========================
    // Address Decode
    // CPU signals: cen=0 active, wen=0 write
    // =========================
    wire led_sel = (data_addr == 10'h100);
    wire seg_sel = (data_addr == 10'h104);
    wire btn_sel = (data_addr == 10'h108);
    wire sw_sel  = (data_addr == 10'h10C);
    wire periph_sel = led_sel | seg_sel | btn_sel | sw_sel;

    wire bus_active = (data_cen == 1'b0);
    wire bus_write  = (data_wen == 1'b0);

    wire led_we = bus_active && bus_write && led_sel;
    wire seg_we = bus_active && bus_write && seg_sel;

    // rdata mux: peripheral reads take priority over memory
    assign rdata = (bus_active && !bus_write && btn_sel) ? btn_rdata :
                   (bus_active && !bus_write && sw_sel)  ? sw_rdata  :
                   mem_rdata;

    // =========================
    // CPU
    // =========================
    riscv_cpu CPU (
        .clk(clk),
        .reset_n(1'b1),
        .i_instr(i_instr),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rdata(rdata),

        .pc(pc),
        .data_addr(data_addr),
        .data_cen(data_cen),
        .data_wen(data_wen),
        .wdata(wdata),
        .reg_wen(reg_wen),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .rd_data(rd_data)
    );

    // =========================
    // Instruction Memory
    // =========================
    mem_instr MEM_INSTR (
        .addr(pc),
        .instr(i_instr)
    );

    // =========================
    // Register File
    // =========================
    regfile REGFILE (
        .clk(clk),
        .reg_wen(reg_wen),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // =========================
    // Data Memory (blocked for peripheral addresses)
    // =========================
    mem_data MEM_DATA (
        .clk(clk),
        .cen(data_cen),
        .wen(periph_sel ? 1'b1 : data_wen),
        .addr(data_addr),
        .wdata(wdata),
        .rdata(mem_rdata)
    );

    // =========================
    // LED Peripheral
    // =========================
    led_periph LED (
        .clk(clk),
        .we(led_we),
        .addr(data_addr),
        .wdata(wdata),
        .led(led)
    );

    // =========================
    // 7-Segment Peripheral
    // =========================
    seg_periph SEG (
        .clk(clk),
        .we(seg_we),
        .addr(data_addr),
        .wdata(wdata),
        .seg(seg),
        .dp(dp),
        .an(an)
    );

    // =========================
    // Button Peripheral
    // =========================
    btn_periph BTN (
        .btnC(btnC),
        .btnU(btnU),
        .btnL(btnL),
        .btnR(btnR),
        .btnD(btnD),
        .rdata(btn_rdata)
    );

    // =========================
    // Switch Peripheral
    // =========================
    sw_periph SW (
        .sw(sw),
        .rdata(sw_rdata)
    );

endmodule

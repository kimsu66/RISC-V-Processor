module riscv_cpu
(
    input               clk,        // clock input
    input               reset_n,    // active-low reset
    input       [31:0]  i_instr,    // 32-bit instruction input
    input       [31:0]  rs1_data,   // 32-bit rs1 data input
    input       [31:0]  rs2_data,   // 32-bit rs2 data input
    input       [31:0]  rdata,      // 32-bit read data input from data memory

    output reg  [9:0]   pc,         // 10-bit program counter output
    output      [9:0]   data_addr,  // 10-bit data memory address output
    output              data_cen,   // data memory chip enable output (active low assumed)
    output              data_wen,   // data memory write enable output (active low assumed)
    output      [31:0]  wdata,      // 32-bit writing data output to data memory
    output              reg_wen,    // regfile write enable output
    output      [4:0]   rs1,        // 5-bit rs1 output
    output      [4:0]   rs2,        // 5-bit rs2 output
    output      [4:0]   rd,         // 5-bit rd output
    output      [31:0]  rd_data     // 32-bit rd data output
);

    wire    [31:0]  instr;
    wire    [6:0]   opcode;
    wire    [6:0]   funct7;
    wire    [2:0]   funct3;

    wire            alu_src;

    wire    [4:0]   alu_ctrl;
    wire    [31:0]  alu_a;
    wire    [31:0]  alu_b;
    reg     [31:0]  alu_res;

    wire    [11:0]  imm;
    wire    [31:0]  ext_imm;

    wire    [1:0]   select;     // 01: BEQ taken, 10: JAL

    //=========================================================
    //                  Instruction Fetch
    //=========================================================
    always @(posedge clk or negedge reset_n)
    begin
        if (!reset_n) begin
            pc <= 10'd0;
        end
        else if ((select == 2'b01) || (select == 2'b10)) begin
            pc <= pc + ext_imm[9:0];
        end
        else begin
            pc <= pc + 10'd4;
        end
    end

    //=========================================================
    //                  Instruction Decoder
    //=========================================================
    assign instr    = {i_instr[7:0], i_instr[15:8], i_instr[23:16], i_instr[31:24]};
    assign opcode   = instr[6:0];
    assign funct7   = instr[31:25];
    assign funct3   = instr[14:12];
    assign rs1      = instr[19:15];
    assign rs2      = instr[24:20];
    assign rd       = instr[11:7];

    assign rd_data  = (opcode == 7'b000_0011) ? rdata :       // LW
                      (opcode == 7'b110_1111) ? ({22'd0, pc} + 32'd4) : // JAL
                      alu_res;

    // ALU Decoder
    assign alu_ctrl = ((opcode == 7'b011_0011) && (funct7 == 7'b000_0000) && (funct3 == 3'b000)) ? 5'b0_0000 : // ADD
                      ((opcode == 7'b011_0011) && (funct7 == 7'b010_0000) && (funct3 == 3'b000)) ? 5'b0_0001 : // SUB
                      ((opcode == 7'b011_0011) && (funct7 == 7'b000_0000) && (funct3 == 3'b110)) ? 5'b0_0010 : // OR
                      ((opcode == 7'b011_0011) && (funct7 == 7'b000_0000) && (funct3 == 3'b111)) ? 5'b0_0011 : // AND
                      ((opcode == 7'b001_0011) && (funct3 == 3'b000))                                ? 5'b0_0000 : // ADDI
                      ((opcode == 7'b001_0011) && (funct3 == 3'b110))                                ? 5'b0_0010 : // ORI
                      ((opcode == 7'b001_0011) && (funct3 == 3'b111))                                ? 5'b0_0011 : // ANDI
                      ((opcode == 7'b000_0011) && (funct3 == 3'b010))                                ? 5'b0_0000 : // LW
                      ((opcode == 7'b010_0011) && (funct3 == 3'b010))                                ? 5'b0_0000 : // SW
                      ((opcode == 7'b110_0011) && (funct3 == 3'b000))                                ? 5'b0_0100 : // BEQ
                      ((opcode == 7'b110_1111))                                                       ? 5'b0_0101 : // JAL
                                                                                                        5'b0_0000;

    assign alu_a    = rs1_data;
    assign alu_b    = alu_src ? ext_imm : rs2_data;

    // Main Decoder
    assign alu_src  = ((opcode == 7'b011_0011) || (opcode == 7'b110_0011)) ? 1'b0 : 1'b1;
    assign reg_wen  = ((opcode == 7'b001_0011) ||  // I-type ALU
                       (opcode == 7'b000_0011) ||  // LW
                       (opcode == 7'b110_1111) ||  // JAL
                       (opcode == 7'b011_0011)) ? 1'b1 : 1'b0;

    assign data_cen = ((opcode == 7'b000_0011) || (opcode == 7'b010_0011)) ? 1'b0 : 1'b1;
    assign data_addr= ((opcode == 7'b000_0011) || (opcode == 7'b010_0011)) ? alu_res[9:0] : 10'd0;
    assign data_wen = (opcode == 7'b010_0011) ? 1'b0 : 1'b1;   // active low write enable assumed
    assign wdata    = (opcode == 7'b010_0011) ? rs2_data : 32'd0;

    // Sign Extension / Immediate Generation
    assign imm      = (opcode == 7'b010_0011) ? {instr[31:25], instr[11:7]} :              // S-type SW
                      (opcode == 7'b110_0011) ? {instr[31], instr[7], instr[30:25], instr[11:8]} : // B-type BEQ
                                                 instr[31:20];                               // I-type

    assign ext_imm  = (opcode == 7'b110_0011) ? {{19{imm[11]}}, imm, 1'b0} :               // B-type BEQ
                      (opcode == 7'b110_1111) ? {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0} : // J-type JAL
                      ((opcode == 7'b001_0011) ||                                             // I-type ALU
                       (opcode == 7'b000_0011) ||                                             // LW
                       (opcode == 7'b010_0011)) ? {{20{imm[11]}}, imm} :                     // I-type, S-type
                                                 32'd0;

    //=========================================================
    //                      Execution
    //=========================================================
    always @(*)
    begin
        case (alu_ctrl)
            5'b0_0000 : alu_res = alu_a + alu_b; // ADD, ADDI, LW, SW
            5'b0_0001 : alu_res = alu_a - alu_b; // SUB
            5'b0_0010 : alu_res = alu_a | alu_b; // OR, ORI
            5'b0_0011 : alu_res = alu_a & alu_b; // AND, ANDI
            5'b0_0100 : alu_res = alu_a - alu_b; // BEQ compare
            default   : alu_res = 32'd0;
        endcase
    end

    assign select = ((alu_ctrl == 5'b0_0100) && (alu_res == 32'd0)) ? 2'b01 : // BEQ taken
                    (opcode == 7'b110_1111)                      ? 2'b10 : // JAL
                                                                  2'b00;

endmodule
module mem_instr
(
	input		[ 9:0]	addr,			//10bit address input
	output		[31:0]	instr			//32bit instruction output
);

	reg			[31:0]	mem	[255:0];	//32bit * 256 reg array

	initial begin
    $readmemh("/home/lenovo/KSY_workspace/fpga/RISCV/RISCV.srcs/sim_1/new/periph_memfile.mem", mem);
    end

	assign	instr	=	mem[addr[9:2]];

endmodule
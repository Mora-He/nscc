//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2014 leishangwen@163.com                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////

`include "defines.v"

module MYmips(

	input	wire		                    clk,
	input    wire		                    rst,
	
	(*mark_debug = "TRUE"*)input wire[`RegBus]         rom_data_i,
	output wire[`RegBus]        rom_addr_o,
	output wire                 rom_ce_o,
	
  //data_ram
	(*mark_debug = "TRUE"*)input wire[`RegBus]         ram_data_i,
	(*mark_debug = "TRUE"*)output wire[`RegBus]        ram_addr_o,
	(*mark_debug = "TRUE"*)output wire[`RegBus]        ram_data_o,
	(*mark_debug = "TRUE"*)output wire                 ram_we_o,
	(*mark_debug = "TRUE"*)output wire[3:0]            ram_sel_o,
	(*mark_debug = "TRUE"*)output wire                 ram_ce_o
);

	(*mark_debug = "TRUE"*)wire[`InstAddrBus] pc;
	(*mark_debug = "TRUE"*)wire[`InstAddrBus] id_pc_i;
	(*mark_debug = "TRUE"*)wire[`InstBus] id_inst_i;
	
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_subop_o;
	(*mark_debug = "TRUE"*)wire[`RegBus] id_reg1_o;
	(*mark_debug = "TRUE"*)wire[`RegBus] id_reg2_o;
	(*mark_debug = "TRUE"*)wire id_reg_we_o;
	(*mark_debug = "TRUE"*)wire[`RegAddrBus] id_num_o;
	wire id_is_in_delayslot_o;
  wire[`RegBus] id_jump_next_addr_o;	
  wire[`RegBus] id_inst_o;

	wire[`AluOpBus] ex_aluop_i;
	wire[`AluSelBus] ex_subop_o;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_reg_we_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_is_in_delayslot_i;	
  wire[`RegBus] ex_jump_next_addr_o;	
  wire[`RegBus] ex_inst_i;

	
	(*mark_debug = "TRUE"*)wire ex_reg_we_o;
	(*mark_debug = "TRUE"*)wire[`RegAddrBus] ex_waddr_o;
	(*mark_debug = "TRUE"*)wire[`RegBus] ex_wdata_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	wire ex_whilo_o;
	wire[`AluOpBus] ex_aluop_o;
	wire[`RegBus] ex_mem_addr_o;
//	wire[`RegBus] ex_reg1_o;
	wire[`RegBus] ex_reg2_o;	


	wire mem_reg_we_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	wire mem_whilo_i;		
	wire[`AluOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg1_i;
	wire[`RegBus] mem_reg2_i;		

	(*mark_debug = "TRUE"*)wire mem_reg_we_o;
	(*mark_debug = "TRUE"*)wire[`RegAddrBus] mem_waddr_o;
	(*mark_debug = "TRUE"*)wire[`RegBus] mem_wdata_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_whilo_o;	

	wire wb_reg_we_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;
	wire wb_whilo_i;	

  (*mark_debug = "TRUE"*)wire id_reg1_rd_en_o;
  (*mark_debug = "TRUE"*)wire id_reg2_rd_en_o;
  (*mark_debug = "TRUE"*)wire[`RegBus] reg1_data;
  (*mark_debug = "TRUE"*)wire[`RegBus] reg2_data;
  (*mark_debug = "TRUE"*)wire[`RegAddrBus] reg1_addr;
  (*mark_debug = "TRUE"*)wire[`RegAddrBus] reg2_addr;

	wire[`RegBus] 	hi;
	wire[`RegBus]   lo;

	wire is_in_delayslot_i;
	wire is_in_delayslot_o;
	wire next_inst_in_delayslot_o;
	(*mark_debug = "TRUE"*)wire id_branch_flag_o;
	(*mark_debug = "TRUE"*)wire[`RegBus] branch_target_address;

	(*mark_debug = "TRUE"*)wire[5:0] stall;
	  (*mark_debug = "TRUE"*)wire stallreq_from_id;	
	  (*mark_debug = "TRUE"*)wire stallreq_from_ex;

  	(*mark_debug = "TRUE"*)wire stall_for_instram_ex;//base ·Ã´æ
  (*mark_debug = "TRUE"*)wire stall_for_instram_ex_mem;
  	
	wire[`InstAddrBus] pc_to_if;
	wire[`InstAddrBus] pc_to_ram;
	wire[`RegBus]  pc_if_inst_o;
	wire pc_stallreq;
	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),
		.stall_for_instram_ex(stall_for_instram_ex),
		.stall_for_instram_ex_mem(stall_for_instram_ex_mem),
		
		.branch_flag_i(id_branch_flag_o),
		.branch_target_address_i(branch_target_address),
		
		.pc_from_if(pc_to_if),		
		.pc(pc),
		.pc_to_ram(pc_to_ram),
		
		.stallreq(pc_stallreq),
		.inst_rom_ce(rom_ce_o)	
	);

	pc_if pc_if0(
       .clk(clk),
	   .rst(rst),
	   .stall(stall),
	   .pc_i(pc),
	   .inst_i(rom_data_i),
	   
       .inst_o(pc_if_inst_o),
       .pc_o(pc_to_if)
    );
	
	
  assign rom_addr_o = pc_to_ram;

	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		
        .branch_flag_i(id_branch_flag_o),

        .if_pc(pc_to_if),
//		.if_inst(pc_if_inst_o),
        .if_inst(rom_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)      	
	);
	
	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),

  	     .ex_aluop_i(ex_aluop_o),

		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),

		.ex_reg_we_i(ex_reg_we_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_waddr_i(ex_waddr_o),

		.mem_reg_we_i(mem_reg_we_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_waddr_i(mem_waddr_o),

	  .is_in_delayslot_i(is_in_delayslot_i),

		.reg1_rd_en_o(id_reg1_rd_en_o),
		.reg2_rd_en_o(id_reg2_rd_en_o), 	  
		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		.aluop_o(id_aluop_o),
		.sub_op_o(id_subop_o),
		.reg1_data_o(id_reg1_o),
		.reg2_data_o(id_reg2_o),
		.reg_num_o(id_num_o),
		.reg_we(id_reg_we_o),
		.inst_o(id_inst_o),

	 	.next_inst_in_delayslot_o(next_inst_in_delayslot_o),	
		.branch_flag_o(id_branch_flag_o),
		.branch_target_address_o(branch_target_address),   
		.jump_next_addr_o(id_jump_next_addr_o),
		
		.is_in_delayslot_o(id_is_in_delayslot_o),
		
		.stallreq(stallreq_from_id)		
	);

	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_reg_we_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (id_reg1_rd_en_o),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (id_reg2_rd_en_o),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);

	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),

		.id_aluop(id_aluop_o),
		.id_subop(id_subop_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_num_o),
		.id_reg_we(id_reg_we_o),
		.id_jump_next_addr(id_jump_next_addr_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),		
		.id_inst(id_inst_o),		

	
		.ex_aluop(ex_aluop_i),
		.ex_subop(ex_subop_o),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_reg_we(ex_reg_we_i),
		.ex_jump_next_addr(ex_jump_next_addr_o),
  	.ex_is_in_delayslot(ex_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i),
		.ex_inst(ex_inst_i)

	);		
	
	ex ex0(
		.rst(rst),
	
		.aluop_i(ex_aluop_i),
		.subop_i(ex_subop_o),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.reg_we_i(ex_reg_we_i),
		.hi_i(hi),
		.lo_i(lo),
		.inst_i(ex_inst_i),

	  .wb_hi_i(wb_hi_i),
	  .wb_lo_i(wb_lo_i),
	  .wb_whilo_i(wb_whilo_i),
	  .mem_hi_i(mem_hi_o),
	  .mem_lo_i(mem_lo_o),
	  .mem_whilo_i(mem_whilo_o),

	    .jump_next_address_i(ex_jump_next_addr_o),
		.is_in_delayslot_i(ex_is_in_delayslot_i),	  
	  
		.wd_o(ex_waddr_o),
		.reg_we_o(ex_reg_we_o),
		.wdata_o(ex_wdata_o),

		.hi_o(ex_hi_o),
		.lo_o(ex_lo_o),
		.whilo_o(ex_whilo_o),

		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),

		.stall_for_instram(stall_for_instram_ex),
		.stallreq(stallreq_from_ex)     				
		
	);

  ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
	  
	  .stall(stall),
	  
		.ex_wd(ex_waddr_o),
		.ex_reg_we(ex_reg_we_o),
		.ex_wdata(ex_wdata_o),
		.ex_hi(ex_hi_o),
		.ex_lo(ex_lo_o),
		.ex_whilo(ex_whilo_o),		

  	     .ex_aluop(ex_aluop_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),			
		.mem_wd(mem_wd_i),
		.mem_reg_we(mem_reg_we_i),
		.mem_wdata(mem_wdata_i),
		.mem_hi(mem_hi_i),
		.mem_lo(mem_lo_i),
		.mem_whilo(mem_whilo_i),
	
  	     .mem_aluop(mem_aluop_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i),
		
		.stall_for_instram(stall_for_instram_ex_mem)			       	
	);
	
	mem mem0(
		.rst(rst),
	
		.wd_i(mem_wd_i),
		.reg_we_i(mem_reg_we_i),
		.wdata_i(mem_wdata_i),
		.hi_i(mem_hi_i),
		.lo_i(mem_lo_i),
		.whilo_i(mem_whilo_i),		

  	    .aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
	
		.mem_data_i(ram_data_i),

		.wd_o(mem_waddr_o),
		.reg_we_o(mem_reg_we_o),
		.wdata_o(mem_wdata_o),
		.hi_o(mem_hi_o),
		.lo_o(mem_lo_o),
		.whilo_o(mem_whilo_o),
		
		.mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o)
	);

	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),

    .stall(stall),

		.mem_wd(mem_waddr_o),
		.mem_reg_we(mem_reg_we_o),
		.mem_wdata(mem_wdata_o),
		.mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),
		.mem_whilo(mem_whilo_o),		
	
		.wb_wd(wb_wd_i),
		.wb_reg_we(wb_reg_we_i),
		.wb_wdata(wb_wdata_i),
		.wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i)
	);

	hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
	
		.we(wb_whilo_i),
		.hi_i(wb_hi_i),
		.lo_i(wb_lo_i),
		.hi_o(hi),
		.lo_o(lo)	
	);
	
	ctrl ctrl0(
		.rst(rst),
		
		.pc_stallreq(pc_stallreq),
		.stallreq_from_id(stallreq_from_id),
	
		.stallreq_from_ex(stallreq_from_ex),
		.stall_for_instram_ex(stall_for_instram_ex),
        .stall_for_instram_ex_mem(stall_for_instram_ex_mem),
		
		.stall(stall)       	
	);




	
endmodule
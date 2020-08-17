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

`include "defines.v"

module id_ex(

	input	wire				clk,
	input wire					rst,

	input wire[5:0]				 stall,
	
	input wire[`AluOpBus]         id_aluop,
	input wire[`AluSelBus]        id_subop,
	input wire[`RegBus]           id_reg1,
	input wire[`RegBus]           id_reg2,
	input wire[`RegAddrBus]       id_wd,
	input wire                    id_reg_we,
	input wire[`RegBus]           id_jump_next_addr,
	input wire                    id_is_in_delayslot,
	input wire                    next_inst_in_delayslot_i,		
	input wire[`RegBus]           id_inst,		

	output reg[`AluOpBus]         ex_aluop,
	output reg[`AluSelBus]        ex_subop,
	output reg[`RegBus]           ex_reg1,
	output reg[`RegBus]           ex_reg2,
	output reg[`RegAddrBus]       ex_wd,
	output reg                    ex_reg_we,
	output reg[`RegBus]           ex_jump_next_addr,
    output reg                    ex_is_in_delayslot,
	output reg                    is_in_delayslot_o,
	output reg[`RegBus]           ex_inst
);

	always @ (posedge clk) begin
			ex_aluop <=(rst == `RstEnable)            ? `EXE_NOP_OP:
		      		   (stall[3:2] == 2'b01)          ?`EXE_NOP_OP:
		      		   ~stall[2]                      ?id_aluop:ex_aluop;

			ex_subop <= (rst == `RstEnable)           ? `EXE_RES_NOP:
		      		   (stall[3:2] == 2'b01)          ?`EXE_RES_NOP:
		      		   ~stall[2]                      ?id_subop:ex_subop;

			ex_reg1 <= (rst == `RstEnable)            ? `ZeroWord:
		      		   (stall[3:2] == 2'b01)          ?`ZeroWord:
		      		   ~stall[2]                      ?id_reg1:ex_reg1;

			ex_reg2 <= (rst == `RstEnable)            ? `ZeroWord:
		      		   (stall[3:2] == 2'b01)          ?`ZeroWord:
		      		   ~stall[2]                      ?id_reg2:ex_reg2;

			ex_wd <= (rst == `RstEnable)        	  ? `NOPRegAddr:
		      		   (stall[3:2] == 2'b01)          ?`NOPRegAddr:
		      		   ~stall[2]                      ?id_wd:ex_wd;

			ex_reg_we <=(rst == `RstEnable)           ? `WriteDisable:
		      		   (stall[3:2] == 2'b01)          ?`WriteDisable:
		      		   ~stall[2]                      ?id_reg_we:ex_reg_we;

			ex_jump_next_addr <= (rst == `RstEnable)  ? `ZeroWord:
		      		   (stall[3:2] == 2'b01)          ?`ZeroWord:
		      		   ~stall[2]                      ?id_jump_next_addr:ex_jump_next_addr;

			ex_is_in_delayslot <= (rst == `RstEnable) ? `NotInDelaySlot:
		      		   (stall[3:2] == 2'b01)          ?`NotInDelaySlot:
		      		   ~stall[2]                      ?id_is_in_delayslot:ex_is_in_delayslot;

	    	is_in_delayslot_o <= (rst == `RstEnable)   ? `NotInDelaySlot:
		      		   (stall[3:2] == 2'b01)          ?`NotInDelaySlot:
		      		   ~stall[2]                      ?next_inst_in_delayslot_i:is_in_delayslot_o;

			ex_inst <=   (rst == `RstEnable)          ? `ZeroWord:
		      		   (stall[3:2] == 2'b01)          ?`ZeroWord:
		      		   ~stall[2]                      ?id_inst:ex_inst;
    	end
endmodule
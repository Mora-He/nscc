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

module ex_mem(

	input	wire					clk,
	input wire						rst,
	input wire[5:0]					stall,	

	input wire[`RegAddrBus]       ex_wd,
	input wire                    ex_reg_we,
	input wire[`RegBus]			   ex_wdata, 	
	input wire[`RegBus]           ex_hi,
	input wire[`RegBus]           ex_lo,
	input wire                    ex_whilo, 	

  input wire[`AluOpBus]          ex_aluop,
	input wire[`RegBus]          ex_mem_addr,
	input wire[`RegBus]          ex_reg2,
	
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_reg_we,
	output reg[`RegBus]			 mem_wdata,
	output reg[`RegBus]          mem_hi,
	output reg[`RegBus]          mem_lo,
	output reg                   mem_whilo,

    output reg[`AluOpBus]        mem_aluop,
	output reg[`RegBus]          mem_mem_addr,
	output reg[`RegBus]          mem_reg2,
	
	output wire                stall_for_instram//∑√¥Êbaseram–≈∫≈

);
    assign stall_for_instram = ~mem_mem_addr[22] && mem_mem_addr[31] &&(ex_aluop[7:5]==3'b111);

	always @ (posedge clk) begin
		     mem_wd <= (rst == `RstEnable)            ? `NOPRegAddr:
		      		   (stall[4:3] == 2'b01)          ?`NOPRegAddr:
		      		   ~stall[3]                      ?ex_wd:mem_wd;
		      		   
			 mem_reg_we <= (rst == `RstEnable)        ?`WriteDisable:
		      		   (stall[4:3] == 2'b01)          ?`WriteDisable:
		      		   ~stall[3]                      ?ex_reg_we: mem_reg_we;
		      		   
		      mem_wdata <=(rst == `RstEnable)         ?`ZeroWord:
		      		   (stall[4:3] == 2'b01)          ?`ZeroWord:
		      		   ~stall[3]                      ?ex_wdata: mem_wdata;
		      		   
		      mem_hi <= (rst == `RstEnable)           ?`ZeroWord:
		      		   (stall[4:3] == 2'b01)          ?`ZeroWord:
		      		   ~stall[3]                      ?ex_hi: mem_hi;
		      		   
		    mem_lo <= (rst == `RstEnable)             ?`ZeroWord:
		      		   (stall[4:3] == 2'b01)          ?`ZeroWord:
		      		   ~stall[3]                      ?ex_lo:mem_lo;
		      		   
		    mem_whilo <=(rst == `RstEnable)           ?`WriteDisable:
		      		   (stall[4:3] == 2'b01)          ?`WriteDisable:
		      		   ~stall[3]                      ?ex_whilo:mem_whilo;	
		      		   
  		    mem_aluop <= (rst == `RstEnable)          ?`EXE_NOP_OP:
		      		   (stall[4:3] == 2'b01)          ?`EXE_NOP_OP:
		      		   ~stall[3]                      ?ex_aluop: mem_aluop;
		      		   
			mem_mem_addr <=  (rst == `RstEnable)      ?`ZeroWord:
		      		   (stall[4:3] == 2'b01)          ?`ZeroWord:
		      		   ~stall[3]                      ?ex_mem_addr: mem_mem_addr;
		      		   
			mem_reg2 <=  (rst == `RstEnable)          ?`ZeroWord:
		      		   (stall[4:3] == 2'b01)          ?`ZeroWord:
		      		   ~stall[3]                      ?ex_reg2: mem_reg2;	
	end      //always
			
endmodule
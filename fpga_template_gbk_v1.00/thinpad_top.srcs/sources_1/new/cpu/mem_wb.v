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

module mem_wb(

	input	wire					clk,
	input wire						rst,

  //来自控制模块的信息
	input wire[5:0]               stall,	
	//来自访存阶段的信息	
	input wire[`RegAddrBus]       mem_wd,
	input wire                    mem_reg_we,
	input wire[`RegBus]			   mem_wdata,
	input wire[`RegBus]           mem_hi,
	input wire[`RegBus]           mem_lo,
	input wire                    mem_whilo,	

	//送到回写阶段的信息
	output reg[`RegAddrBus]      wb_wd,
	output reg                   wb_reg_we,
	output reg[`RegBus]			 wb_wdata,
	output reg[`RegBus]          wb_hi,
	output reg[`RegBus]          wb_lo,
	output reg                   wb_whilo
);


	always @ (posedge clk) begin
		 wb_wd <=      (rst == `RstEnable)            ? `NOPRegAddr:
		      		   (stall[5:4] == 2'b01)          ?`NOPRegAddr:
		      		   ~stall[4]                      ?mem_wd:wb_wd;
		      		   
		wb_reg_we <=   (rst == `RstEnable)            ?`WriteDisable:
		      		   (stall[5:4] == 2'b01)          ?`WriteDisable:
		      		   ~stall[4]                      ?mem_reg_we: wb_reg_we;
		      		   
		wb_wdata <=    (rst == `RstEnable)            ?`ZeroWord:
		      		   (stall[5:4] == 2'b01)          ?`ZeroWord:
		      		   ~stall[4]                      ?mem_wdata: wb_wdata;
		      		   
		wb_hi <=       (rst == `RstEnable)            ?`ZeroWord:
		      		   (stall[5:4] == 2'b01)          ?`ZeroWord:
		      		   ~stall[4]                      ?mem_hi: wb_hi;
		      		   
		wb_lo <=       (rst == `RstEnable)            ?`ZeroWord:
		      		   (stall[5:4] == 2'b01)          ?`ZeroWord:
		      		   ~stall[4]                      ?mem_lo:wb_lo;
		      		   
		wb_whilo <=    (rst == `RstEnable)            ?`WriteDisable:
		      		   (stall[5:4] == 2'b01)          ?`WriteDisable:
		      		   ~stall[4]                      ?mem_whilo:wb_whilo;	
	end      //always
			

endmodule
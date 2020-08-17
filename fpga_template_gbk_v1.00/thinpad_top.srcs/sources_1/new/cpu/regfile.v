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

module regfile(
	input	wire						clk,
	input wire							rst,
	//д�˿�
	input wire							we,
	input wire[`RegAddrBus]				waddr,
	input wire[`RegBus]					wdata,
	
	//���˿�1
	input wire					re1,
	input wire[`RegAddrBus]		raddr1,
	output reg[`RegBus]        rdata1,
	
	//���˿�2
	input wire					re2,
	input wire[`RegAddrBus]		raddr2,
	output reg[`RegBus]        rdata2
);

	reg[`RegBus]  regs[0:`RegNum-1];
always @ (posedge clk) begin
	regs[waddr] <=(!rst && we && (waddr != `RegNumLog2'h0))? wdata: regs[waddr];
end
	
always @ (*) begin
    rdata1<= rst                               ?`ZeroWord:
            (raddr1 == `RegNumLog2'h0)          ?`ZeroWord:
            ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable))   ?wdata:
            (re1 == `ReadEnable)                ?regs[raddr1]:`ZeroWord;
end

always @ (*) begin
     rdata2<= rst                               ?`ZeroWord:
            (raddr2 == `RegNumLog2'h0)          ?`ZeroWord:
            ((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable))   ?wdata:
            (re2 == `ReadEnable)                ?regs[raddr2]:`ZeroWord;
end
 
endmodule
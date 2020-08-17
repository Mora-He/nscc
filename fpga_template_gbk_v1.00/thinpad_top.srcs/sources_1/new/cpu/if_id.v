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

module if_id(

	input	wire					clk,
	input wire						rst,

    input wire                    branch_flag_i,
    
	input wire[5:0]               stall,	
	input wire[`InstAddrBus]	   if_pc,
	input wire[`InstBus]          if_inst,
	output reg[`InstAddrBus]      id_pc,
	output reg[`InstBus]          id_inst  
	
);  
always @ (posedge clk) begin
    id_pc <= (rst == `RstEnable)    ?32'h80000000:
            (stall[2:1] == 2'b01)   ?32'h80000000:
            ~stall[1]               ?if_pc:id_pc;
end

reg delay_flag;
always @ (posedge clk) begin
    id_inst <= (rst == `RstEnable)   ?`ZeroWord:
            (stall[2:1] == 2'b01)           ?`ZeroWord:
            delay_flag                      ?`ZeroWord://发出跳转信号的下下个clk清空多取的inst
                                                        //两个周期延时：delayflag一拍+id_inst一拍
            (~stall[1])                     ?if_inst:id_inst;
end

always@(posedge clk)begin
    delay_flag <= (rst == `RstEnable)   ?1'b0:
                    stall[1]            ?delay_flag://比暂停信号慢一拍的标志信号
                    branch_flag_i; 
end


endmodule
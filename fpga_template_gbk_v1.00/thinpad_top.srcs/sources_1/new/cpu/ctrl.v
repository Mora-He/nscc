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

module ctrl(
	input wire										rst,
	
	input wire                   pc_stallreq,
	
	input wire                   stallreq_from_id,
  //来自执行阶段的暂停请求
	input wire                   stallreq_from_ex,
    input wire                   stall_for_instram_ex,
    input wire                   stall_for_instram_ex_mem,
	(*mark_debug = "TRUE"*)output reg[5:0]              stall       
);

(*mark_debug = "TRUE"*)wire [3:0] stall_sign;
assign stall_sign={stallreq_from_id,stallreq_from_ex,stall_for_instram_ex,stall_for_instram_ex_mem};

always @ (*) begin
		if(rst == `RstEnable) begin
			stall <= 6'b000000;
		end else if(pc_stallreq)
		    stall <= 6'b000111;	//pc不变
		else begin//else 1
			case(stall_sign)
		      4'b0000:stall <= 6'b000000;                 //nostop
		      4'b0001:stall <= 6'b000111;	//pc不变      //stall_for_instram_ex_mem
		      4'b0010:stall <= 6'b000111;	//pc不变      //stall_for_instram_ex
		      4'b0011:stall <= 6'b000111;   //pc不变
		      4'b0100:stall <= 6'b001111;                 //stallreq_from_ex
		      4'b1000:stall <= 6'b000111;	              //stallreq_from_id
		      default:stall <= 6'b000111;                 //!!!default situation:stop from id
		  endcase
		 end   //else1
	end      //always
endmodule
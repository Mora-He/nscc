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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module hilo_reg(

	input	wire					clk,
	input wire						rst,
	
	//Ð´¶Ë¿Ú
	input wire						we,
	input wire[`RegBus]				hi_i,
	input wire[`RegBus]				lo_i,
	
	//¶Á¶Ë¿Ú1
	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o
	
);

	always @ (posedge clk) begin
		hi_o <=   rst     ? `ZeroWord:
		          we      ?  hi_i:
		          hi_o;
		lo_o <=   rst     ? `ZeroWord:
		          we      ?  lo_i:
		          lo_o;
	end

endmodule
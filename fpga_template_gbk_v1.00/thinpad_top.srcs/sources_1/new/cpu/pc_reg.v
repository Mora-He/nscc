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

module pc_reg(

	input	wire				  clk,
	input wire					  rst,
	
	input wire[5:0]               stall,
	input wire                    stall_for_instram_ex,
	input wire                    stall_for_instram_ex_mem,
	 
	input wire                    branch_flag_i,
	input wire[`RegBus]           branch_target_address_i,
	
	input wire[`InstAddrBus]	   pc_from_if,
	output reg[`InstAddrBus]	   pc,
	output wire[`InstAddrBus]	   pc_to_ram,
	
	output wire                   stallreq,
	output reg                    inst_rom_ce
	
);
    assign pc_to_ram=stall[0]?pc_from_if:pc;
    //<取值暂停信号>
    reg inst_ram_get_data_flag;
     always@(posedge clk)begin
        inst_ram_get_data_flag <= stall_for_instram_ex&&!stall_for_instram_ex_mem;
    end
     reg inst_ram_get_data_flag2;
     always@(posedge clk)begin
        inst_ram_get_data_flag2 <= inst_ram_get_data_flag;
    end
    assign stallreq = inst_ram_get_data_flag2;
   //</取值暂停信号>

    
	always @ (posedge clk) begin
        	pc <=  (inst_rom_ce== `ChipDisable)                ?32'h80000000:
		  	       (~stall[0]&&branch_flag_i)                  ? branch_target_address_i:
		  	       (stall_for_instram_ex&&!stall_for_instram_ex_mem)          ?pc:
		  	       (~stall[0])                                 ?pc + 4'h4:
		  	       pc;
	end

	always @ (posedge clk) begin
        inst_rom_ce <= (rst == `RstEnable)?`ChipDisable:`ChipEnable;
	end


endmodule
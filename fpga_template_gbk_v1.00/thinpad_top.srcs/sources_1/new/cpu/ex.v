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

module ex(

	input wire										rst,
	
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        subop_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    reg_we_i,
	input wire[`RegBus]           inst_i,

	
	input wire[`RegBus]           hi_i,
	input wire[`RegBus]           lo_i,

	input wire[`RegBus]           wb_hi_i,
	input wire[`RegBus]           wb_lo_i,
	input wire                    wb_whilo_i,
	
	input wire[`RegBus]           mem_hi_i,
	input wire[`RegBus]           mem_lo_i,
	input wire                    mem_whilo_i,

	input wire[`RegBus]           jump_next_address_i,
	input wire                    is_in_delayslot_i,	

	output reg[`RegAddrBus]       wd_o,
	output reg                    reg_we_o,
	output reg[`RegBus]			  wdata_o,

	output reg[`RegBus]           hi_o,
	output reg[`RegBus]           lo_o,
	output reg                    whilo_o,

	output wire[`AluOpBus]        aluop_o,
	output wire[`RegBus]          mem_addr_o,
	output wire[`RegBus]          reg2_o,

    output wire                   stall_for_instram,//访存baseram信号
	output wire				        stallreq       			
	
);

	reg[`RegBus] logicout;
	reg[`RegBus] shiftres;
	reg[`RegBus] moveres;
	reg[`RegBus] arithmeticres;
	reg[`DoubleRegBus] mulres;	
	reg[`RegBus] HI;
	reg[`RegBus] LO;
	wire[`RegBus] reg2_i_mux;
	wire[`RegBus] reg1_i_not;	
	wire[`RegBus] result_sum;
	wire ov_sum;
	wire reg1_eq_reg2;
	wire reg1_lt_reg2;
	wire[`RegBus] opdata1_mult;
	wire[`RegBus] opdata2_mult;
	wire[`DoubleRegBus] hilo_temp;

  assign aluop_o = aluop_i;
  
  assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
  
  assign stallreq=1'b0;
  assign stall_for_instram = ~mem_addr_o[22] && mem_addr_o[31] &&(aluop_i[7:5]==3'b111);
  //访存baseram信号,（地址&&访存指令）->stall_for_instram拉高
  
  
  assign reg2_o = reg2_i;
			
always @ (*) begin
	  logicout <= (rst == `RstEnable) ?`ZeroWord:
	          (aluop_i==`EXE_OR_OP) ?  reg1_i | reg2_i:
	          (aluop_i==`EXE_AND_OP)?  reg1_i & reg2_i:
	          (aluop_i==`EXE_NOR_OP)? ~(reg1_i|reg2_i):
	          (aluop_i==`EXE_XOR_OP)?  reg1_i ^ reg2_i:
	                                 `ZeroWord;
end      //always

always @ (*) begin
	 shiftres<= (rst == `RstEnable)   ?`ZeroWord:
	          (aluop_i==`EXE_SLL_OP)?  reg2_i << reg1_i[4:0]:
	          (aluop_i==`EXE_SRL_OP)?  reg2_i >> reg1_i[4:0]:
	          (aluop_i==`EXE_SRA_OP)? ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) | reg2_i >> reg1_i[4:0]:
	                                 `ZeroWord;
end      //always

	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||
											 (aluop_i == `EXE_SLT_OP) ) 
											 ? (~reg2_i)+1 : reg2_i;

	assign result_sum = reg1_i + reg2_i_mux;										 

	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
									((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31]));  
									
	assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP)) ?
							   ((reg1_i[31] && !reg2_i[31]) || 
							   (!reg1_i[31] && !reg2_i[31] && result_sum[31])||
			                   (reg1_i[31] && reg2_i[31] && result_sum[31]))
			                   :	(reg1_i < reg2_i);
  
    assign reg1_i_not = ~reg1_i;
							
always @ (*) begin
	arithmeticres <= (rst == `RstEnable)                                                      ?`ZeroWord:
	              ((aluop_i == `EXE_SLT_OP) || (aluop_i == `EXE_SLTU_OP))                     ?reg1_lt_reg2:
	              ((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDU_OP)||(aluop_i == `EXE_ADDI_OP) || (aluop_i == `EXE_ADDIU_OP))?result_sum:
	              ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP))                     ?result_sum:`ZeroWord;
end

assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) )
													&& (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;

assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP))
													&& (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;	

assign hilo_temp = opdata1_mult * opdata2_mult;																				

always @ (*) begin
	mulres <= (rst == `RstEnable)                                                         ? {`ZeroWord,`ZeroWord}:
	      ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP) && reg1_i[31]^reg2_i[31])?~hilo_temp + 1:
	      ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP))                         ?hilo_temp:hilo_temp;
end

  //数据相关问题
always @ (*) begin
	{HI,LO} <= (rst == `RstEnable)                             ?{`ZeroWord,`ZeroWord}:
	          (mem_whilo_i == `WriteEnable)   ?{mem_hi_i,mem_lo_i}:
	          (wb_whilo_i == `WriteEnable)    ?{wb_hi_i,wb_lo_i}:
	                                          {hi_i,lo_i};
end	

always @ (*) begin
	moveres <=  rst                    ?`ZeroWord:
	           (aluop_i==`EXE_MFHI_OP) ?HI:
	           (aluop_i==`EXE_MFLO_OP) ?LO:
	           (aluop_i==`EXE_MOVZ_OP) ?reg1_i:
	           (aluop_i==`EXE_MOVN_OP) ?reg1_i:
	                                   `ZeroWord;
end	 

 always @ (*) begin
	 wd_o <= wd_i;	 	 	
	 reg_we_o <= (((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1))?
	             `WriteDisable:reg_we_i;
	             
	 wdata_o  <=   (subop_i==`EXE_RES_LOGIC)      ?logicout:
	               (subop_i==`EXE_RES_SHIFT)      ?shiftres:
	               (subop_i==`EXE_RES_MOVE)       ?moveres:
	               (subop_i==`EXE_RES_ARITHMETIC) ?arithmeticres:
	               (subop_i==`EXE_RES_MUL)        ?mulres[31:0]:
	               (subop_i==`EXE_RES_JUMP_BRANCH)?jump_next_address_i: `ZeroWord;
 end	
 
always @ (*) begin
	whilo_o <=   rst                        ?`WriteDisable:
	         ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP))     ?`WriteEnable:
	         (subop_i==`EXE_MTHI_OP)       ?`WriteEnable:
	         (subop_i==`EXE_MTLO_OP)       ?`WriteEnable:`WriteDisable;
	         
	hi_o    <=   rst                        ? `ZeroWord:
	        ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP))      ? mulres[63:32]:        
            (subop_i==`EXE_MTHI_OP)        ?reg1_i:                                       
            (subop_i==`EXE_MTLO_OP)        ?HI:`ZeroWord;        
                             
	lo_o    <=   rst                        ? `ZeroWord:
	        ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP))      ? mulres[31:0]:        
            (subop_i==`EXE_MTHI_OP)        ?LO:                                       
            (subop_i==`EXE_MTLO_OP)        ?reg1_i:`ZeroWord;            
	   

end			

endmodule
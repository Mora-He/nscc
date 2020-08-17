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

module id(
	input wire						rst,
	input wire[`InstAddrBus]		pc_i,
	input wire[`InstBus]          inst_i,

    input wire[`AluOpBus]				ex_aluop_i,

	input wire					   ex_reg_we_i,//reg写请求
	input wire[`RegBus]			   ex_wdata_i,//ex阶段数据前推
	input wire[`RegAddrBus]       ex_waddr_i,//ex阶段写操作reg号，用于判断寄存器相关
	
	input wire					   mem_reg_we_i,//reg写请求                              
	input wire[`RegBus]			   mem_wdata_i,//mem阶段数据前推                      
	input wire[`RegAddrBus]       mem_waddr_i,//mem阶段写操作reg号，用于判断寄存器相关 
	
	input wire[`RegBus]           reg1_data_i,
	input wire[`RegBus]           reg2_data_i,

	input wire                    is_in_delayslot_i,

	output reg                    reg1_rd_en_o,//reg读请求
	output reg                    reg2_rd_en_o,//reg读请求 
	output reg[`RegAddrBus]       reg1_addr_o,//reg编号
	output reg[`RegAddrBus]       reg2_addr_o,//reg编号 	      
	
	output reg[`AluOpBus]         aluop_o,//运算类型
	output reg[`AluSelBus]        sub_op_o,//子运算类型，多周期指令用
	output reg[`RegBus]           reg1_data_o,
	output reg[`RegBus]           reg2_data_o,
	output reg[`RegAddrBus]       reg_num_o,//reg号
	output reg                    reg_we,//reg-we
	output wire[`RegBus]          inst_o,

	output reg                    next_inst_in_delayslot_o,
	output reg                    branch_flag_o,
	output reg[`RegBus]           branch_target_address_o,    
	output reg[`RegBus]           jump_next_addr_o,//jal&jar target address
	output reg                    is_in_delayslot_o,
	
	output wire                   stallreq	
);

  wire[5:0] op = inst_i[31:26];
  wire[4:0] op2 = inst_i[10:6];
  wire[5:0] op3 = inst_i[5:0];
  wire[4:0] op4 = inst_i[20:16];
  reg[`RegBus]	imm;
//  reg instvalid;
  wire[`RegBus] pc_plus_8;
  wire[`RegBus] pc_plus_4;
  wire[`RegBus] imm_offset;  

  reg stallreq_for_reg1_loadrelate;
  reg stallreq_for_reg2_loadrelate;
  wire pre_inst_is_load;
  
  assign pc_plus_8 = pc_i + 32'd8;//保存当前译码阶段后面的两条指令地址
  assign pc_plus_4 = pc_i + 32'd4;//保存当前译码阶段后面的一条指令地址
  assign imm_offset = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };  
  assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
  assign pre_inst_is_load = ((ex_aluop_i == `EXE_LB_OP) || 
  							(ex_aluop_i == `EXE_LBU_OP)||
  							(ex_aluop_i == `EXE_LH_OP) ||
  							(ex_aluop_i == `EXE_LHU_OP)||
  							(ex_aluop_i == `EXE_LW_OP) ||
  							(ex_aluop_i == `EXE_LWR_OP)||
  							(ex_aluop_i == `EXE_LWL_OP)||
  							(ex_aluop_i == `EXE_LL_OP) ||
  							(ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;

  assign inst_o = inst_i;
    
	always @ (*) begin	
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			sub_op_o <= `EXE_RES_NOP;
			reg_num_o <= `NOPRegAddr;
			reg_we <= `WriteDisable;
			reg1_rd_en_o <= 1'b0;
			reg2_rd_en_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;	
			jump_next_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;					
	  end else begin
			aluop_o <= `EXE_NOP_OP;
			sub_op_o <= `EXE_RES_NOP;
			reg_num_o <= inst_i[15:11];
			reg_we <= `WriteDisable;
			reg1_rd_en_o <= 1'b0;
			reg2_rd_en_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
			reg2_addr_o <= inst_i[20:16];		
			imm <= `ZeroWord;
			jump_next_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;	
			next_inst_in_delayslot_o <= `NotInDelaySlot; 			
		  case (op)
		    `EXE_SPECIAL_INST:		begin
		    	case (op2)
		    		5'b00000:			begin
		    			case (op3)
		    				`EXE_OR:	begin
		    					reg_we <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
		  						sub_op_o <= `EXE_RES_LOGIC; 	reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;
								end  
		    				`EXE_AND:	begin
		    					reg_we <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
		  						sub_op_o <= `EXE_RES_LOGIC;	  reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;	
								end  	
		    				`EXE_XOR:	begin
		    					reg_we <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
		  						sub_op_o <= `EXE_RES_LOGIC;		reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;	
								end  				
		    				`EXE_NOR:	begin
		    					reg_we <= `WriteEnable;		aluop_o <= `EXE_NOR_OP;
		  						sub_op_o <= `EXE_RES_LOGIC;		reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;	
								end 							
							`EXE_ADD: begin
								reg_we <= `WriteEnable;		aluop_o <= `EXE_ADD_OP;
		  						sub_op_o <= `EXE_RES_ARITHMETIC;		reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;
								end
							`EXE_ADDU: begin
									reg_we <= `WriteEnable;		aluop_o <= `EXE_ADDU_OP;
		  						sub_op_o <= `EXE_RES_ARITHMETIC;		reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;
								end
							`EXE_MULT: begin
									reg_we <= `WriteDisable;		aluop_o <= `EXE_MULT_OP;
		  						reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1; 
								end
							`EXE_MULTU: begin
									reg_we <= `WriteDisable;		aluop_o <= `EXE_MULTU_OP;
		  						reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;  
								end
		
							`EXE_JR: begin
								reg_we <= `WriteDisable;		aluop_o <= `EXE_JR_OP;
		  						sub_op_o <= `EXE_RES_JUMP_BRANCH;   reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;
		  						jump_next_addr_o <= `ZeroWord;
		  						branch_target_address_o <= reg1_data_o;branch_flag_o <= `Branch;
			                    next_inst_in_delayslot_o <= `InDelaySlot;
								end
							`EXE_JALR: begin
								reg_we <= `WriteEnable;		aluop_o <= `EXE_JALR_OP;
		  						sub_op_o <= `EXE_RES_JUMP_BRANCH;   reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;
		  						reg_num_o <= inst_i[15:11];
		  						jump_next_addr_o <= pc_plus_8;
			            	    branch_target_address_o <= reg1_data_o;
			            	    branch_flag_o <= `Branch;
			                    next_inst_in_delayslot_o <= `InDelaySlot;
								end													 											  											
						    default:	begin
						    end
						  endcase
						 end
						default: begin
						end
					endcase	
					end									  
		  	`EXE_ORI:			begin                        //ORI指令
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
		  		sub_op_o <= `EXE_RES_LOGIC; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		reg_num_o <= inst_i[20:16];
		  	end
		  	`EXE_ANDI:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_AND_OP;
		  		sub_op_o <= `EXE_RES_LOGIC;	reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		reg_num_o <= inst_i[20:16];		  	
				end	 	
		  	`EXE_XORI:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_XOR_OP;
		  		sub_op_o <= `EXE_RES_LOGIC;	reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		reg_num_o <= inst_i[20:16];		  	
				end	 		
		  	`EXE_LUI:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_OR_OP;
		  		sub_op_o <= `EXE_RES_LOGIC; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					imm <= {inst_i[15:0], 16'h0};		reg_num_o <= inst_i[20:16];		  
				end			
				`EXE_SLTI:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_SLT_OP;
		  		sub_op_o <= `EXE_RES_ARITHMETIC; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		reg_num_o <= inst_i[20:16];	
				end
				`EXE_SLTIU:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_SLTU_OP;
		  		sub_op_o <= `EXE_RES_ARITHMETIC; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		reg_num_o <= inst_i[20:16];		
				end
				`EXE_PREF:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_NOP_OP;
		  		sub_op_o <= `EXE_RES_NOP; reg1_rd_en_o <= 1'b0;	reg2_rd_en_o <= 1'b0;	  	  	
				end						
				`EXE_ADDI:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_ADDI_OP;
		  		sub_op_o <= `EXE_RES_ARITHMETIC; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		reg_num_o <= inst_i[20:16];		
				end
				`EXE_ADDIU:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_ADDIU_OP;
		  		sub_op_o <= `EXE_RES_ARITHMETIC; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		reg_num_o <= inst_i[20:16];		
				end
				`EXE_J:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_J_OP;
		  		sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b0;	reg2_rd_en_o <= 1'b0;
		  		jump_next_addr_o <= `ZeroWord;
			    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			    branch_flag_o <= `Branch;
			    next_inst_in_delayslot_o <= `InDelaySlot;		  	
				end
				`EXE_JAL:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_JAL_OP;
		  		sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b0;	reg2_rd_en_o <= 1'b0;
		  		reg_num_o <= 5'b11111;	
		  		jump_next_addr_o <= pc_plus_8 ;
			    branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
			    branch_flag_o <= `Branch;
			    next_inst_in_delayslot_o <= `InDelaySlot;		  	
				end
				`EXE_BEQ:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_BEQ_OP;
		  		sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;
		  		if(reg1_data_o == reg2_data_o) begin
			    	branch_target_address_o <= pc_plus_4 + imm_offset;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_BGTZ:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_BGTZ_OP;
		  		sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;
		  		if((reg1_data_o[31] == 1'b0) && (reg1_data_o != `ZeroWord)) begin
			    	branch_target_address_o <= pc_plus_4 + imm_offset;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_BLEZ:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_BLEZ_OP;
		  		sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;
		  		if((reg1_data_o[31] == 1'b1) || (reg1_data_o == `ZeroWord)) begin
			    	branch_target_address_o <= pc_plus_4 + imm_offset;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    end
				end
				`EXE_BNE:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_BLEZ_OP;
		  		sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;
		  		if(reg1_data_o != reg2_data_o) begin
			    	branch_target_address_o <= pc_plus_4 + imm_offset;
			    	branch_flag_o <= `Branch;
			    	next_inst_in_delayslot_o <= `InDelaySlot;		
			    end
				end
				`EXE_LB:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_LB_OP;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					reg_num_o <= inst_i[20:16];
				end
				`EXE_LBU:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_LBU_OP;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					reg_num_o <= inst_i[20:16];	
				end
				`EXE_LH:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_LH_OP;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					reg_num_o <= inst_i[20:16];
				end
				`EXE_LHU:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_LHU_OP;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					reg_num_o <= inst_i[20:16]; 
				end
				`EXE_LW:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_LW_OP;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					reg_num_o <= inst_i[20:16]; 
				end
				`EXE_LL:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_LL_OP;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;	  	
					reg_num_o <= inst_i[20:16];
				end
				`EXE_LWL:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_LWL_OP;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;	  	
					reg_num_o <= inst_i[20:16]; 
				end
				`EXE_LWR:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_LWR_OP;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;	  	
					reg_num_o <= inst_i[20:16];
				end			
				`EXE_SB:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_SB_OP;
		  		reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1; 
		  		sub_op_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SH:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_SH_OP;
		  		reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SW:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_SW_OP;
		  		reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWL:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_SWL_OP;
		  		reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SWR:			begin
		  		reg_we <= `WriteDisable;		aluop_o <= `EXE_SWR_OP;
		  		reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1; 
		  		sub_op_o <= `EXE_RES_LOAD_STORE; 
				end
				`EXE_SC:			begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_SC_OP;
		  		sub_op_o <= `EXE_RES_LOAD_STORE; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;	  	
					reg_num_o <= inst_i[20:16];
					sub_op_o <= `EXE_RES_LOAD_STORE; 
				end								
//				`EXE_REGIMM_INST:		begin
//					case (op4)
//						`EXE_BGEZ:	begin
//							reg_we <= `WriteDisable;		aluop_o <= `EXE_BGEZ_OP;
//		  				sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;
//		  				instvalid <= `InstValid;	
//		  				if(reg1_data_o[31] == 1'b0) begin
//			    			branch_target_address_o <= pc_plus_4 + imm_offset;
//			    			branch_flag_o <= `Branch;
//			    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
//			   			end
//						end
//						`EXE_BGEZAL:		begin
//							reg_we <= `WriteEnable;		aluop_o <= `EXE_BGEZAL_OP;
//		  				sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;
//		  				jump_next_addr_o <= pc_plus_8; 
//		  				reg_num_o <= 5'b11111;  	instvalid <= `InstValid;
//		  				if(reg1_data_o[31] == 1'b0) begin
//			    			branch_target_address_o <= pc_plus_4 + imm_offset;
//			    			branch_flag_o <= `Branch;
//			    			next_inst_in_delayslot_o <= `InDelaySlot;
//			   			end
//						end
//						`EXE_BLTZ:		begin
//						  reg_we <= `WriteDisable;		aluop_o <= `EXE_BGEZAL_OP;
//		  				sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;
//		  				instvalid <= `InstValid;	
//		  				if(reg1_data_o[31] == 1'b1) begin
//			    			branch_target_address_o <= pc_plus_4 + imm_offset;
//			    			branch_flag_o <= `Branch;
//			    			next_inst_in_delayslot_o <= `InDelaySlot;		  	
//			   			end
//						end
//						`EXE_BLTZAL:		begin
//							reg_we <= `WriteEnable;		aluop_o <= `EXE_BGEZAL_OP;
//		  				sub_op_o <= `EXE_RES_JUMP_BRANCH; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b0;
//		  				jump_next_addr_o <= pc_plus_8;	
//		  				reg_num_o <= 5'b11111; instvalid <= `InstValid;
//		  				if(reg1_data_o[31] == 1'b1) begin
//			    			branch_target_address_o <= pc_plus_4 + imm_offset;
//			    			branch_flag_o <= `Branch;
//			    			next_inst_in_delayslot_o <= `InDelaySlot;
//			   			end
//						end
//						default:	begin
//						end
//					endcase
//				end								
				`EXE_SPECIAL2_INST:		begin
					case ( op3 )
						`EXE_MUL:		begin
							reg_we <= `WriteEnable;		aluop_o <= `EXE_MUL_OP;
		  				sub_op_o <= `EXE_RES_MUL; reg1_rd_en_o <= 1'b1;	reg2_rd_en_o <= 1'b1;	
						end					
						default:	begin
						end
					endcase      //EXE_SPECIAL_INST2 case
				end																		  	
		    default:			begin
		    end
		  endcase		  //case op
		  if (inst_i[31:21] == 11'b00000000000) begin
		  	if (op3 == `EXE_SLL) begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_SLL_OP;
		  		sub_op_o <= `EXE_RES_SHIFT; reg1_rd_en_o <= 1'b0;	reg2_rd_en_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		reg_num_o <= inst_i[15:11];
				end else if ( op3 == `EXE_SRL ) begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_SRL_OP;
		  		sub_op_o <= `EXE_RES_SHIFT; reg1_rd_en_o <= 1'b0;	reg2_rd_en_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		reg_num_o <= inst_i[15:11];
				end else if ( op3 == `EXE_SRA ) begin
		  		reg_we <= `WriteEnable;		aluop_o <= `EXE_SRA_OP;
		  		sub_op_o <= `EXE_RES_SHIFT; reg1_rd_en_o <= 1'b0;	reg2_rd_en_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		reg_num_o <= inst_i[15:11];
				end
			end		  
		end       //if
	end         //always
	

	always @ (*) begin
        stallreq_for_reg1_loadrelate <=(rst == `RstEnable)  ?`NoStop:
                        (pre_inst_is_load == 1'b1 && ex_waddr_i == reg1_addr_o&& reg1_rd_en_o == 1'b1 )?`Stop:`NoStop;
                        
        reg1_data_o <=  (rst == `RstEnable)                  ?`ZeroWord:
                    ((reg1_rd_en_o == 1'b1)&& (ex_reg_we_i == 1'b1)&& (ex_waddr_i == reg1_addr_o))    ?ex_wdata_i:
                    ((reg1_rd_en_o == 1'b1) && (mem_reg_we_i == 1'b1)&& (mem_waddr_i == reg1_addr_o)) ?mem_wdata_i:
                    (reg1_rd_en_o == 1'b1)       ?reg1_data_i:
                    (reg1_rd_en_o == 1'b0)       ?imm:
                    `ZeroWord;
	end
	
	always @ (*) begin
	   stallreq_for_reg2_loadrelate <=(rst == `RstEnable)?`NoStop:
	                   (pre_inst_is_load == 1'b1 && ex_waddr_i == reg2_addr_o&& reg2_rd_en_o == 1'b1 )?`Stop:`NoStop;
	                   
         reg2_data_o <=(rst == `RstEnable)            ?`ZeroWord:
                    ((reg2_rd_en_o == 1'b1) && (ex_reg_we_i == 1'b1)&& (ex_waddr_i == reg2_addr_o))   ?ex_wdata_i:
                    ((reg2_rd_en_o == 1'b1) && (mem_reg_we_i == 1'b1)&& (mem_waddr_i == reg2_addr_o)) ?mem_wdata_i:
                    (reg2_rd_en_o == 1'b1)       ?reg2_data_i:
                    (reg2_rd_en_o == 1'b0)       ?imm:
                    `ZeroWord;
	end

	always @ (*) begin
        is_in_delayslot_o <= (rst == `RstEnable) ?`NotInDelaySlot:is_in_delayslot_i;		
	end

endmodule
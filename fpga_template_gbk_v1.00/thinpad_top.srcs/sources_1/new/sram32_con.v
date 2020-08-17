`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/15 21:02:33
// Design Name: 
// Module Name: sram32_con
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sram32_con(
    input wire clk,
    input wire clk_50M,
    input wire rst,
    input wire we_i,//д����   ����Ч   ��cpu��we
    input wire ce_i,

    output reg iodata_en,//��̬�ſ����ź�
    output reg read_ready,//����ɣ��Ѵ�ram��ȡ��dataʱ����
    
    output wire ce_n,//ce  chipenabled
    output reg oe_n,//��ʹ��
    output wire we_n//weдʹ��
    );

    (*mark_debug = "TRUE"*)reg[3:0] cstate,nstate;
    
parameter  IDLE = 4'd0,
            WRITE0 = 4'd1,
            WRITE1 = 4'd2,
            READ0  = 4'd3,
            READ1  = 4'd4;
 
always@(posedge clk or posedge rst)
begin
    if(rst)cstate<=IDLE;
    else cstate<=nstate;
end

reg[2:0] delay=3'd0;
always@(posedge clk_50M)
begin
    if(rst)delay<=3'd0;
    else if(delay==3'd4) delay<=3'd0;
    else if(nstate==READ0||nstate==WRITE0)delay<=delay+3'b1;
    else if(cstate==IDLE&&(nstate==READ0||nstate==WRITE0))delay<=delay+3'b1;
    else if(cstate==WRITE1&&(nstate==READ0||nstate==WRITE0))delay<=delay+3'b1;
    else if(cstate==IDLE) delay<=3'd0;
    else delay<=3'd0;
//        delay<=3'd1;
end
`define delay_TAA   (delay>=3'd1)//0.1ns
`define delay_TSA   (delay>=3'd1)//0.1ns


always@(*)
begin
//    if(!ce_i)begin
    case(cstate)
        IDLE:if(we_i&&ce_i)nstate<=WRITE0;
            else if(!we_i&&ce_i)nstate<=READ0;
            else nstate<=IDLE;
//        WRITE0:nstate<=WRITE1;
////        if(`delay_TSA)nstate<=WRITE1;
////                else nstate<=WRITE0;
//        WRITE1:if(we_i&&ce_i)nstate<=WRITE0;
//            else if(!we_i&&ce_i)nstate<=READ0;
//            else nstate<=IDLE;
        WRITE0:if(we_i&&ce_i)nstate<=WRITE0;
            else if(!we_i&&ce_i)nstate<=READ0;
            else nstate<=IDLE;
        READ0:if(!we_i&&ce_i)nstate<=READ0;
            else if(we_i&&ce_i)nstate<=WRITE0;
            else nstate<=IDLE;       
//        READ1:nstate<=IDLE;                 
        default:nstate<=IDLE;
    endcase
//    end
end    
    
assign ce_n = ~ce_i;    //SRAM Chip Select enable
//assign oe_n = ~read_ready;    //SRAM output enable = = cpu can read ram
//assign be_n= sel_i;    //byte always available
//assign controller_addr_o = cpu_addr_i;  
//-----------------write------------------------
//always@(posedge clk or posedge rst)
//begin
//    if(rst)iodata_en<=1'd0;
//    else  case(cstate)
//        IDLE:if(we_i) iodata_en<= 1'b1;///
//             else if(!we_i)iodata_en <= 1'b0;
//             else iodata_en<= 1'b0;
//        WRITE0:begin iodata_en<=1'd1;  end
//        WRITE1:begin iodata_en<=1'd1;  end   
//        default:iodata_en<=1'd0;
//    endcase
//end
always@(*)
begin
    if(rst)iodata_en=1'd0;
    else if(nstate==IDLE&&we_i&&ce_i&&`delay_TSA&&delay!=3'b0) iodata_en= 1'b1;
//    else if(nstate==WRITE0||nstate==WRITE1) iodata_en=1'b1;
    else if(nstate==WRITE0&&delay!=3'b0) iodata_en=1'b1;
    else iodata_en=1'd0;
end


assign we_n = (~iodata_en);       //дʹ�ܵ���Ч��д״̬ʱiodata_enΪ1��we_nΪ0

//---------------read----------------------------
//always@(posedge clk or posedge rst)
//begin
//    if(rst)read_ready<=1'd0;
//    else if(nstate==READ0) read_ready<=1'b1;
//    else read_ready<=1'd0;
//end
always@(*)
begin
    if(rst)read_ready=1'd0;
    else if(nstate==READ0&&`delay_TAA) read_ready=1'b1;
    else read_ready=1'd0;
end

//always@(posedge clk or posedge rst)  
//begin
//    if(rst)oe_n<=1'd1;
//    else if(nstate==READ0) oe_n<=1'b0;
////    else if(nstate==READ1) oe_n<=1'b0;
//    else oe_n<=1'd1;
//end

always@(*)  
begin
    if(rst)oe_n=1'd1;
    else if(nstate==READ0&&delay!=3'b0) oe_n=1'b0;
//    else if(nstate==READ1) oe_n<=1'b0;
    else oe_n=1'd1;
end


endmodule

   
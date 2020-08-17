`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/08/10 18:42:18
// Design Name: 
// Module Name: pc_if
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

`include "defines.v"

module pc_if(
    input wire clk,
    input wire rst,
    input wire[31:0]  pc_i,
    output reg[31:0]  pc_o
    );
    
//    always@(posedge clk)
//    begin
//        pc_o<=(rst == 1'b1)?32'h80000000:pc_i;
//    end
    
endmodule

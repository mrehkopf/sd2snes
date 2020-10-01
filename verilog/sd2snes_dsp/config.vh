`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:31:19 01/19/2019 
// Design Name: 
// Module Name:    config 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

`ifndef _config_vh
`define _config_vh

// `define DEBUG

`ifdef MK2
  `ifdef DEBUG
    `define MK2_DEBUG
  `endif
`endif

`endif
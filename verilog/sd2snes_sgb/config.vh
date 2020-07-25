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

`ifdef MK2
  //`define MSU_AUDIO // doesn't fit with features below
  
`ifndef MSU_AUDIO
  `define SGB_MCU_ACCESS
  `define SGB_SAVE_STATES
  `define SGB_SERIAL
  `define SGB_EXTRA_MAPPERS
`endif

  `define BRIGHTNESS_PATCH

  // doesn't fit
  //`define MSU_DATA
  //`define BRIGHTNESS_LIMIT
  //`define SGB_DEBUG
  //`define SGB_SPR_INCREASE
`else
  `define MSU_AUDIO
  `define MSU_DATA
  `define BRIGHTNESS_PATCH
  `define BRIGHTNESS_LIMIT
  `define SGB_MCU_ACCESS
  `define SGB_SAVE_STATES
  `define SGB_SERIAL
  `define SGB_DEBUG
  `define SGB_SPR_INCREASE
  `define SGB_EXTRA_MAPPERS
`endif

`define SGB_FEAT_VOL_BOOST    2:0
`define SGB_FEAT_ENH_OVERRIDE 8:8
`define SGB_FEAT_SPR_INCREASE 9:9

`endif

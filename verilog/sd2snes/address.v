`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Company: Rehkopf
// Engineer: Rehkopf
// 
// Create Date:    01:13:46 05/09/2009 
// Design Name: 
// Module Name:    address 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: Address logic w/ SaveRAM masking
//
// Dependencies: 
//
// Revision: 
// Revision 0.02 - All new combinatorial glory. fucking slow.
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module address(
    input CLK,
    input [2:0] MAPPER,       // AVR detected mapper
    input [23:0] SNES_ADDR,   // requested address from SNES
    input SNES_CS,            // "CART" pin from SNES (active low)
    output [19:0] SRAM_ADDR,  // Address to request from SRAM
    output [3:0] ROM_SEL,     // which SRAM unit to access (active low)
    input AVR_ENA,            // enable AVR master mode (active low)
    input MODE,               // AVR(1) or SNES(0) ("bus phase")
    output IS_SAVERAM,        // address/CS mapped as SRAM?
    output IS_ROM,            // address mapped as ROM?
    input [23:0] AVR_ADDR,    // allow address to be set externally
    input ADDR_WRITE,
    output SRAM_ADDR0,
    input [23:0] SAVERAM_MASK,
    input [23:0] ROM_MASK
    );

reg [3:0] AVR_ROM_SEL_BUF;
reg [3:0] CS_ARRAY[3:0];
wire [1:0] SRAM_BANK;

wire [3:0] CURRENT_ROM_SEL;
wire [22:0] SRAM_ADDR_FULL;

initial begin
   CS_ARRAY[0] = 4'b0001;
   CS_ARRAY[1] = 4'b0010;
   CS_ARRAY[2] = 4'b0100;
   CS_ARRAY[3] = 4'b1000;
end 

/* currently supported mappers:
   Index     Mapper     
      000      HiROM
      001      LoROM
      010      ExHiROM (48-64Mbit)
      
      111      menu (ROM in upper SRAM)
*/

/*                               HiROM:   SRAM @ Bank 0x30-0x3f, 0xb0-0xbf
                                          Offset 6000-7fff */

assign IS_ROM = ( (MAPPER == 3'b000) ? ( (!SNES_ADDR[22]
                                         & SNES_ADDR[15])
                                       |(SNES_ADDR[22]))
                : (MAPPER == 3'b001) ? ( (SNES_ADDR[15] & !SNES_ADDR[22])
                                        |(SNES_ADDR[22]))                                         
                : (MAPPER == 3'b010) ? ((!SNES_ADDR[22] & SNES_ADDR[15])
                                       |(SNES_ADDR[22]))
                : (MAPPER == 3'b111) ? ((!SNES_ADDR[22] & SNES_ADDR[15])
                                       |(SNES_ADDR[22]))
                : 1'b0);

assign IS_SAVERAM = ((MAPPER == 3'b000 || MAPPER == 3'b010 || MAPPER == 3'b111) ? (!SNES_ADDR[22]
                                           & SNES_ADDR[21:20]                                           
                                           & &SNES_ADDR[14:13]
                                           & !SNES_ADDR[15]
                                           & SNES_CS
                                           )
/*                               LoROM:   SRAM @ Bank 0x70-0x7d, 0xf0-0xfd
                                          Offset 0000-7fff TODO: 0000-ffff for
                                          small ROMs */
                    :(MAPPER == 3'b001) ? (&SNES_ADDR[22:20]
                                           & (SNES_ADDR[19:16] < 4'b1110)
                                           & !SNES_ADDR[15]
                                           & !SNES_CS)
                    : 1'b0);

assign SRAM_ADDR_FULL = (MODE) ? AVR_ADDR
                          : ((MAPPER == 3'b000) ?
                              (IS_SAVERAM ? (SNES_ADDR[14:0] - 15'h6000) & SAVERAM_MASK
                                          : (SNES_ADDR[22:0] & ROM_MASK))
                            :(MAPPER == 3'b001) ? 
                              (IS_SAVERAM ? SNES_ADDR[14:0] & SAVERAM_MASK
                                          : ({1'b0, SNES_ADDR[22:16], SNES_ADDR[14:0]} & ROM_MASK))
                            :(MAPPER == 3'b010) ?
                              (IS_SAVERAM ? (SNES_ADDR[14:0] - 15'h6000) & SAVERAM_MASK
                                          : ({!SNES_ADDR[23], SNES_ADDR[21:0]} & ROM_MASK))
                            :(MAPPER == 3'b111) ?
                              (IS_SAVERAM ? 23'h7F0000 + ((SNES_ADDR[14:0] - 15'h6000) & SAVERAM_MASK)
                                          : ((SNES_ADDR[22:0] & ROM_MASK) + 23'h600000))
                            : 23'b0);

assign SRAM_BANK = SRAM_ADDR_FULL[22:21];
assign SRAM_ADDR = SRAM_ADDR_FULL[20:1];

assign ROM_SEL = (MODE) ? CS_ARRAY[SRAM_BANK] : IS_SAVERAM ? 4'b1000 : CS_ARRAY[SRAM_BANK];

assign SRAM_ADDR0 = SRAM_ADDR_FULL[0];

endmodule

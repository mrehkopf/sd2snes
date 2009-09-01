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
    output [20:0] SRAM_ADDR,  // Address to request from SRAM
    output [3:0] ROM_SEL,     // which SRAM unit to access (active low)
    input AVR_ADDR_RESET,     // reset AVR sequence (active low)
    input AVR_NEXTADDR,       // next byte request from AVR
    input AVR_ENA,            // enable AVR master mode (active low)
    input AVR_ADDR_EN,        // enable address counter (active low)
    input [1:0] AVR_BANK,     // which bank does the AVR want
	 input MODE,               // AVR(1) or SNES(0) ("bus phase")
    output IS_SAVERAM,        // address/CS mapped as SRAM?
    output IS_ROM,            // address mapped as ROM?
    input AVR_NEXTADDR_CURR,
    input AVR_NEXTADDR_PREV
    );

reg [22:0] SRAM_ADDR_BUF;
reg [3:0] ROM_SEL_BUF;
reg [3:0] AVR_ROM_SEL_BUF;
reg [20:0] AVR_ADDR;
reg [3:0] CS_ARRAY[3:0];

wire [3:0] CURRENT_ROM_SEL;
wire [22:0] SRAM_ADDR_FULL;

initial begin
   AVR_ADDR = 21'b0;
   CS_ARRAY[0] = 4'b1110;
   CS_ARRAY[1] = 4'b1101;
   CS_ARRAY[2] = 4'b1011;
   CS_ARRAY[3] = 4'b0111;
end 

/* currently supported mappers:
   Index     Mapper     
      000      HiROM
      001      LoROM
*/

/*                               HiROM:   SRAM @ Bank 0x20-0x3f, 0xa0-0xbf
                                          Offset 6000-7fff */
assign IS_SAVERAM = ((MAPPER == 3'b000) ? (!SNES_ADDR[22]
                                           & SNES_ADDR[21] 
                                           & &SNES_ADDR[14:13]
                                           & !SNES_ADDR[15]
                                           )
/*                               LoROM:   SRAM @ Bank 0x70-0x7f, 0xf0-0xff
                                          Offset 0000-7fff */
                    :(MAPPER == 3'b001) ? (&SNES_ADDR[22:20]
                                           & !SNES_ADDR[15]
                                           & !SNES_CS)
                    : 1'b0);

assign IS_ROM = ((MAPPER == 3'b000) ? ( (!SNES_ADDR[22]
                                         & SNES_ADDR[15])
                                       |(SNES_ADDR[22]))
                :(MAPPER == 3'b001) ? ( (SNES_ADDR[15]) )
                : 1'b0);
                                         
assign SRAM_ADDR_FULL = (MODE) ? AVR_ADDR
                          : ((MAPPER == 3'b000) ?
                              (IS_SAVERAM ? SNES_ADDR[14:0] - 15'h6000
                                          : SNES_ADDR[22:0])
                            :(MAPPER == 3'b001) ? 
                              (IS_SAVERAM ? SNES_ADDR[14:0]
                                          : {1'b0, SNES_ADDR[22:16], SNES_ADDR[14:0]})
                            : 21'b0);

assign SRAM_BANK = SRAM_ADDR_FULL[22:21];
assign SRAM_ADDR = SRAM_ADDR_FULL[20:0];

assign ROM_SEL = (MODE) ? CS_ARRAY[AVR_BANK] : IS_SAVERAM ? 4'b0111 : 4'b1110; // CS_ARRAY[SRAM_BANK];
//assign ROM_SEL = 4'b1110;

always @(posedge CLK) begin
   if(AVR_NEXTADDR_CURR) begin
      if(!AVR_NEXTADDR_PREV) begin
         if(!AVR_ADDR_RESET)
            AVR_ADDR <= 21'b0;
         else if (!AVR_ADDR_EN)
            AVR_ADDR <= AVR_ADDR + 1;
      end
   end
end


/*
always @(posedge AVR_NEXTADDR) begin
   if (!AVR_ADDR_RESET)
      AVR_ADDR <= 21'b0;
   else if (!AVR_ADDR_EN)
      AVR_ADDR <= AVR_ADDR + 1;
end
*/
endmodule
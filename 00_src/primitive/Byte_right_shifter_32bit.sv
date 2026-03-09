///////////////////////////////////////
//// Byte right shifter logic ////
///////////////////////////////////////
module Byte_right_shifter_32bit (
  input logic [63:0] shifter_input,
  input logic [1:0]  byte_shift, 
  output logic [31:0] shifter_output
 );
  always_comb begin 
    case ( byte_shift )
	   2'b00 : shifter_output = shifter_input [31:0];
		 2'b01 : shifter_output = shifter_input [39:8];
		 2'b10 : shifter_output = shifter_input [47:16];
		 2'b11 : shifter_output = shifter_input [55:24];
	 endcase
  end
endmodule : Byte_right_shifter_32bit


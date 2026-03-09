//////////////////////////////////////
//// Byte left shifter ///////////////
//////////////////////////////////////
module Byte_left_shifter_32bit (
  input logic [31:0] shifter_input,
  input logic [1:0]  byte_shift, 
  output logic [63:0] shifter_output
 );
  always_comb begin 
    case ( byte_shift )
	   2'b00 : shifter_output = { 32'd0, shifter_input [31:0] };
		 2'b01 : shifter_output = { 24'd0, shifter_input [31:0], 8'd0  };
		 2'b10 : shifter_output = { 16'd0, shifter_input [31:0], 16'd0 };
		 2'b11 : shifter_output = { 8'd0, shifter_input [31:0],  24'd0 };
	 endcase
  end
endmodule : Byte_left_shifter_32bit
module dmem (
   input logic [31:0] data_a, data_b,
   input logic [13:0] addr_a, addr_b,
 	input logic [3:0] be_a, be_b,
   input logic  we, clk,
   output logic [31:0] q_a, q_b
);
   byte_mem byte_mem0 (
	 .clk    ( clk ),
	 .data_a ( data_a [7:0] ),
	 .data_b ( data_b [7:0] ),
	 .we_a   ( be_a [0] & we ),
	 .we_b   ( be_b [0] & we ),
	 .addr_a ( addr_a ),
	 .addr_b ( addr_b ),
	 .q_a    ( q_a [7:0] ),
	 .q_b    ( q_b [7:0] ) 
	);
	byte_mem byte_mem1 (
	 .clk    ( clk ),
	 .data_a ( data_a [15:8] ),
	 .data_b ( data_b [15:8] ),
	 .we_a   ( be_a [1] & we ),
	 .we_b   ( be_b [1] & we),
	 .addr_a ( addr_a ),
	 .addr_b ( addr_b ),
	 .q_a    ( q_a [15:8] ),
	 .q_b    ( q_b [15:8] ) 
	);
   byte_mem byte_mem2 (
	 .clk    ( clk ),
	 .data_a ( data_a [23:16] ),
	 .data_b ( data_b [23:16] ),
	 .we_a   ( be_a [2] & we),
	 .we_b   ( be_b [2] & we),
	 .addr_a ( addr_a ),
	 .addr_b ( addr_b ),
	 .q_a    ( q_a [23:16] ),
	 .q_b    ( q_b [23:16] ) 
	);	
   byte_mem byte_mem3 (
	 .clk    ( clk ),
	 .data_a ( data_a [31:24] ),
	 .data_b ( data_b [31:24] ),
	 .we_a   ( be_a [3] & we),
	 .we_b   ( be_b [3] & we),
	 .addr_a ( addr_a ),
	 .addr_b ( addr_b ),
	 .q_a    ( q_a [31:24] ),
	 .q_b    ( q_b [31:24] ) 
	);	
endmodule

module byte_mem (
   input logic [7:0] data_a, data_b,
   input logic [13:0] addr_a, addr_b,
   input logic  we_a, we_b, clk,
   output logic [7:0] q_a, q_b
);
// Declare the RAM variable
   logic [7:0] ram[16383:0];
   always @ (posedge clk) begin // Port A
     if (we_a) begin
       ram[addr_a] <= data_a;
       q_a <= data_a;
     end else q_a <= ram[addr_a];
   end
	
   always @ (posedge clk) begin // Port b
     if (we_b) begin
       ram[addr_b] <= data_b;
       q_b <= data_b;
     end else q_b <= ram[addr_b];
   end
endmodule


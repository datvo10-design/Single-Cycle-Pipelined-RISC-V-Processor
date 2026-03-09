module stack_ra_unit (
  input logic clk, rstn,
  // write
  input logic [6:0] EX_opcode,
  input logic [31:0] EX_pc_add_4,
  //load
  input logic [6:0] IF_opcode,
  output logic [31:0] pc_ra,
  output logic vld
);
 // stack reg
  logic [30:0] stack [3:0];
  logic w_en, reset;
  logic [1:0] addr;
  logic [1:0] next_addr;
  always_ff @( posedge clk ) begin 
    if ( reset ) stack [next_addr] <= 31'd0;
    else if ( w_en ) stack [addr] <= { EX_pc_add_4, 1'b1 };
  end
 // write processor
  assign w_en = ( & EX_opcode [6:5] ) & ( ~ EX_opcode [4] ) & ( & EX_opcode [3:0] );
 // read processor
   //mux
  logic [30:0] out_mux;
  always_comb begin 
    case ( addr ) 
      2'b00: out_mux = stack [3]; 
      2'b01: out_mux = stack [0];
      2'b10: out_mux = stack [1];
      2'b11: out_mux = stack [2];
    endcase
  end
   // read en
  logic r_en;
  assign r_en = ( & IF_opcode [6:5] ) & ( &( ~ IF_opcode [4:3] ) ) & ( & IF_opcode [2:0] ); 
  assign { pc_ra, vld } = { 30{ r_en } } & out_mux;
  assign reset = r_en;
 // FSM for addr
  logic [1:0] set_of_en;
  assign set_of_en = { w_en, r_en }; 
  always_comb begin
   case ( addr ) 
     2'b00: begin 
       case ( set_of_en ) 
         2'b10: next_addr = 2'b01;
         2'b01: next_addr = 2'b11;
         default: next_addr = addr;
       endcase 
     end
     2'b01: begin 
       case ( set_of_en ) 
         2'b10: next_addr = 2'b10;
         2'b01: next_addr = 2'b00;
         default: next_addr = addr;
       endcase
     end
     2'b10: begin 
       case ( set_of_en ) 
         2'b10: next_addr = 2'b11;
         2'b01: next_addr = 2'b01;
         default: next_addr = addr;
       endcase
     end
     2'b11: begin 
       case ( set_of_en ) 
         2'b10: next_addr = 2'b00;
         2'b01: next_addr = 2'b10;
         default: next_addr = addr;
       endcase
     end
   endcase
  end
   //state
  always_ff @( posedge clk ) begin
    if ( ~rstn ) addr <= 2'b00;
    else addr <= next_addr;
  end
endmodule



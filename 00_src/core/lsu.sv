/////////////////////////////////////////
//// main module ////////////////////////
/////////////////////////////////////////
module lsu (
 //// input ////
  input logic         i_clk,
  input logic         i_rstn,
  input logic [31:0]  i_lsu_addr,
  input logic [31:0]  i_st_data, 
  input logic         i_lsu_wren,  //// load or store 
  input logic [2:0]   funct3, //// funct3 [1:0] = 11 is nothing, 00 is byte access, 01 is half word access, 10 is word access
                              //// funct3 [2]   = 1  is unsigned-extended
  input logic [31:0]  i_io_sw,
 //// output ////
  output logic [31:0] o_ld_data,
  output logic [31:0] o_io_ledr,
  output logic [31:0] o_io_ledg,
  output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
                      o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7,
  output logic [31:0] o_io_lcd
);
/////////////////////////////////////////
//// Write stage ////////////////////////
/////////////////////////////////////////
/////////////////////////////////////////
//// byte left shifter instantiation ////
/////////////////////////////////////////
  logic [1:0] W_byte_shift;
  logic [63:0] left_shifter_output;
  assign W_byte_shift = i_lsu_addr [1:0];
  Byte_left_shifter_32bit Byte_left_shifter_32bit0 (
    .shifter_input  ( i_st_data ),
    .byte_shift     ( W_byte_shift ),
    .shifter_output ( left_shifter_output )
);
///////////////////////////////////////////////////
//// memory domains instantiation /////////////////
///////////////////////////////////////////////////
  //// enable access ////
  logic dmem_access_en, ledr_access_en, ledg_access_en, 
        led_3_0_access_en, led_7_4_access_en, lcd_access_en,  //// enable accessc for each memory domain //// 
        sw_access_en;
  assign dmem_access_en     = & ( ~i_lsu_addr [31:16] );
  assign ledr_access_en     = ( & ( ~i_lsu_addr [31:29] ) ) & i_lsu_addr [28] & ( & ( ~i_lsu_addr [27:2] ) );
  assign ledg_access_en     = ( & ( ~i_lsu_addr [31:29] ) ) & i_lsu_addr [28] & ( & ( ~i_lsu_addr [27:13] ) ) & 
                             i_lsu_addr [12] & ( & ( ~i_lsu_addr [11:2] ) );
  assign led_3_0_access_en = ( & ( ~i_lsu_addr [31:29] ) ) & i_lsu_addr [28] & ( & ( ~i_lsu_addr [27:14] ) ) & 
                             i_lsu_addr [13] & ( & ( ~i_lsu_addr [12:2] ) );
  assign led_7_4_access_en = ( & ( ~i_lsu_addr [31:29] ) ) & i_lsu_addr [28] & ( & ( ~i_lsu_addr [27:14] ) ) & 
                             i_lsu_addr [13] & i_lsu_addr [12] & ( & ( ~i_lsu_addr [11:2] ) );
  assign lcd_access_en     = ( & ( ~i_lsu_addr [31:29] ) ) & i_lsu_addr [28] & ( & ( ~i_lsu_addr [27:15] ) ) & 
                             i_lsu_addr [14] & ( & ( ~i_lsu_addr [13:2] ) );
  assign sw_access_en      = ( & ( ~i_lsu_addr [31:29] ) ) & i_lsu_addr [28] & ( & ( ~i_lsu_addr [27:17] ) ) & 
                             i_lsu_addr [16] & ( & ( ~i_lsu_addr [15:2] ) );
  //// access signal for the load stage ////
  logic [6:0] W_set_of_access;
  assign W_set_of_access =  { sw_access_en, 
                            lcd_access_en, led_7_4_access_en, led_3_0_access_en,
                            ledg_access_en, ledr_access_en, dmem_access_en }; 
  //// combinational for the bmask signal ////
  logic [7:0] W_bmask;
  logic [2:0] W_funct3;
  assign W_funct3 = funct3;
  always_comb begin 
    case ( W_funct3 [1:0] ) 
     2'b00 : begin 
      case ( i_lsu_addr [1:0] )
        2'b00 : W_bmask = 8'b00000001;
        2'b01 : W_bmask = 8'b00000010;
        2'b10 : W_bmask = 8'b00000100;
        2'b11 : W_bmask = 8'b00001000;
      endcase
     end
     2'b01 : begin 
      case ( i_lsu_addr [1:0] )
        2'b00 : W_bmask = 8'd3;
        2'b01 : W_bmask = 8'd6;
        2'b10 : W_bmask = 8'd12;
        2'b11 : W_bmask = 8'd24;
      endcase
     end
     2'b10 : begin
      case ( i_lsu_addr [1:0] )
        2'b00 : W_bmask = 8'd15;
        2'b01 : W_bmask = 8'd30;
        2'b10 : W_bmask = 8'd60;
        2'b11 : W_bmask = 8'd120;
      endcase
     end
     2'b11 : W_bmask = 8'd0;
    endcase
  end
  //// next addr ///////////////////////////
  logic [31:0] next_addr;
  add_32bit next_address (
    .A ( i_lsu_addr ),
    .B ( 32'd4 ),
    .SUM ( next_addr ),
    .C_o ( )
  );
  //// dmem ////////////////////////////////
  logic [31:0] o_rdata; 
  logic [31:0] o_rdata_next_addr;
  logic [31:0] o_rdata_not_filtering;  // ordata chua dc loc qua bmask //
  logic [31:0] o_rdata_next_addr_not_filtering;  
  logic        W_lsu_wren;
  assign       W_lsu_wren = i_lsu_wren;
  dmem dmem0 (
   .clk                 ( i_clk & dmem_access_en ),
   .addr_a              ( i_lsu_addr [15:2] ),
   .addr_b              ( next_addr [15:2] ),
   .data_a              ( left_shifter_output [31:0] ),
   .data_b              ( left_shifter_output [63:32] ),
   .be_a                ( W_bmask [3:0] ),
   .be_b                ( W_bmask [7:4] ),
   .we                  ( W_lsu_wren ),
   .q_a                 ( o_rdata_not_filtering ),
   .q_b                 ( o_rdata_next_addr_not_filtering )
);
 //// io_ledr ////////////////////////////////
  logic [31:0] o_data_ledr; 
  io_reg io_ledr ( 
    .i_clk       ( i_clk ),
   .i_reset      ( i_rstn ),
   .i_access_en  ( ledr_access_en ),
   .i_wdata      ( left_shifter_output [31:0] ),
   .i_bmask      ( W_bmask [3:0] ),
   .i_wren       ( W_lsu_wren ),
   .o_data       ( o_data_ledr ),
   .o_io         ( o_io_ledr )
);
//// io_ledg ////////////////////////////////
  logic [31:0] o_data_ledg; 
  io_reg io_ledg ( 
    .i_clk       ( i_clk ),
   .i_reset      ( i_rstn ),
   .i_access_en  ( ledg_access_en ),
   .i_wdata      ( left_shifter_output [31:0] ),
   .i_bmask      ( W_bmask [3:0] ),
   .i_wren       ( W_lsu_wren ),
   .o_data       ( o_data_ledg ),
   .o_io         ( o_io_ledg )
);
//// io_Seven_segment_LEDs_3_0 ////////////////////////////////
  logic [31:0] o_data_led3_0; 
  logic [31:0] o_io_led3_0;
  io_reg io_Seven_segment_LEDs_3_0 ( 
    .i_clk       ( i_clk ),
   .i_reset      ( i_rstn ),
   .i_access_en ( led_3_0_access_en ),
   .i_wdata      ( left_shifter_output [31:0] ),
   .i_bmask      ( W_bmask [3:0] ),
   .i_wren       ( W_lsu_wren ),
   .o_data       ( o_data_led3_0 ),
   .o_io         ( o_io_led3_0)
);
  assign o_io_hex3 = o_io_led3_0 [30:24];
  assign o_io_hex2 = o_io_led3_0 [22:16];
  assign o_io_hex1 = o_io_led3_0 [14:8];
  assign o_io_hex0 = o_io_led3_0 [6:0];
//// io_Seven_segment_LEDs_7_4 ////////////////////////////////
  logic [31:0] o_data_led7_4; 
  logic [31:0] o_io_led7_4;
  io_reg io_Seven_segment_LEDs_7_4 ( 
    .i_clk       ( i_clk ),
   .i_reset      ( i_rstn ),
   .i_access_en ( led_7_4_access_en ),
   .i_wdata      ( left_shifter_output [31:0] ),
   .i_bmask      ( W_bmask [3:0] ),
   .i_wren       ( W_lsu_wren ),
   .o_data       ( o_data_led7_4 ),
   .o_io         ( o_io_led7_4 )
);
  assign o_io_hex7 = o_io_led7_4 [30:24];
  assign o_io_hex6 = o_io_led7_4 [22:16];
  assign o_io_hex5 = o_io_led7_4 [14:8];
  assign o_io_hex4 = o_io_led7_4 [6:0];
//// io_lcd ////////////////////////////////
  logic [31:0] o_data_lcd; 
  io_reg io_lcd0 ( 
    .i_clk       ( i_clk ),
   .i_reset      ( i_rstn ),
   .i_access_en ( lcd_access_en ),
   .i_wdata      ( left_shifter_output [31:0] ),
   .i_bmask      ( W_bmask [3:0] ),
   .i_wren       ( W_lsu_wren ),
   .o_data       ( o_data_lcd ),
   .o_io         ( o_io_lcd )
);
//// io_sw ////////////////////////////////
  logic [31:0] o_data_sw; 
sw_io io_sw0 ( 
    .i_clk         ( i_clk ),
    .i_reset       ( i_rstn ),
    .i_access_en   ( sw_access_en ),
    .i_sw_external ( i_io_sw ),   
    .i_bmask       ( W_bmask [3:0] ),
    .o_data_sw     ( o_data_sw )  
); 
/////////////////////////////////
//// PIPELINED FOR LSU //////////
/////////////////////////////////
  logic [6:0] R_set_of_access;
  logic [1:0] R_byte_shift;
  logic [2:0] R_funct3;
  logic [7:0] R_bmask;
  logic        R_lsu_wren;
  always_ff @( posedge i_clk) R_set_of_access <= W_set_of_access;
  always_ff @( posedge i_clk) R_byte_shift <= W_byte_shift;
  always_ff @( posedge i_clk) R_funct3 <= W_funct3;
  always_ff @( posedge i_clk) R_bmask <= W_bmask;
  always_ff @( posedge i_clk) R_lsu_wren <= W_lsu_wren;
/////////////////////////////////
//// Load stage ////////////
/////////////////////////////////
//// filltering the output of dmem ////
 logic [63:0] fillter;
 assign fillter = { {8{R_bmask[7]}}, {8{R_bmask[6]}}, {8{R_bmask[5]}}, {8{R_bmask[4]}}, {8{R_bmask[3]}}, {8{R_bmask[2]}}, {8{R_bmask[1]}}, {8{R_bmask[0]}} };  
 assign o_rdata = fillter [31:0] & { 32{ ~R_lsu_wren } } & o_rdata_not_filtering;
 assign o_rdata_next_addr = fillter [63:32] & { 32{ ~R_lsu_wren } } & o_rdata_next_addr_not_filtering;
  //// Encoder //// 
  logic [2:0] sel_mem_output;                  
  always_comb begin 
    case ( R_set_of_access ) 
    8'd1 : sel_mem_output = 3'd0;
    8'd2 : sel_mem_output = 3'd1;
    8'd4 : sel_mem_output = 3'd2;
    8'd8 : sel_mem_output = 3'd3;
    8'd16 : sel_mem_output = 3'd4;
    8'd32 : sel_mem_output = 3'd5;
    8'd64 : sel_mem_output = 3'd6;
    default : sel_mem_output = 3'd7;
    endcase
  end  
  //// MUX 8-1 //// select output from dmem or io ////
  logic [63:0] mux_output;
  always_comb begin 
    case ( sel_mem_output ) 
     3'd0 : mux_output = { o_rdata_next_addr, o_rdata }; 
     3'd1 : mux_output = { 32'd0, o_data_ledr };
     3'd2 : mux_output = { 32'd0, o_data_ledg };
     3'd3 : mux_output = { 32'd0, o_data_led3_0 };
     3'd4 : mux_output = { 32'd0, o_data_led7_4 };
     3'd5 : mux_output = { 32'd0, o_data_lcd };
     3'd6 : mux_output = { 32'd0, o_data_sw };
     3'd7 : mux_output = 64'd0;
   endcase
  end
  //// right shifter ////
  logic [31:0] right_shifter_output;
  Byte_right_shifter_32bit Byte_right_shifter_32bit0 (
    .shifter_input  ( mux_output ),
   .byte_shift      ( R_byte_shift ),
   .shifter_output ( right_shifter_output )
);
/////////////////////////////////////////////
/// load output and signed-extended /////////////////////////////
/////////////////////////////////////////////
  always_comb begin 
    case ( R_funct3 )
      3'b000: o_ld_data [31:8] = { 24{right_shifter_output [7]} };
      3'b001: begin 
        o_ld_data [31:16] = { 16{right_shifter_output [15]} };
        o_ld_data [15:8]  = right_shifter_output [15:8];
      end
      3'b010: o_ld_data [31:8] = right_shifter_output [31:8];
      3'b100: o_ld_data [31:8] = 24'd0;
      3'b101: begin 
        o_ld_data [31:16] = 16'd0;
        o_ld_data [15:8]  = right_shifter_output [15:8];
      end
      default: o_ld_data [31:8] = 24'd0;
    endcase 
  end
  assign o_ld_data [7:0] = right_shifter_output [7:0];
//// end ////
endmodule : lsu 
////////////////////////////
//// END LSU ///////////////
////////////////////////////

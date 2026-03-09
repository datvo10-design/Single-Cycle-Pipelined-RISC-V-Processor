module regfile	(	
    input logic i_clk,                 
    input logic i_rstn,                 
    
    // (Write Port)
    input logic i_rd_wren,            	
    input logic [4:0] i_rd_addr,    	
    input logic [31:0] i_rd_data,    
    
    //  (Read Port 1)
    input logic [4:0] i_rs1_addr,    	 
    output logic [31:0] o_rs1_data,    
    
    //  (Read Port 2)
    input logic [4:0] i_rs2_addr,    
    output logic [31:0] o_rs2_data     	 
);

   logic [31:0] register [31:1];
//// write ////
  always_ff @( posedge i_clk or negedge i_rstn ) begin 
    if ( ~i_rstn ) begin 
      register <= '{default: 0}; 
    end else begin 
      if ( i_rd_wren & ( |i_rd_addr ) ) begin
        register [ i_rd_addr ] <= i_rd_data;
      end
    end
  end
//// read ////
  always_comb begin  
    if ( &(i_rd_addr ~^ i_rs1_addr) & i_rd_wren & ( |i_rd_addr ) ) o_rs1_data = i_rd_data;
    else begin 
      if ( |i_rs1_addr )                          o_rs1_data = register [i_rs1_addr];
      else                                        o_rs1_data = 32'd0;   
    end 
  end
  
  always_comb begin  
    if ( &(i_rd_addr ~^ i_rs2_addr) & i_rd_wren & ( |i_rd_addr ) ) o_rs2_data = i_rd_data;
    else begin 
      if ( |i_rs2_addr )                          o_rs2_data = register [i_rs2_addr];
      else                                        o_rs2_data = 32'd0;   
    end 
  end
endmodule : regfile


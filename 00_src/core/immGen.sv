module immGen(
  input logic [31:0] i_instr,		// mã lệnh nhận được từ imem
  input  logic [2:0]  i_ImmSel,
  
  output logic [31:0] o_imm			// giá trị imm tính được
  
);

// Mặc định luôn gán o_imm = 0 để tránh latch
logic [31:0] imm_val; 		// Ta sẽ dùng 1 tín hiệu trung gian
  always_comb begin 
    case (i_ImmSel)
	   3'b000: imm_val = {{20{i_instr[31]}}, i_instr[31:20]};			//dạng I format, mở rộng bit dấu ra cho đủ 32 bit //
		
		3'b001: imm_val  = {{20{i_instr[31]}}, i_instr[31:20]};            //// load-I format ////
		
		3'b010: imm_val = {{20{i_instr[31]}}, i_instr[31:25], i_instr[11:7]};    //// S format: mở rộng bit dấu và phải ghép bit  ////
		
		3'b011: imm_val= {{19{i_instr[31]}}, i_instr[31], i_instr[7],i_instr[30:25],i_instr[11:8], 1'b0}; 	 	//// B format ////
		
		3'b100: imm_val = {{11{i_instr[31]}}, i_instr[31], i_instr[19:12], i_instr[20],i_instr[30:21],1'b0};	 //// J format ////
		
		3'b101: imm_val = {i_instr [31:12], 12'b0};      //// lui-U format /////
		
		3'b110: imm_val = { i_instr [31:12], 12'b0 };      //// auipc-U format ////
		
	   3'b111: imm_val = {{20{i_instr[31]}}, i_instr[31:20]};   //// jalr-I format ////
		
      default : imm_val = 32'd0;
    endcase		
  end
  // Gán giá trị ra output
    assign o_imm = imm_val;
endmodule
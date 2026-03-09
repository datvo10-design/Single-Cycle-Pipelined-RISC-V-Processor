  module EX_MEM_alu_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input từ tầng EX, kết quả của bộ alu
		input  logic [31:0] i_alu_result,      // pc hiện tại
	 
    // output sang cổng addr của dmem HOẶC đi thẳng sang WB
		output logic [31:0] o_alu_result		
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_alu_result <= 32'b0;							// Khi Reset (Mức thấp)
        end 
		  
        else if (i_flush) begin
			o_alu_result <= 32'b0;		// Flush xóa lệnh, đoán sai thì xóa lệnh
																
        end 
		  
        else if (i_stall) begin
			o_alu_result <= o_alu_result;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_alu_result <= i_alu_result; 	// Bình thường: cập nhật kết quả mới từ alu
        end
    end

endmodule
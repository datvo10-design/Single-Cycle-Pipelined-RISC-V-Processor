  module MEM_WB_alu_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input từ tầng MEM
		input  logic [31:0] i_alu_result,		// Kết quả lấy từ EX_MEM_alu_reg truyền sang
	 
    // output sang tầng MEM
		output logic [31:0] o_alu_result		// // Đi vào bộ MUX Writeback
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_alu_result <= 32'b0;							// Khi Reset (Mức thấp): 
        end 
		  
        else if (i_flush) begin
			o_alu_result <= 32'b0;		// Flush xóa lệnh, đoán sai thì xóa lệnh
																
        end 
		  
        else if (i_stall) begin
			o_alu_result <= o_alu_result;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_alu_result <= i_alu_result;		// Bình thường: cập nhật giá trị alu
        end
    end

endmodule
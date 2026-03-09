module ID_EX_inst_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // dữ liệu input từ tầng ID, Lấy từ thanh ghi IF_ID_inst_reg ra
		input  logic [31:0] i_inst,      // Lệnh gốc 32-bit
	 
    // dữ liệu output sang tầng EX
		output logic [31:0] o_inst			// Lệnh tại tầng EX (inst_EX)
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_inst <= 32'b0;							// Khi Reset (Mức thấp): Đưa về lệnh NOP (addi x0, x0, 0) 
        end 
		  
        else if (i_flush) begin
			o_inst <= 32'b0;			// Flush xóa lệnh, đoán sai thì xóa lệnh
																
        end 
		  
        else if (i_stall) begin
			o_inst <= o_inst;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_inst <= i_inst;			// Bình thường: cập nhật lệnh mới
        end
    end

endmodule
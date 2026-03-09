// cơ bản giống hệt rs1 nhưng có thêm chức năng là làm dữ liệu để GHI (Store)

module ID_EX_imm_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // dữ liệu input từ tầng ID 
		input  logic [31:0] i_imm,      // Giá trị tức thời (đã sign-extended 32-bit)
	 
    // dữ liệu output sang tầng EX
		output logic [31:0] o_imm
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_imm <= 32'b0;							// Khi Reset (Mức thấp): Xóa mọi thứ   
        end 
		  
        else if (i_flush) begin
			o_imm <= 32'b0;			// Flush xóa lệnh, Khi lệnh bị hủy thì giá trị imm không còn ý nghĩa
																
        end 
		  
        else if (i_stall) begin
			o_imm <= o_imm;			// Stall (Do Load-Use Hazard): Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_imm <= i_imm;			// Bình thường: cập nhật dữ liệu từ khối regfile tầng ID
        end
    end

endmodule
module EX_MEM_pc_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input từ tầng EX, Lấy từ thanh ghi IF_ID_inst_reg ra
		input  logic [31:0] i_pc_ex,      // pc hiện tại
	 
    // output sang tầng MEM
		output logic [31:0] o_pc_mem		
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_pc_mem <= 32'b0;							// Khi Reset (Mức thấp)
        end 
		  
        else if (i_flush) begin
			o_pc_mem <= 32'b0;		// Flush xóa lệnh, đoán sai thì xóa lệnh
																
        end 
		  
        else if (i_stall) begin
			o_pc_mem <= o_pc_mem;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_pc_mem <= i_pc_ex;		// Bình thường: cập nhật pc từ ex sang mem
        end
    end

endmodule
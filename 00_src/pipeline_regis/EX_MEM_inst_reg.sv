  module EX_MEM_inst_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input từ tầng EX, Lấy từ thanh ghi ID_EX_inst_reg	 ra
		input  logic [31:0] i_inst,     
	 
    // output sang tầng MEM
		output logic [31:0] o_inst
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_inst <= 32'b0;							// Khi Reset (Mức thấp): hủy lệnh
        end 
		  
        else if (i_flush) begin
			o_inst <= 32'b0;		// Flush xóa lệnh nếu branch sai
																
        end 
		  
        else if (i_stall) begin
			o_inst <= o_inst;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_inst <= i_inst;		// Bình thường: truyền lệnh từ ex sang mem
        end
    end

endmodule
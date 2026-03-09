  module MEM_WB_pc4_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input từ tầng MEM
		input  logic [31:0] i_pc_add_4,		// Kết quả của bộ cộng (PC + 4) ở tầng MEM
	 
    // output sang tầng MEM
		output logic [31:0] o_pc_add_4		// // Đi vào bộ MUX Writeback
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_pc_add_4 <= 32'b0;							// Khi Reset (Mức thấp): 
        end 
		  
        else if (i_flush) begin
			o_pc_add_4 <= 32'b0;		// Flush xóa lệnh, đoán sai thì xóa lệnh
																
        end 
		  
        else if (i_stall) begin
			o_pc_add_4 <= o_pc_add_4;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_pc_add_4 <= i_pc_add_4;		// Bình thường: cập nhật pc +4 mơis
        end
    end

endmodule
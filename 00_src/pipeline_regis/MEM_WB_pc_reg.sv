module MEM_WB_pc_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input từ tầng MEM
		input  logic [31:0] i_pc_mem,      // pc hiện tại
	 
    // output sang tầng WB
		output logic [31:0] o_pc_wb		
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_pc_wb <= 32'b0;							// Khi Reset (Mức thấp)
        end 
		  
        else if (i_flush) begin
			o_pc_wb <= 32'b0;		// Flush xóa lệnh, đoán sai thì xóa lệnh
																
        end 
		  
        else if (i_stall) begin
			o_pc_wb <= o_pc_wb;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_pc_wb <= i_pc_mem;		// Bình thường: cập nhật pc từ ex sang mem
        end
    end

endmodule
  module EX_MEM_rs2_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input từ tầng EX, Đây phải là dữ liệu rs2 mới nhất, lấy từ bộ mux forwarding B, kh đc lấy từ ID_EX_rs2_reg
		input  logic [31:0] i_rs2_data,
	 
    // output sang tầng MEM
		output logic [31:0] o_rs2_data	
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_rs2_data <= 32'b0;							// Khi Reset (Mức thấp)
        end 
		  
        else if (i_flush) begin
			o_rs2_data <= 32'b0;		// Flush xóa lệnh, đoán sai thì xóa lệnh
																
        end 
		  
        else if (i_stall) begin
			o_rs2_data <= o_rs2_data;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_rs2_data <= i_rs2_data;		// Bình thường: cập nhật giá trị rs2 từ EX
        end
    end

endmodule
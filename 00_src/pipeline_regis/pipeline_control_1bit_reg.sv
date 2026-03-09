module pipeline_control_1bit_reg (
    input logic i_clk,
    input logic i_reset,
    
    // control
    input  logic i_flush, 		// Xóa về 0 (NOP)
    input  logic i_stall, 		// Giữ nguyên
    
    // Data
    input  logic i_data,  	// Tín hiệu điều khiển vào
    output logic o_data   	// Tín hiệu điều khiển ra
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
            o_data <= '0; 			// reset về 0 hết
        end
		  
        else if (i_flush) begin
            o_data <= '0; 			// Flush thì xóa tín hiệu điều khiển (biến thành NOP)
        end
		  
        else if (i_stall) begin
            o_data <= o_data; 			// Stall thì giữ nguyên tín hiệu
        end
        else begin
            o_data <= i_data; 			// Bình thường thì cập nhật tín hiệu mới
        end
    end

endmodule
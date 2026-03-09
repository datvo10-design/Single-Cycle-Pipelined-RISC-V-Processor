module pipe_control_2_bit_reg (
    input logic i_clk,
    input logic i_reset,
    
    // control
    input  logic i_flush, 		// Xóa về 0 (NOP)
    input  logic i_stall, 		// Giữ nguyên
    
    // Data
    input logic [1:0] in_data,  	// Tín hiệu điều khiển vào 4 bit
    output logic [1:0] out_data   	// Tín hiệu điều khiển ra 4 bit
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
            out_data <= '0; 			// reset về 0 hết
        end
		  
        else if (i_flush) begin
            out_data <= '0; 			// Flush thì xóa tín hiệu điều khiển (biến thành NOP)
        end
		  
        else if (i_stall) begin
            out_data <= out_data; 			// Stall thì giữ nguyên tín hiệu
        end
        else begin
            out_data <= in_data; 			// Bình thường thì cập nhật tín hiệu mới
        end
    end

endmodule
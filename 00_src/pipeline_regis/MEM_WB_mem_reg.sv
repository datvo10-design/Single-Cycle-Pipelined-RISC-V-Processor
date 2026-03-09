  module MEM_WB_mem_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input từ tầng MEM
		input  logic [31:0] i_mem_data,		//Dữ liệu đọc được từ dmem
	 
    // output sang tầng MEM
		output logic [31:0] o_mem_data		// Đi vào bộ MUX Writeback
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_mem_data <= 32'b0;						// Khi Reset (Mức thấp): 
        end 
		  
        else if (i_flush) begin
			o_mem_data <= 32'b0;		// Flush xóa lệnh, đoán sai thì xóa lệnh
																
        end 
		  
        else if (i_stall) begin
			o_mem_data <= o_mem_data;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_mem_data <= i_mem_data;		// Bình thường: cập nhật dữ liệu đọc từ dmem
        end
    end

endmodule
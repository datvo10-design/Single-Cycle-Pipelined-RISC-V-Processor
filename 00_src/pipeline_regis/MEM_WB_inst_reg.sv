  module MEM_WB_inst_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input từ tầng MEM
		input  logic [31:0] i_inst,		// lấy từ EX_MEM_inst_reg
	 
    // output sang tầng MEM
		output logic [31:0] o_inst		// Đi vào bộ MUX Writeback
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_inst <= 32'b0;						// Khi Reset (Mức thấp): reset lệnh
        end 
		  
        else if (i_flush) begin
			o_inst <= 32'b0;		// Flush xóa lệnh, đoán sai thì xóa lệnh
																
        end 
		  
        else if (i_stall) begin
			o_inst <= o_inst;			// Stall Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_inst <= i_inst;		// Bình thường: cập nhật 
        end
    end

endmodule
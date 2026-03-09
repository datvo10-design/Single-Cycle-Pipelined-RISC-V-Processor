// Giai đoạn này đơn giản nhất, chỉ cần ném thông tin thô vào để tầng sau giải mã.
module IF_ID_instr_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

	 input  logic [31:0] instr_in,		// lệnh lấy từ imem (Từ tầng Ins Fetch)
    output logic [31:0] instr_out

);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
		instr_out <= 32'b0;		// Khi Reset (Mức thấp): Xóa mọi thứ
        end 
		  
        else if (i_flush) begin
		instr_out <= 32'b0;					// Flush (Do đoán sai nhánh): Biến lệnh thành NOP
																// PC không quan trọng vì lệnh NOP không ghi gì cả
        end 
		  
        else if (i_stall) begin
		instr_out <= instr_out;					// Stall (Do Load-Use Hazard): Giữ nguyên giá trị cũ
        end 
		  
        else begin
		instr_out <= instr_in;						// Bình thường: Cập nhật giá trị mới từ tầng IF
        end
    end

endmodule
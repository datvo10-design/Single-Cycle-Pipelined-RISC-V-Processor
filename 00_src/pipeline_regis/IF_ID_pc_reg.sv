// Giai đoạn này đơn giản nhất, chỉ cần ném thông tin thô vào để tầng sau giải mã.
module IF_ID_pc_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // DỮ LIỆU ĐẦU VÀO (Từ tầng Ins Fetch)
    input  logic [31:0] pc_current_in,		// Địa chỉ PC hiện tại của lệnh (Dùng để tính offset nếu là lệnh Branch/Jump).


    // DỮ LIỆU ĐẦU RA (Sang tầng Ins Decode)
    output logic [31:0] pc_current_out
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
																// Khi Reset (Mức thấp): Xóa mọi thứ
            pc_current_out   <= 32'b0;
        end 
        else if (i_flush) begin
				pc_current_out   <= 32'b0; 			// Flush (Do đoán sai nhánh): Biến lệnh thành NOP
																// PC không quan trọng vì lệnh NOP không ghi gì cả
        end 
		  
        else if (i_stall) begin
																// Stall (Do Load-Use Hazard): Giữ nguyên giá trị cũ
            pc_current_out   <= pc_current_out;
        end 
		  
        else begin
			pc_current_out   <= pc_current_in;		// Bình thường: Cập nhật giá trị mới từ tầng IF 
        end
    end

endmodule
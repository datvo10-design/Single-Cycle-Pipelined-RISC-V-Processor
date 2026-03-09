module ID_EX_pc_reg (
    input logic i_clk,
    input logic i_reset,      // reset active low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // input Từ tầng ID
    input  logic [31:0] pc_current_in,		// Địa chỉ PC hiện tại (Dùng để tính offset nếu là lệnh Branch/Jump).

    // output Sang tầng EX
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
																// Bình thường: chuyển PC sang tầng EX
            pc_current_out   <= pc_current_in;
        end
    end

endmodule
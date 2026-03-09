// cơ bản giống hệt rs1 nhưng có thêm chức năng là làm dữ liệu để GHI (Store)

module ID_EX_rs2_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // DỮ LIỆU ĐẦU VÀO (Từ tầng ID )
    input  logic [31:0] i_rs2_data, // Giá trị đọc được từ RegFile 	
//	 input  logic [4:0]  i_rs2_addr, // Địa chỉ thanh ghi rs2 ( quan trọng cho FORWARDING)
								// tại EX, cái o_rs2_addr này đc đưa vào bộ Forwarding Unit. Nếu nó trùng với địa chỉ đích (rd) của các lệnh phía 
								// trước (đang ở MEM hoặc WB), thì phải lấy dữ liệu mới nhất chứ không dùng cái o_rs2_data cũ  này.
	 
    // DỮ LIỆU ĐẦU RA (Sang tầng EX)
    output logic [31:0] o_rs2_data
//	 output logic [4:0]  o_rs2_addr	// (FORWARDING)
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_rs2_data <= 32'b0;
//         o_rs2_addr <= 5'b0;													// Khi Reset (Mức thấp): Xóa mọi thứ   
        end 
		  
        else if (i_flush) begin
				o_rs2_data <= 32'b0;
//            o_rs2_addr <= 5'b0;			// Flush xóa lệnh đang thực thi dở
																// PC không quan trọng vì lệnh NOP không ghi gì cả
        end 
		  
        else if (i_stall) begin
				o_rs2_data <= o_rs2_data;
//            o_rs2_addr <= o_rs2_addr;				// Stall (Do Load-Use Hazard): Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_rs2_data <= i_rs2_data;
//         o_rs2_addr <= i_rs2_addr;				// Bình thường: cập nhật dữ liệu từ khối regfile tầng ID
        end
    end

endmodule
module ID_EX_rs1_reg (
    input logic i_clk,
    input logic i_reset,      // reset Active Low
    
    // Tín hiệu điều khiển từ Hazard Unit
    input logic i_stall,      // 1 = Giữ nguyên (Pause)
    input logic i_flush,      // 1 = Xóa lệnh (Clear/Bubble)

    // DỮ LIỆU ĐẦU VÀO (Từ tầng ID )
    input  logic [31:0] i_rs1_data, // Giá trị đọc được từ RegFile 	
//	 input  logic [4:0]  i_rs1_addr, // Địa chỉ thanh ghi rs1 ( tuần 1 chưa cần nhưng quan trọng cho FORWARDING)
									// bộ Forwarding Control Logic cần đầu vào là rs1_EX (chính là o_rs1_addr) để so sánh với rd_MEM và rd_WB.
	 
    // DỮ LIỆU ĐẦU RA (Sang tầng EX)
    output logic [31:0] o_rs1_data
//	 output logic [4:0]  o_rs1_addr	// (FORWARDING) tuần 1 chưa cần
);

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
			o_rs1_data <= 32'b0;
//         o_rs1_addr <= 5'b0;													// Khi Reset (Mức thấp): Xóa mọi thứ   
        end 
		  
        else if (i_flush) begin
				o_rs1_data <= 32'b0;
//            o_rs1_addr <= 5'b0;			// Flush (Do đoán sai nhánh): Biến lệnh thành NOP
																// PC không quan trọng vì lệnh NOP không ghi gì cả
        end 
		  
        else if (i_stall) begin
				o_rs1_data <= o_rs1_data;
//            o_rs1_addr <= o_rs1_addr;				// Stall (Do Load-Use Hazard): Giữ nguyên giá trị cũ
        end 
		  
        else begin
			o_rs1_data <= i_rs1_data;
 //        o_rs1_addr <= i_rs1_addr;				// Bình thường: cập nhật dữ liệu từ khối regfile tầng ID
        end
    end

endmodule
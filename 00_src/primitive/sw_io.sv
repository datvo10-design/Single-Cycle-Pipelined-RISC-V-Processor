module sw_io (
    input logic          i_clk,
    input logic          i_reset,
    input logic          i_access_en,
    input logic [31:0]   i_sw_external, // Đổi tên: Đây là tín hiệu từ công tắc vật lý
    input logic [3:0]    i_bmask,       // CPU muốn đọc byte nào?
    output logic [31:0]  o_data_sw      // Dữ liệu trả về cho CPU
);

    logic [31:0] sw_synchronizer; // Thanh ghi đồng bộ hóa

    always_ff @( posedge i_clk or negedge i_reset ) begin 
        if ( ~i_reset ) begin 
            sw_synchronizer <= 32'd0;
            o_data_sw       <= 32'd0; // [SỬA LỖI] Reset cả output
        end else begin 
            // Bước 1: Đồng bộ hóa tín hiệu từ bên ngoài (Chống Metastability)
            // Tín hiệu Switch vật lý thường bị rung và không đồng bộ với Clock
            sw_synchronizer <= i_sw_external;

            // Bước 2: Logic Đọc (Read Logic)
            // Chỉ trả về dữ liệu nếu được phép truy cập (access_en = 1)
            // Logic này tạo ra độ trễ tổng cộng là 2 chu kỳ (An toàn cho IO)
            if (i_access_en) begin
                o_data_sw [7:0]   <= i_bmask[0] ? sw_synchronizer [7:0]   : 8'b0;
                o_data_sw [15:8]  <= i_bmask[1] ? sw_synchronizer [15:8]  : 8'b0;
                o_data_sw [23:16] <= i_bmask[2] ? sw_synchronizer [23:16] : 8'b0;
                o_data_sw [31:24] <= i_bmask[3] ? sw_synchronizer [31:24] : 8'b0;
            end else begin
                o_data_sw <= 32'd0; // Trả về 0 khi không được chọn
            end
        end
    end

endmodule

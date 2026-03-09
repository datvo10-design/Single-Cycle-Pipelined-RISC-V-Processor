// module chính
// Lưu ý bit nhớ cuối cùng C_o gọi là bit không mượn, 
// nếu A - B > 0 -> A > B thì C_o = 1, nếu A - B < 0 -> A < B thì C_o = 0
// ta sẽ sử dụng lại bộ trừ 32 bit, lưu ý trong bộ sltu không cần dùng kết quả của bộ trừ (SUB) nhưng vẫn phải nối dây đủ mạch mới hoạt động đc
// Theo bảng mã lệnh, nếu A < B thì ngõ ra Result = 1, nếu A > B thì Result = 0 --> Result = ~C_o
module sltu_32bit (
    input  logic [31:0] A,
    input  logic [31:0] B,
    output logic Result
);
    logic [31:0] SUB_o; // khai báo ngõ ra kết quả bộ trừ nhưng sẽ không cần dùng đến 
    logic        C_out;   // Đây là tín hiệu C_o 

    // Gọi bộ trừ 32-bit ra và tiến hành nối chân để tạo bộ sltu
    sub_32bit sltu_zz ( .A( A ), .B( B ), .SUB( SUB_o ),  .C_o( C_out ));      // Lấy tín hiệu not-borrow ra

    // Kết quả SLTU là phủ định của bit C_out
    assign Result = ~C_out;

endmodule
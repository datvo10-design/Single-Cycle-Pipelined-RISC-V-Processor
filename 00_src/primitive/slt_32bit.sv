// module chính
// so với SLTU thù SLT không cần sử dụng bit C_o
// nếu A - B > 0 -> A > B thì C_o = 1, nếu A - B < 0 -> A < B thì C_o = 0
// ta sẽ sử dụng lại bộ trừ 32 bit
// Theo bảng mã lệnh, nếu A < B thì ngõ ra Result = 1, nếu A > B thì Result = 0 --> Result = ~C_o

module slt_32bit (
    input  logic [31:0] A,
    input  logic [31:0] B,
	 output logic Result
);
    logic [31:0] SUB_o; // khai báo ngõ ra kết quả bộ trừ 
	 logic        C_out;   // Dây C_out (không dùng cho logic slt, nhưng vẫn phải nối)

    // Gọi bộ trừ 32-bit ra và tiến hành nối chân để tạo bộ sltu
    sub_32bit sltu_zz ( .A( A ), .B( B ), .SUB( SUB_o ), .C_o(C_out));    // Nối C_o vào đây (dù không dùng);// Lấy tín hiệu not-borrow ra

    // Kết quả SLTU là Result sẽ dựa vào bit dấu của A, B và SUB
	 // với SLT: A < B sẽ đúng (sltu=1) trong 2 trường hợp là:
// 1. A là số âm (A[31]=1) và B là số dương (B[31]) = 0 --> A[31] & ~B[31] = 1
// 2. 2 số A và B cùng dấu A[31]=B[31] và SUB = A - B < 0 (SUB[31] = 1) --> ( A[31] ^ ~B[31] ) & SUB[31] = 0 | 1 = 1
    assign Result = ((A[31] & (~B[31])) | ((A[31] ^ (~B[31])) & SUB_o[31]));

endmodule
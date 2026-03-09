/* phương pháp là xây dựng một bộ so sánh 32-bit có cấu trúc phân cấp (hierarchical), 
sau đó dùng nó để tạo ra một Khối So sánh Nhánh (Branch Comparison Unit - BRC) cho CPU 
Ta bắt đầu với khối so sánh 2 bit không dấu trước, sau đó lần lượt tạo khối so sánh 8,16 và 32 bit
Ta chia ra làm hai nửa: so sánh 16 bit cao: A[31:16] với B[31:16] và so sánh 2 bit thấp: A[31:16] với B[31:16] rồi kết hợp kết quả lại
*/
	
module brc_32bit (
  input logic [31:0] i_rs1_data,
  input logic [31:0] i_rs2_data,
  input logic        i_br_un,			// ngõ vào lựa chọn, 1 là so sánh có dấu, 0 là so sánh không dấu
  output logic       o_br_less,		// ngõ ra A < B
  output logic       o_br_equal		// ngõ ra A = B
);
  logic [1:0] EQ;                                                  // ngõ ra bằng của bộ so sánh 16 bit: 16-bit comparator //
  logic [1:0] LT;                                                  // ngõ ra bé hơn của bộ so sánh 16 bit: 16-bit comparator //
  // Bắt đầu so sánh bằng
  assign      o_br_equal  = EQ [1] & EQ [0];								// A = B nếu cả 16 bit cao và 16 bit thấp của A và B đều giống nhau
                   
  // bắt đầu so sánh bé hơn
  logic unsigned_less_than;   				
  logic signed_less_than;  
  
  // Kết quả so sánh không dấu
  assign unsigned_less_than = LT[1] | (EQ[1] & LT[0]);	// A < B nếu 16 bit cao của A < B HOẶC 16 bit cao của A = B VÀ 16 bit thấp của A < B
  
	// Kết quả so sánh có dấu
	assign signed_less_than = (i_rs1_data[31] & ~i_rs2_data[31]) | (~(i_rs1_data[31] ^ i_rs2_data[31]) & unsigned_less_than);
				// A < B trong 2 TH: 
				// TH 1 là bit thứ 31 của A = 1 (A là số âm) VÀ bit thứ 31 của B = 0 (B là số dương)
				// TH 2 là A và B có cùng dấu (cùng âm hoặc cùng dương) VÀ khi so sánh chúng như hai số không dấu thì A nhỏ hơn B
				// ( ~(i_rs1_data[31] ^ i_rs2_data[31]): Đây là phép XNOR, nó bằng 1 khi hai bit dấu giống nhau --> cùng âm, cùng dương
// unsigned_less_than là kết quả của phép so sánh không dấu
// LƯU Ý VÌ KHI 2 SỐ A VÀ B ĐÃ CÓ DÙNG DẤU RỒI THÌ VIỆC SO SÁNH CHÚNG CŨNG TƯƠNG TỰ NHƯ SO SÁNH 2 SỐ KHÔNG DẤU
// VÍ DỤ A = -5 = 1011 VÀ B = -2 = 1110, ta đưa về so sánh không dấu --> 1011 = 11 và 1110 = 14 --> -5 < -2 			
  
  always_comb begin  // 2-1 Mux //
    if ( i_br_un ) 	// Nếu i_br_un = 1, chọn KẾT QUẢ CÓ DẤU, i_br_un =  0 thì chọn kq không dấu
	 o_br_less = unsigned_less_than;
    else                     
	 o_br_less = signed_less_than;
  end
  
Comparator_16bits Comparator_16bits1 (
  .A      ( i_rs1_data [31:16] ),
  .B      ( i_rs2_data [31:16] ),
  .A_lt_B ( LT [1] ),
  .A_eq_B ( EQ [1] )
);
Comparator_16bits Comparator_16bits0 (
  .A      ( i_rs1_data [15:0] ),
  .B      ( i_rs2_data [15:0] ),
  .A_lt_B ( LT [0] ),
  .A_eq_B ( EQ [0] )
);
endmodule: brc_32bit



///////////////////////////
//// 2-bits Comparator: Đây là "viên gạch" cơ bản nhất, so sánh 2 số 2-bit.
// Cách hoạt động của A_eq_B: 2 số 2-bit A=A1A0 và B=B1B0 bằng nhau khi và chỉ khi tất cả các bit tương ứng của chúng bằng nhau.
// Phép so sánh 2 bit bằng nhau (==) trong phần cứng chính là cổng XNOR. Cổng XNOR sẽ cho ra 1 nếu 2 bit vào giống nhau.
// assign A_xnor_B = ~ ( A ^ B); có nghĩa là A_xnor_B[1] sẽ bằng 1 nếu A[1] == B[1] và A_xnor_B[0] sẽ bằng 1 nếu A[0] == B[0]
/* assign A_eq_B = A_xnor_B [1] & A_xnor_B [0] nghĩa là A và B sẽ bằng nhau khi cả A_xnor_B[1] và A_xnor_B[0] đều bằng 1,*/
// Cách hoạt động của ngõ ra A_lt_B: A < B nếu1 trong 2 TH sau xảy ra: 
// Trường hợp 1: Bit cao của A nhỏ hơn bit cao của B: (~A[1]) & B[1]
// Trường hợp 2: Bit cao của A bằng bit cao của B, VÀ bit thấp của A nhỏ hơn bit thấp của B: (~(A[1] ^ B[1])) & ((~A[0]) & B[0])

module Comparator_2bits (
  input logic [1:0] A,
  input logic [1:0] B,
  output logic      A_lt_B, // A nhỏ hơn B //
  output logic      A_eq_B  // A bằng B //
);
  logic [1:0] A_xnor_B;
  assign      A_xnor_B = ~ ( A ^ B);
  assign A_lt_B = ( (~ A [1] ) & B [1]) | (~(A[1] ^ B[1]) & (~A[0] & B[0]));
  
  assign A_eq_B = A_xnor_B [1] & A_xnor_B [0];
endmodule : Comparator_2bits



///////////////////////////
//// 4-bits Comparator: dùng 2 khối Comparator_2bits để xây dựng một khối 4-bit.
// Khối này thiết kế theo kiểu phân cấp (hierarchical design). Thay vì so sánh 4 bit cùng lúc bằng một hàm logic
// ta chia  ra làm hai: so sánh 2 bit cao: A[3:2] và B[3:2] và so sánh 2 bit thấp: A[1:0] và B[1:0] rồi kết hợp kết quả lại
///////////////////////////
module Comparator_4bits (
  input logic [3:0] A,
  input logic [3:0] B,
  output logic      A_lt_B, // A nhỏ hơn B //
  output logic      A_eq_B  // A bằng B //
);
  logic [1:0] EQ; 													// "Equal" output for each 2-bit comparator //
  logic [1:0] LT; 													// "Less than" output for each 2-bit comparator  //
  assign      A_lt_B = LT [1] | ( EQ [1] & LT [0] );		/* Logic so sánh nhỏ hơn: A < B nếu 2 bit cao của A < B HOẶC 		
																			   2 bit cao của A = B VÀ 2 bit thấp của A < B */ 
  assign      A_eq_B = EQ [1] & EQ [0];						// Logic so sánh bằng: A = B nếu 2 bit cao và 2 bit thấp của cả 2 bằng nhau
Comparator_2bits Comparator_2bits1 (				// tạo khối so sánh dùng Comparator_2bits tên là Comparator_2bits1 để so sánh 2 bit cao
  .A      ( A [3:2] ),
  .B      ( B [3:2] ),
  .A_lt_B ( LT [1] ),
  .A_eq_B ( EQ [1] )
);
Comparator_2bits Comparator_2bits0 (				// tạo khối so sánh dùng Comparator_2bits tên là Comparator_2bits1 để so sánh 2 bit thấp
  .A      ( A [1:0] ),
  .B      ( B [1:0] ),
  .A_lt_B ( LT [0] ),
  .A_eq_B ( EQ [0] )
);
endmodule : Comparator_4bits

///////////////////////////
//// 8-bits Comparator bằng cách Dùng 2 khối Comparator_4bits làm tương tự khối 4 bit
//  ta chia  ra làm hai: so sánh 4 bit cao: A[7:4] và B[7:4] và so sánh 2 bit thấp: A[3:0] và B[3:0] rồi kết hợp kết quả lại
///////////////////////////
module Comparator_8bits (
  input logic [7:0] A,
  input logic [7:0] B,
  output logic      A_lt_B, // A less than B //
  output logic      A_eq_B  // A equal B //
);
  logic [1:0] EQ; // "Equal" output for each 4-bit comparator //
  logic [1:0] LT; // "Less than" output for each 4-bit comparator  //
  assign      A_lt_B = LT [1] | ( EQ [1] & LT [0] );
  assign      A_eq_B = EQ [1] & EQ [0];
Comparator_4bits Comparator_4bits1 (
  .A      ( A [7:4] ),
  .B      ( B [7:4] ),
  .A_lt_B ( LT [1] ),
  .A_eq_B ( EQ [1] )
);
Comparator_4bits Comparator_4bits0 (
  .A      ( A [3:0] ),
  .B      ( B [3:0] ),
  .A_lt_B ( LT [0] ),
  .A_eq_B ( EQ [0] )
);
endmodule : Comparator_8bits

////////////////////////////
//// 16-bits Comparator: dùng 2 khối Comparator_8bits làm tương tự
// ta chia  ra làm hai: so sánh 8 bit cao: A[15:8] và B[15:8] và so sánh 2 bit thấp: A[7:0] và B[7:0] rồi kết hợp kết quả lại
////////////////////////////
module Comparator_16bits (
  input logic [15:0] A,
  input logic [15:0] B,
  output logic      A_lt_B, // A less than B //
  output logic      A_eq_B  // A equal B //
);
  logic [1:0] EQ; // "Equal" output for each 8-bit comparator //
  logic [1:0] LT; // "Less than" output for each 8-bit comparator  //
  assign      A_lt_B = LT [1] | ( EQ [1] & LT [0] );
  assign      A_eq_B = EQ [1] & EQ [0];
Comparator_8bits Comparator_8bits1 (
  .A      ( A [15:8] ),
  .B      ( B [15:8] ),
  .A_lt_B ( LT [1] ),
  .A_eq_B ( EQ [1] )
);
Comparator_8bits Comparator_8bits0 (
  .A      ( A [7:0] ),
  .B      ( B [7:0] ),
  .A_lt_B ( LT [0] ),
  .A_eq_B ( EQ [0] )
);
endmodule : Comparator_16bits



// de co bo tru 32 bit, ta se dung quy tac A - B = A + B' + 1
// suy ra bit nho C_i = 1 va ngo vao B phai dua qua cong NOT
// đầu tiên là thiết kế bộ cộng FA 1 bit

	
	
// Giờ ta sẽ ghép chung 32 bộ cộng FA để tạo thành bộ cộng FA 32 bit
module sub_32bit (
	input logic [31:0] A,
	input logic [31:0] B,
	output logic [31:0] SUB,
	output logic C_o
	);
	// C1 đến C31 là bit nhớ từ cột sau gửi tới cột trước, xem lại KTS là thấy
	logic C1,C2,C3,C4,C5,C6,C7,C8,C9,C10,C11,C12,C13,C14,C15,C16,C17,C18,C19,C20,C21,C22,
			C23,C24,C25,C26,C27,C28,C29,C30,C31,C_out;

	
	// nối chân 32 khối FA
	// Lưu ý trong phép trừ thì bit nhớ đầu tiên luôn là 1 (C_in = 1'b1)
	// toàn bộ ngõ vào B phải đưa qua cổng NOT nên code là: .y (~B[0]),....
		full_adder bit_0 (.x (A[0]), .y (~B[0]), .z (1'b1), .S_o (SUB[0]), .C_o (C1));
		full_adder bit_1 (.x (A[1]), .y (~B[1]), .z (C1), .S_o (SUB[1]), .C_o (C2));
		full_adder bit_2 (.x (A[2]), .y (~B[2]), .z (C2), .S_o (SUB[2]), .C_o (C3));
		full_adder bit_3 (.x (A[3]), .y (~B[3]), .z (C3), .S_o (SUB[3]), .C_o (C4));
		full_adder bit_4  (.x(A[4]),  .y(~B[4]), .z(C4), .S_o(SUB[4]),  .C_o(C5));
		full_adder bit_5  (.x(A[5]),  .y(~B[5]), .z(C5), .S_o(SUB[5]),  .C_o(C6));
		 full_adder bit_6  (.x(A[6]),  .y(~B[6]), .z(C6), .S_o(SUB[6]),  .C_o(C7));
		 full_adder bit_7  (.x(A[7]),  .y(~B[7]), .z(C7), .S_o(SUB[7]),  .C_o(C8));
		 full_adder bit_8  (.x(A[8]),  .y(~B[8]), .z(C8), .S_o(SUB[8]),  .C_o(C9));
		 full_adder bit_9  (.x(A[9]),  .y(~B[9]), .z(C9),   .S_o(SUB[9]),  .C_o(C10));
		 full_adder bit_10 (.x(A[10]), .y(~B[10]), .z(C10),  .S_o(SUB[10]), .C_o(C11));
		 full_adder bit_11 (.x(A[11]), .y(~B[11]), .z(C11),  .S_o(SUB[11]), .C_o(C12));
		 full_adder bit_12 (.x(A[12]), .y(~B[12]), .z(C12),  .S_o(SUB[12]), .C_o(C13));
		 full_adder bit_13 (.x(A[13]), .y(~B[13]), .z(C13),  .S_o(SUB[13]), .C_o(C14));
		 full_adder bit_14 (.x(A[14]), .y(~B[14]), .z(C14),  .S_o(SUB[14]), .C_o(C15));
		 full_adder bit_15 (.x(A[15]), .y(~B[15]), .z(C15),  .S_o(SUB[15]), .C_o(C16));
		 full_adder bit_16 (.x(A[16]), .y(~B[16]), .z(C16),  .S_o(SUB[16]), .C_o(C17));
		 full_adder bit_17 (.x(A[17]), .y(~B[17]), .z(C17),  .S_o(SUB[17]), .C_o(C18));
		 full_adder bit_18 (.x(A[18]), .y(~B[18]), .z(C18),  .S_o(SUB[18]), .C_o(C19));
		 full_adder bit_19 (.x(A[19]), .y(~B[19]), .z(C19),  .S_o(SUB[19]), .C_o(C20));
		 full_adder bit_20 (.x(A[20]), .y(~B[20]), .z(C20),  .S_o(SUB[20]), .C_o(C21));
		 full_adder bit_21 (.x(A[21]), .y(~B[21]), .z(C21),  .S_o(SUB[21]), .C_o(C22));
		 full_adder bit_22 (.x(A[22]), .y(~B[22]), .z(C22),  .S_o(SUB[22]), .C_o(C23));
		 full_adder bit_23 (.x(A[23]), .y(~B[23]), .z(C23),  .S_o(SUB[23]), .C_o(C24));
		 full_adder bit_24 (.x(A[24]), .y(~B[24]), .z(C24),  .S_o(SUB[24]), .C_o(C25));
		 full_adder bit_25 (.x(A[25]), .y(~B[25]), .z(C25),  .S_o(SUB[25]), .C_o(C26));
		 full_adder bit_26 (.x(A[26]), .y(~B[26]), .z(C26),  .S_o(SUB[26]), .C_o(C27));
		 full_adder bit_27 (.x(A[27]), .y(~B[27]), .z(C27),  .S_o(SUB[27]), .C_o(C28));
		 full_adder bit_28 (.x(A[28]), .y(~B[28]), .z(C28),  .S_o(SUB[28]), .C_o(C29));
		 full_adder bit_29 (.x(A[29]), .y(~B[29]), .z(C29),  .S_o(SUB[29]), .C_o(C30));
		 full_adder bit_30 (.x(A[30]), .y(~B[30]), .z(C30),  .S_o(SUB[30]), .C_o(C31));
		 full_adder bit_31 (.x(A[31]), .y(~B[31]), .z(C31),  .S_o(SUB[31]), .C_o(C_out));
		 assign C_o = C_out;
	endmodule: sub_32bit
	
	
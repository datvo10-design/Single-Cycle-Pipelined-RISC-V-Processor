module xor_1bit (
	input logic A_i,
	input logic B_i,
	output logic C_o
	);
	assign C_o = A_i ^ B_i;
	endmodule: xor_1bit


	 
module xor_32bit (
	input logic [31:0] A,
	input logic [31:0] B,
	output logic [31:0] C
	);
	
	xor_1bit bit_0 (.A_i (A[0]), .B_i (B[0]), .C_o (C[0]));
	xor_1bit bit_1 (.A_i (A[1]), .B_i (B[1]), .C_o (C[1]));
	xor_1bit bit_2 (.A_i (A[2]), .B_i (B[2]), .C_o (C[2]));
	xor_1bit bit_3 (.A_i (A[3]), .B_i (B[3]), .C_o (C[3]));
	xor_1bit bit_4 (.A_i (A[4]), .B_i (B[4]), .C_o (C[4]));
	xor_1bit bit_5 (.A_i (A[5]), .B_i (B[5]), .C_o (C[5]));
	xor_1bit bit_6 (.A_i (A[6]), .B_i (B[6]), .C_o (C[6]));
	xor_1bit bit_7 (.A_i (A[7]), .B_i (B[7]), .C_o (C[7]));
	xor_1bit bit_8 (.A_i (A[8]), .B_i (B[8]), .C_o (C[8]));
	xor_1bit bit_9 (.A_i (A[9]), .B_i (B[9]), .C_o (C[9]));
	xor_1bit bit_10 (.A_i (A[10]), .B_i (B[10]), .C_o (C[10]));
	xor_1bit bit_11 (.A_i (A[11]), .B_i (B[11]), .C_o (C[11]));
	xor_1bit bit_12 (.A_i (A[12]), .B_i (B[12]), .C_o (C[12]));
	xor_1bit bit_13 (.A_i (A[13]), .B_i (B[13]), .C_o (C[13]));
	xor_1bit bit_14 (.A_i (A[14]), .B_i (B[14]), .C_o (C[14]));
	xor_1bit bit_15 (.A_i (A[15]), .B_i (B[15]), .C_o (C[15]));
	xor_1bit bit_16 (.A_i (A[16]), .B_i (B[16]), .C_o (C[16]));
	xor_1bit bit_17 (.A_i (A[17]), .B_i (B[17]), .C_o (C[17]));
	xor_1bit bit_18 (.A_i (A[18]), .B_i (B[18]), .C_o (C[18]));
	xor_1bit bit_19 (.A_i (A[19]), .B_i (B[19]), .C_o (C[19]));
	xor_1bit bit_20 (.A_i (A[20]), .B_i (B[20]), .C_o (C[20]));
	xor_1bit bit_21 (.A_i (A[21]), .B_i (B[21]), .C_o (C[21]));
	xor_1bit bit_22 (.A_i (A[22]), .B_i (B[22]), .C_o (C[22]));
	xor_1bit bit_23 (.A_i (A[23]), .B_i (B[23]), .C_o (C[23]));
	xor_1bit bit_24 (.A_i (A[24]), .B_i (B[24]), .C_o (C[24]));
	xor_1bit bit_25 (.A_i (A[25]), .B_i (B[25]), .C_o (C[25]));
	xor_1bit bit_26 (.A_i (A[26]), .B_i (B[26]), .C_o (C[26]));
	xor_1bit bit_27 (.A_i (A[27]), .B_i (B[27]), .C_o (C[27]));
	xor_1bit bit_28 (.A_i (A[28]), .B_i (B[28]), .C_o (C[28]));
	xor_1bit bit_29 (.A_i (A[29]), .B_i (B[29]), .C_o (C[29]));
	xor_1bit bit_30 (.A_i (A[30]), .B_i (B[30]), .C_o (C[30]));
	xor_1bit bit_31 (.A_i (A[31]), .B_i (B[31]), .C_o (C[31]));
	

	endmodule: xor_32bit
	

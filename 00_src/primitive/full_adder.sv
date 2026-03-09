	module full_adder (
	input logic x,
	input logic y,
	input logic z,			// là bit nhớ tại vị trí có trọng số nhỏ hơn gửi tới, VD 19+25 thì 9 + 5 = 4 nhớ 1
	output logic S_o,		// S_o là biến tổng của x+y+z
	output logic C_o		// C_o là bit nhớ từ z gửi tới	
	);
	assign S_o =  ((~x)&(~y)&z) | ((~x)&y&(~z)) | (x&(~y)&(~z)) | (x&y&z);
	assign C_o =(x & y) + (x & z) + (y & z);
	
	endmodule: full_adder
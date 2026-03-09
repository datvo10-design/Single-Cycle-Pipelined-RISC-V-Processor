module mux_32_to_1 (
    input  logic d0, d1, d2, d3,d4,d5,d6,d7,d8,d9,d10,d11,d12,d13,d14,d15,
					  d16,d17,d18,d19,d20,d21,d22,d23,d24,d25,d26,d27,d28,d29,d30,d31, // 32 ngõ vào dữ liệu
    input  logic [4:0] sel,          // 32 ngõ vào điều khiển {S0,S1... S32}
    output logic      Z              // 1 ngõ ra
);
    // Dùng always_comb và case để mô tả MUX 32-1
    always_comb begin
        case (sel)
            5'b00000:  Z = d0;
            5'b00001:  Z = d1;
            5'b00010:  Z = d2;
            5'b00011:  Z = d3;
				5'b00100:  Z = d4;
				5'b00101:  Z = d5;
				5'b00110:  Z = d6;
				5'b00111:  Z = d7;
				5'b01000:  Z = d8;
				5'b01001:  Z = d9;
				5'b01010:  Z = d10;
				5'b01011:  Z = d11;
				5'b01100:  Z = d12;
				5'b01101:  Z = d13;
				5'b01110:  Z = d14;
				5'b01111:  Z = d15;
				5'b10000:  Z = d16;
				5'b10001:  Z = d17;
				5'b10010:  Z = d18;
				5'b10011:  Z = d19;
				5'b10100:  Z = d20;
				5'b10101:  Z = d21;
				5'b10110:  Z = d22;
				5'b10111:  Z = d23;
				5'b11000:  Z = d24;
				5'b11001:  Z = d25;
				5'b11010:  Z = d26;
				5'b11011:  Z = d27;
				5'b11100:  Z = d28;
				5'b11101:  Z = d29;
				5'b11110:  Z = d30;
				5'b11111:  Z = d31;
            default: Z = 1'b0;
        endcase
    end
endmodule: mux_32_to_1
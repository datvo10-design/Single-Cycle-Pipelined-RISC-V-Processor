// module chính alu điều khiển tất cả các lệnh, là một khối lớn (ALU) được ghép từ các khối nhỏ hơn đã có sẵn
module alu (
	input logic [31:0] i_op_a,
	input logic [31:0] i_op_b,
	input logic [3:0] i_alu_op,
	output logic [31:0] o_alu_data
	);
	
    //Khai báo các dây nối trung gian để nhận kết quả từ các bộ tính toán đã trong khối alu
    logic [31:0] add_result; // Dây hứng kết quả từ bộ cộng
	 logic [31:0] sub_result; // Dây hứng kết quả từ bộ SUB
	 logic slt_result; // Dây hứng kết quả từ bộ slt 
	 logic sltu_result; // Dây hứng kết quả từ bộ sltu
	 logic [31:0] xor_result; // Dây hứng kết quả từ bộ 
	 logic [31:0] or_result; // Dây hứng kết quả từ bộ 
    logic [31:0] and_result; // Dây hứng kết quả từ bộ 
	 logic [31:0] sll_result; // Dây hứng kết quả từ bộ 
	 logic [31:0] srl_result; // Dây hứng kết quả từ bộ srl
	 logic [31:0] sra_result; // Dây hứng kết quả từ bộ sra

    // Gọi (Instantiate) các module con ra và nối chân, Cả hai khối này sẽ luôn hoạt động song song
    
			// Tạo add_alu
			// Mặc định C_i=0 cho phép cộng và Không cần dùng C_o ở đây
    add_32bit add_alu ( .A( i_op_a ), .B( i_op_b ),  .SUM( add_result ), .C_o( /* open */ ));  

	     // Tạo sub_alu
		  // Mặc định C_i = 1 cho phép trừ và Không cần dùng C_o ở đây
    sub_32bit sub_alu ( .A( i_op_a ), .B( i_op_b ), .SUB( sub_result ), .C_o( /* open */ ) );
	 
			// Tạo slt_alu
    slt_32bit slt_alu ( .A( i_op_a ), .B( i_op_b ), .Result( slt_result ) );
	 
			// Tạo sltu_alu
    sltu_32bit sltu_alu ( .A( i_op_a ), .B( i_op_b ), .Result( sltu_result ) );
	 
			// Tạo xor_alu
    xor_32bit xor_alu ( .A( i_op_a ), .B( i_op_b ), .C( xor_result ) );
	 
			// Tạo or_alu
    or_32bit or_alu ( .A( i_op_a ), .B( i_op_b ), .C( or_result ) );
	 
			// Tạo AND
    and_32bit and_alu (.A( i_op_a ), .B( i_op_b ), .C( and_result ) );
	 
			// Tạo sll_alu
    sll_32bit sll_alu ( .Y( i_op_a ), .S( i_op_b[4:0] ), .Z( sll_result ) );
	 
			// Tạo srl_alu
    srl_32bit srl_alu ( .Y( i_op_a ), .S( i_op_b[4:0] ), .Z( srl_result ) );
	 
			// Tạo sra_alu
    sra_32bit sra_alu ( .Y( i_op_a ), .S( i_op_b[4:0] ), .Z( sra_result ) );
	 
	 	 
		// Định nghĩa mã lệnh cho các chức năng
		// Dùng localparam để code dễ đọc hơn khi làm bộ mux 16-1
    localparam OP_ADD = 4'b0000;
    localparam OP_SUB = 4'b0001;
	 localparam OP_SLT = 4'b0010;
	 localparam OP_SLTU = 4'b0011;
	 localparam OP_XOR = 4'b0100;
	 localparam OP_OR =  4'b0101;
	 localparam OP_AND = 4'b0110;
	 localparam OP_SLL = 4'b0111;
	 localparam OP_SRL = 4'b1000;
	 localparam OP_SRA = 4'b1001;	 
	 localparam OP_PASS_B = 4'b1111;			// định nghĩa mà lệnh cho lệnh LUI
	 
    //Dùng một bộ MUX 16-1 để chọn kết quả cuối cùng đưa ra ngoài
    always_comb begin       
        o_alu_data = 32'b0;  // Mặc định ngõ ra = 0 để tránh tạo latch

        case (i_alu_op)
            OP_ADD: begin     				 // OP_ADD ứng với 4'b0000        
                o_alu_data = add_result;	 // Nếu mã lệnh là ADD, chọn kết quả từ bộ cộng
            end

				OP_SUB: begin     				     
                o_alu_data = sub_result;	 
            end

				OP_SLT: begin     				      
                o_alu_data = slt_result;	 
            end

				OP_SLTU: begin     				        
                o_alu_data = sltu_result;	 
            end

				OP_XOR: begin     				       
                o_alu_data = xor_result;	 
            end

				OP_OR: begin     				     // OP_ADD ứng với 4'b0101   
                o_alu_data = or_result;	  // Nếu mã lệnh là OR, chọn kết quả từ bộ or
            end

            OP_AND: begin               
                o_alu_data = and_result;	
            end
				
				OP_SLL: begin     				       
                o_alu_data = sll_result;	 
            end

				OP_SRL: begin     				       
                o_alu_data = srl_result;	 
            end
				
				OP_SRA: begin     				 // OP_SRA ứng với 4'b1001     
                o_alu_data = sra_result;	 // Nếu mã lệnh là SRA, chọn kết quả từ bộ SRA
            end

				
				OP_PASS_B: begin
					o_alu_data = i_op_b; 				// Lệnh LUI: Gán thẳng giá trị từ cổng B ra kết quả
					end
					
            default: begin
                // Nếu mã lệnh không hợp lệ, ngõ ra = 0
                o_alu_data = 32'b0;
            end
        endcase
    end

endmodule: alu
				
          
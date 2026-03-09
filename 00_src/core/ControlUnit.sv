module ControlUnit (
    // ... các c?ng input
    input  logic [31:0] i_instr,			// Mã l?nh 32-bit t? IMEM

    // ??u ra: Các tín hi?u ?i?u khi?n datapath
  
    output logic        o_rd_wren,    // 1: cho phép ghi vào RegFile
    output logic        o_insn_vld,   // 1: l?nh h?p l?, dùng ?? test 	
    output logic        o_br_un,      // 1: so sánh không d?u cho BRC	
    output logic        o_opa_sel,    // 0: ch?n rs1, 1: ch?n PC
    output logic        o_opb_sel,    // 0: ch?n rs2, 1: ch?n ImmGen
    output logic [3:0]   o_alu_op,     // Mã l?nh cho ALU
    output logic        o_mem_wren,   // 1: cho phép ghi vào LSU/DMEM
    output logic o_wb_sel,      // 0: ALU, 1: LSU/Memory
	 output logic [2:0] o_ImmSel,			// ch?n ki?u Immediate cho kh?i ImmGen
	 
	// pipeline
	output logic o_is_branch,		// tín hi?u báo là m?t l?nh r? nhánh
	output logic o_is_jump,			// tín hi?u báo là m?t l?nh nh?y jal, jalr
	output logic o_type_jump, // select between jal and jalr
	 output logic o_is_load,			// lw, lh, lb....
	 
	 output logic o_rs1_used, 		// tín hi?u báo l?nh này có s? d?ng rs1 trong regfile
    output logic o_rs2_used	// tín hi?u báo l?nh này có s? d?ng rs2 trong regfile
	
);

    // ===================================================================
    // 1. TRÍCH XU?T 9 BIT VÀ CÁC TR??NG QUAN TR?NG
    // ===================================================================
	 // KHAI BÁO CÁC "DÂY ?I?N" N?I B?
	 logic [6:0] opcode;
	 logic [2:0] funct3;
	 logic       funct7b5;								// bit 30, dùng ?? phân bi?t ADD/SUB và SRL/SRA
	 
    assign opcode   = i_instr[6:0];
    assign funct3   = i_instr[14:12];
    assign funct7b5 = i_instr[30];			// bit 30, dùng ?? phân bi?t ADD/SUB và SRL/SRA

    // ===================================================================
    // 2. KH?I GI?I MÃ L?NH (INSTRUCTION DECODER)
    // T?o các c? nh?n di?n lo?i l?nh d?a trên opcode
    // ===================================================================
	 
    // ??nh ngh?a các h?ng s? cho d? ??c (best practice!)
    // Opcodes
    localparam OPCODE_R_TYPE = 7'b0110011;		 // add, sub, xor, slt...
    localparam OPCODE_I_TYPE = 7'b0010011;		 // addi, slti, xori...
    localparam OPCODE_LOAD   = 7'b0000011; 		// lw, lh, lb...
    localparam OPCODE_STORE  = 7'b0100011; 		// sw, sh, sb...
    localparam OPCODE_BRANCH = 7'b1100011; 		// beq, bne, blt...
    localparam OPCODE_JALR   = 7'b1100111;
    localparam OPCODE_JAL    = 7'b1101111;
    localparam OPCODE_AUIPC  = 7'b0010111;
    localparam OPCODE_LUI    = 7'b0110111;
	 
// Khai báo các c? nh?n di?n l?nh
logic is_r_type, is_i_type, is_load, is_store, is_branch, 
      is_jalr, is_jal, is_auipc, is_lui;
	 
	 always_comb begin
    // B??c 1: Luôn luôn gán giá tr? m?c ??nh tr??c. R?t quan tr?ng ?? tránh t?o ra latch (b? nh? ngoài ý mu?n)
    is_r_type = 1'b0;
    is_i_type = 1'b0;
    is_load   = 1'b0;
    is_store  = 1'b0;
    is_branch = 1'b0;
    is_jalr   = 1'b0;
    is_jal    = 1'b0;
    is_auipc  = 1'b0;
    is_lui    = 1'b0;

    // B??c 2: Dùng case ?? x? lý opcode
    case (opcode)
        OPCODE_R_TYPE: is_r_type = 1'b1;
        OPCODE_I_TYPE: is_i_type = 1'b1;
        OPCODE_LOAD: is_load   = 1'b1;
        OPCODE_STORE: is_store  = 1'b1;
        OPCODE_BRANCH: is_branch = 1'b1;
        OPCODE_JALR: is_jalr   = 1'b1;
        OPCODE_JAL: is_jal    = 1'b1;
        OPCODE_AUIPC: is_auipc  = 1'b1;
        OPCODE_LUI: is_lui    = 1'b1;
		  
        default: ; // Không làm gì trong các tr??ng h?p khác
    endcase
end
	 
	 
// ===================================================================
    // 3. T?O CÁC TÍN HI?U ?I?U KHI?N (CONTROL SIGNAL GENERATION)
    // D?a trên các c? nh?n di?n l?nh ? trên.
    // ===================================================================

	 
    // --- Tín hi?u o_rd_wren (Cho phép ghi vào RegFile) ---
    // B?t khi l?nh là R-type, I-type, Load, JALR, JAL, AUIPC, LUI
    assign o_rd_wren = is_r_type | is_i_type | is_load | is_jalr | is_jal | is_auipc | is_lui;

	 
	 // --- Tín hi?u o_opa_sel (Ch?n RS1 ho?c PC cho toán h?ng A) --- 
	// o_opa_sel = 1 khi là AUIPC, JAL, ho?c BRANCH.
	assign o_opa_sel = is_auipc | is_jal | is_branch;
	
	
    // --- Tín hi?u o_opb_sel (Ch?n Rs2 ho?c ImmGen cho toán h?ng B) ---
    // B?t cho t?t c? các l?nh dùng immediate, tr? R-type và các l?nh branch dùng rs2
    assign o_opb_sel = is_i_type | is_load | is_store | is_jalr | is_jal | is_auipc | is_lui| is_branch;
	 
	 
		// o_insn_vld = 1 n?u l?nh thu?c b?t k? lo?i nào ???c h? tr? thì b?t lên 1 (?? test)
	assign o_insn_vld = is_r_type | is_i_type | is_load | is_store | is_branch | is_jalr | is_jal | is_auipc | is_lui;
	 

    // --- Tín hi?u o_mem_wren (Cho phép ghi vào Memory) ---
    assign o_mem_wren = is_store;
	 

    // --- Tín hi?u o_br_un (So sánh không d?u) ---
    // D?a theo quy lu?t trong slide: BrUn = inst[13] khi là l?nh branch 
    assign o_br_un = is_branch & i_instr[13];


	 
    // --- Tín hi?u o_wb_sel (b? mux Ch?n ngu?n ghi ng??c vào regFile) ---
    always_comb begin
        if (is_load)          o_wb_sel = 1'b1; 			// Ch?n Memory
        else                     o_wb_sel = 1'b0; 		// M?c ??nh ch?n ALU
    end	 
	 
	 

	 
	//------ Tín hi?u o_ImmSel ch?n ki?u Immediate cho kh?i ImmGen-------
	 always_comb begin
  case (i_instr[6:2])
    5'b00100: o_ImmSel = 3'b000; 			// I-type (addi, xori,?)
    5'b00000: o_ImmSel = 3'b001; 			// I-type (lw)
    5'b01000: o_ImmSel = 3'b010; 			// S-type (sw)
    5'b11000: o_ImmSel = 3'b011; 			// B-type (beq)
	 5'b11011: o_ImmSel = 3'b100;				 // J-type (jal)
    5'b01101: o_ImmSel = 3'b101; 			// U-type (lui)
    5'b00101: o_ImmSel = 3'b110;				 // U-type (auipc)
	 5'b11001: o_ImmSel = 3'b111;				 // J-type (jalr)
    default:    o_ImmSel = 3'b000;
  endcase
end	 
	 

	 
    // ---------- Tín hi?u o_alu_op (Mã l?nh cho ALU) ----------------
	
	 // COPY CÁC ??NH NGH?A T? kh?i ALU.SV qua ?ây
// ===================================================================
	localparam OP_ADD  = 4'b0000;
	localparam OP_SUB  = 4'b0001;
	localparam OP_SLT  = 4'b0010;
	localparam OP_SLTU = 4'b0011;
	localparam OP_XOR  = 4'b0100;
	localparam OP_OR   = 4'b0101;
	localparam OP_AND  = 4'b0110;
	localparam OP_SLL  = 4'b0111; 
	localparam OP_SRL  = 4'b1000;
	localparam OP_SRA  = 4'b1001;
	localparam OP_PASS_B = 4'b1111;			// ??nh ngh?a mà l?nh cho l?nh LUI
	
    always_comb begin
        // Gán giá tr? m?c ??nh cho alu là phép add
        o_alu_op = OP_ADD; 

        if (is_r_type) begin			// logic cho R-type: add, sub, xor, slt...
            case (funct3)
                3'b000: if (funct7b5 == 1'b0) 		// add và sub ??u có funct3 là 000 nên dùng bit th? 30 ?? phân bi?t 
								o_alu_op = OP_ADD; // ADD
                        else                 
								o_alu_op = OP_SUB; // SUB
						
			 	    3'b001: o_alu_op = OP_SLL;			// SLL có funct3 là 001
				
					 3'b010: o_alu_op = OP_SLT;		   // SLT có funct3 là 010
					 
					 3'b011: o_alu_op = OP_SLTU;
					 
					 3'b100: o_alu_op = OP_XOR;
					 
					 3'b101: if (funct7b5 == 1'b0) 	// SRL và SRA ??u có funct3 là 101 nên dùng bit th? 30 ?? phân bi?t
								o_alu_op = OP_SRL; // SRL
								else                  
								o_alu_op = OP_SRA; // SRA
								 
					 3'b110: o_alu_op = OP_OR;
					 
					 3'b111: o_alu_op = OP_AND;			// AND có funct3 là 111
					 
					 default: begin
						o_alu_op = 4'b0000;				// ??a v? m?c ??nh ADD
				end
            endcase
		end
				
				// --- LOGIC CHO I-TYPE: addi, subi, xori, slti...---
    else if (is_i_type) begin
        // Dùng case(funct3) ?? phân bi?t các l?nh I-type
        case (funct3)
            3'b000: o_alu_op = OP_ADD;  // ADDI		(không có l?nh SUBI)
            3'b010: o_alu_op = OP_SLT;  // SLTI 
            3'b011: o_alu_op = OP_SLTU; // SLTIU
            3'b100: o_alu_op = OP_XOR;  // XORI
            3'b110: o_alu_op = OP_OR;   // ORI
            3'b111: o_alu_op = OP_AND;  // ANDI
				3'b001: o_alu_op = OP_SLL;		//SLLI
				3'b101: if (funct7b5 == 1'b0) 	// SRLI và SRAI ??u có funct3 là 101 nên dùng bit th? 30 ?? phân bi?t
								o_alu_op = OP_SRL; // SRLI
								else                  
								o_alu_op = OP_SRA; // SRAI
        endcase
    end
				
				
				// ----logic cho các l?nh khác: T?t c? các l?nh này ??u dùng phép c?ng ?? tính toán
				else if (is_load | is_store | is_auipc | is_branch | is_jal | is_jalr) begin     
						o_alu_op = OP_ADD;
				end
				
				else if (is_lui) begin				// L?nh LUI c?n ALU cho d? li?u ? c?ng B ?i th?ng ra
						o_alu_op = OP_PASS_B; 
				end
		end
		
// pipeline

// x? lý o_mispred
// nhìn opcode ?? báo ?ây là m?t l?nh Branch
always_comb begin
    case (opcode)
        7'b1100011: o_is_branch = 1'b1;	// BRANCH
    default: 
		o_is_branch = 1'b0;
		 endcase
end	

// nhìn opcode ?? báo ?ây là m?t l?nh jump
always_comb begin
    case (opcode)
      7'b1101111: begin 
        o_is_jump = 1'b1;	// jal
        o_type_jump = 1'b1; // jal
      end
		  7'b1100111: begin
		    o_is_jump = 1'b1;	// jalr
		    o_type_jump = 1'b0; // jalr
		  end
      default: begin 
       	o_is_jump = 1'b0;
       	o_type_jump = 1'b0;
     	end
		endcase
end	

// x? lý o_ctrl
// báo ?ây là m?t l?nh ?i?u khi?n (Branch, JAL, JALR).
assign o_is_control = o_is_branch | o_is_jump;

// x? lý load use hazard
assign o_is_load = is_load;

   // x? lý hazard detection unit
always_comb begin
    // M?c ??nh cho b?ng 0
    o_rs1_used = 1'b0;
    o_rs2_used = 1'b0;
    
    case (opcode)
        // TH dùng c? rs1 và rs2 (R-Type, S-Type, B-Type)
        7'b0110011: begin    // R-Type (add, sub...)
            o_rs1_used = 1'b1;
            o_rs2_used = 1'b1;
        end
        
        7'b0100011: begin    // S-Type (sw...)
            o_rs1_used = 1'b1;
            o_rs2_used = 1'b1;
        end
        
        7'b1100011: begin    // B-Type (beq...)
            o_rs1_used = 1'b1;
            o_rs2_used = 1'b1;
        end
   
        // TH ch? dùng rs1 (I-Type ALU, Load, JALR)
        7'b0010011: begin    // I-Type Arith (addi...)
            o_rs1_used = 1'b1;
            o_rs2_used = 1'b0;
        end
        
        7'b0000011: begin    // Load (lw...)
            o_rs1_used = 1'b1;
            o_rs2_used = 1'b0;
        end
        
        7'b1100111: begin    // JALR
            o_rs1_used = 1'b1;
            o_rs2_used = 1'b0;
        end
        
        // KHÔNG dùng cái nào (LUI, AUIPC, JAL)
        default: begin
            o_rs1_used = 1'b0;
            o_rs2_used = 1'b0;
        end
    endcase
end


	 endmodule: ControlUnit
	
	 
	 
	 
	 
	 
  

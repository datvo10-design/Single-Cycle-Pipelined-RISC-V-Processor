module branch_ctr_unit (
    // --- INPUT TỪ EX STAGE (Ưu tiên 1 - Cao nhất) ---
    input  logic        EX_is_branch,     // Là lệnh Br
    input  logic        EX_is_jal,        // Là lệnh JAL (đẩy xuống từ ID -> EX)
    input  logic        EX_is_jalr,       // Là lệnh JALR
    input  logic [2:0]  EX_funct3,        // Funct3 để check điều kiện Br
    input  logic        EX_br_equal,      // Flag từ ALU
    input  logic        EX_br_less,       // Flag từ ALU
    input  logic [31:0] EX_target_pc,     // Địa chỉ đích tính tại EX (ALU Result)
    input  logic [31:0] EX_pc_plus_4,     // PC+4 của lệnh tại EX
    
    // --- INPUT TỪ ID STAGE (Dùng để kiểm tra EX đúng hay sai) ---
    // ID_pc ở đây là PC của lệnh ĐANG NẰM Ở ID (Lệnh ngay sau EX)
    input  logic [31:0] ID_pc,            
    
    // --- INPUT TỪ ID STAGE (Ưu tiên 2 - Xử lý JAL sớm tại ID) ---
    input  logic        ID_is_jal,        // Phát hiện JAL tại ID
    input  logic [31:0] ID_target_pc,     // Địa chỉ đích của JAL tại ID

    // --- INPUT TỪ IF STAGE (Dùng để kiểm tra ID đúng hay sai) ---
    input  logic [31:0] IF_pc,            // PC của lệnh đang Fetch (Ngay sau ID)
    
    // --- INPUT TỪ FETCH (Ưu tiên 3 - Dự đoán) ---
    input  logic        BTB_hit,          // BTB dự đoán có lệnh nhảy
    input  logic        stack_valid,        // Stack dự đoán (cho RET)

    // --- OUTPUT ĐIỀU KHIỂN NEXT PC MUX (QUAN TRỌNG NHẤT) ---
    // 00: PC+4 (Tuần tự)
    // 01: Dự đoán (BTB/RAS)
    // 10: Sửa lỗi từ ID (JAL correction)
    // 11: Sửa lỗi từ EX (Branch/JALR correction - Flush All)
    output logic [1:0]  o_pc_mux_sel, 
    output logic [31:0] o_pc_target_out, // Địa chỉ PC đúng cần nạp

    // --- OUTPUT FLUSH PIPELINE ---
    output logic        o_flush_ID_EX,       // Xóa lệnh ở ID (do sai ở ID hoặc EX)
    output logic        o_flush_IF_ID,       // Xóa lệnh ở IF (do sai ở ID hoặc EX)
    
    // --- OUTPUT UPDATE BTB ---
    output logic        o_btb_update_en,  // Cho phép ghi vào BTB
    output logic [31:0] o_btb_target_data, // Dữ liệu ghi vào BTB
    output logic        o_mispred
);

    // =================================================================
    // 1. LOGIC TÍNH "THỰC TẾ" TẠI EX (ACTUAL OUTCOME)
    // =================================================================
    logic EX_taken; // Điều kiện nhảy có thỏa mãn không?

    always_comb begin
        if (EX_is_branch) begin
            case (EX_funct3)
                3'b000: EX_taken = EX_br_equal;                     // BEQ
                3'b001: EX_taken = !EX_br_equal;                    // BNE
                3'b100: EX_taken = EX_br_less;                      // BLT
                3'b101: EX_taken = !EX_br_less;                     // BGE
                3'b110: EX_taken = EX_br_less;                      // BLTU (Unsigned handled by ALU)
                3'b111: EX_taken = !EX_br_less;                     // BGEU
                default: EX_taken = 1'b0;
            endcase
        end 
        else if (EX_is_jal | EX_is_jalr) begin
            EX_taken = 1'b1; // JAL và JALR luôn nhảy
        end 
        else begin
            EX_taken = 1'b0;
        end
    end

    // =================================================================
    // 2. LOGIC KIỂM TRA SAI SÓT (MISPREDICTION CHECK)
    // =================================================================
    
    // --- CHECK TẠI EX ---
    // So sánh "Nơi EX muốn đến" vs "Nơi ID đang đứng"
    logic EX_mispredict;
    logic [29:0] EX_correct_next_pc;

    always_comb begin
        // Tính địa chỉ đúng thực tế
        EX_correct_next_pc = (EX_taken) ? EX_target_pc : EX_pc_plus_4;

        // So sánh với lệnh đang ở ID (Next instruction in pipeline)
        if ( EX_is_branch | EX_is_jal | EX_is_jalr ) begin
            if (EX_correct_next_pc != ID_pc) begin
                EX_mispredict = 1'b1; // Sai rồi!
            end else begin
                EX_mispredict = 1'b0; // Đúng, pipeline đang chạy mượt
            end
        end else begin
            EX_mispredict = 1'b0;
        end
    end

    // --- CHECK TẠI ID (Cho JAL Optimization) ---
    // So sánh "Nơi JAL tại ID muốn đến" vs "Nơi IF đang fetch"
    logic ID_mispredict;
    logic [29:0] ID_correct_next_pc;

    always_comb begin
        ID_correct_next_pc = ID_target_pc;

        // Nếu EX đã phát hiện sai thì không cần check ID nữa (EX quyền to hơn)
        if ( ~EX_mispredict & ID_is_jal ) begin
            if (ID_correct_next_pc != IF_pc) begin
                ID_mispredict = 1'b1; // JAL tại ID chưa được dự đoán, fetch sai
            end else begin
                ID_mispredict = 1'b0;
            end
        end else begin
            ID_mispredict = 1'b0;
        end
    end

    // =================================================================
    // 3. BỘ ĐIỀU KHIỂN TRUNG TÂM (MAIN CONTROL & MUX)
    // =================================================================
    // Priority: EX Correction > ID Correction > Prediction > PC+4
    
    always_comb begin
        // Mặc định
        o_flush_ID_EX      = 1'b0;
        o_flush_IF_ID      = 1'b0;
        o_btb_update_en = 1'b0;
        o_btb_target_data = EX_target_pc;
        
        // ---------------------------------------------------------
        // ƯU TIÊN 1: SỬA LỖI TẠI EX (Branch/Jalr/Jal miss)
        // ---------------------------------------------------------
        if (EX_mispredict) begin
            o_pc_mux_sel   = { 2'b01 } & { 2 { EX_is_branch | EX_is_jalr } } ;             // Chọn input từ EX
            o_pc_target_out = EX_correct_next_pc;
            
            o_flush_ID_EX      = EX_is_branch | EX_is_jalr;             // Lệnh ở ID là rác -> Xóa
            o_flush_IF_ID      = EX_is_branch | EX_is_jalr;             // Lệnh ở IF là rác -> Xóa
            
            // Chỉ update BTB nếu thực tế là CÓ NHẢY (Taken)
            if (EX_taken) begin
                o_btb_update_en = 1'b1;         // Ghi địa chỉ đúng vào BTB
            end
        end 
        
        // ---------------------------------------------------------
        // ƯU TIÊN 2: SỬA LỖI TẠI ID (JAL miss)
        // ---------------------------------------------------------
        else if (ID_mispredict) begin
            o_pc_mux_sel    = 2'b01;            // Chọn input từ ID
            o_pc_target_out = ID_correct_next_pc;
            
            o_flush_IF_ID      = ID_is_jal;             // Lệnh ở IF là rác -> Xóa
            o_flush_ID_EX      = 1'b0;             // Không flush ID vì JAL ở ID là lệnh hợp lệ
            
            // Có thể update BTB tại đây hoặc đợi JAL xuống EX mới update
            // Thường đợi xuống EX mới update để đơn giản hóa cổng ghi BTB
        end
        
        // ---------------------------------------------------------
        // ƯU TIÊN 3: DỰ ĐOÁN (FETCH STAGE)
        // ---------------------------------------------------------
        else if ( stack_valid ) begin
            o_pc_mux_sel    = 2'b11;            // PC lấy từ BTB/Stack
            o_pc_target_out = 32'b0;            // (Fetch unit tự lấy từ BTB)
        end
		  // Ưu tiên 4: Chọn ngõ vào là giá trị BTB đã dự đoán 
        else if ( BTB_hit ) begin 
            o_pc_mux_sel    = 2'b10;           
            o_pc_target_out = 32'b0;  
        end
        
        // ---------------------------------------------------------
        // MẶC ĐỊNH: PC + 4
        // ---------------------------------------------------------
        else begin
            o_pc_mux_sel    = 2'b00;
            o_pc_target_out = 32'b0;            // (Fetch unit tự tính PC+4)
        end
    end
    assign o_mispred = EX_mispredict;
endmodule

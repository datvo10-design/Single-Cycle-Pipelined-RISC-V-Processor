module pipelined (
    input  logic        i_clk,
    input  logic        i_reset,        // reset tich cuc thap
    input  logic [31:0] i_io_sw,
    output logic [31:0] o_pc_debug,     // PC debug output
    output logic        o_insn_vld,
    output logic        o_ctrl,
    output logic        o_mispred,
    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [6:0]  o_io_hex0, o_io_hex1, o_io_hex2, o_io_hex3,
    output logic [6:0]  o_io_hex4, o_io_hex5, o_io_hex6, o_io_hex7,
    output logic [31:0] o_io_lcd
);

    // ==============================================================================
    // 0. GLOBAL SIGNALS
    // ==============================================================================
    // Tin hieu Hazard
    logic hazard_stall;
    logic hazard_flush_IF_ID;
    logic hazard_flush_ID_EX;

    // Tin hieu Debug
    logic ID_is_ctrl, EX_is_ctrl, MEM_is_ctrl, WB_is_ctrl;
    logic EX_is_mispred, MEM_is_mispred, WB_is_mispred;

    // ==============================================================================
    // 1. IF STAGE (INSTRUCTION FETCH)
    // ==============================================================================
    logic [31:0] IF_pc_current;
    logic [31:0] IF_pc_add_4;
    logic [31:0] IF_pc_next;
    logic [31:0] IF_instruction;

    // 1.1 PC Register
    PC_reg pc_register (
        .i_clk         ( i_clk          ),
        .i_rstn        ( i_reset        ),
        .i_pc_next     ( IF_pc_next     ),
        .o_pc_current  ( IF_pc_current  ),
        .i_stall       ( hazard_stall   )
    );

    // 1.2 Adder PC + 4
    add_32bit add_32_if (
        .A    ( IF_pc_current ),
        .B    ( 32'd4         ),
        .SUM  ( IF_pc_add_4   ),
        .C_o  ( /* open */    )
    );

    // 1.3 MUX PC Next
    logic [1:0] pc_mux_sel;
    logic [31:0] pc_target;
    logic [31:0] pc_stack;
    logic [31:0] pc_btb;
    always_comb begin
        case ( pc_mux_sel )
          2'b00: IF_pc_next = IF_pc_add_4;
          2'b01: IF_pc_next = pc_target;
          2'b10: IF_pc_next = pc_btb;
          2'b11: IF_pc_next = pc_stack;
        endcase
    end
   
    // 1.4 Instruction Memory
    logic [31:0] addr_in_imem;
    logic [1:0] sel_addr_imem;
    assign sel_addr_imem = { hazard_stall, i_reset };

    always_comb begin 
      case ( sel_addr_imem ) 
        2'b00: addr_in_imem = 32'd0;
        2'b01: addr_in_imem = IF_pc_next;
        2'b10: addr_in_imem = 32'd0;
        2'b11: addr_in_imem = IF_pc_current;
      endcase
    end

    imem imem_inst (
        .i_clk   ( i_clk ),
        .i_addr  ( addr_in_imem  ),
        .o_rdata ( IF_instruction )
    );

    // ---- PIPELINE REGISTER: IF -> ID -----------------------------------------
    logic [31:0] ID_pc_current, ID_instruction;

    IF_ID_pc_reg pc_if_id_reg (
        .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_IF_ID), .i_stall(hazard_stall), 
        .pc_current_in(IF_pc_current), .pc_current_out(ID_pc_current)
    );

    IF_ID_instr_reg instr_if_id_reg (
        .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_IF_ID), .i_stall(hazard_stall), 
        .instr_in(IF_instruction), .instr_out(ID_instruction)
    );

    // ==============================================================================
    // 2. ID STAGE (INSTRUCTION DECODE)
    // ==============================================================================
    logic [31:0] ID_rs1_data, ID_rs2_data, ID_imm;
    logic        ID_rd_wren, ID_mem_wren, ID_br_un, ID_opa_sel, ID_opb_sel;
    logic [3:0]  ID_alu_op;
    logic        ID_wb_sel;     // Luu y: Pipelined II dung 1 bit wb_sel
    logic [2:0]  ID_ImmSel;
    logic        ID_insn_vld_internal;
   
    // Control Info cho Hazard/Forwarding
    logic        ID_is_branch, ID_is_jump, ID_type_jump, ID_is_load;
    logic        ID_rs1_used, ID_rs2_used;

    // Tin hieu Feedback tu WB (De ghi vao Regfile)
    logic        WB_reg_wren; 
    logic [31:0] WB_final_data;
    logic [4:0]  WB_rd_addr;

    // 2.1 Register File
    regfile regfile_inst (
        .i_clk       ( i_clk                  ),
        .i_rstn      ( i_reset                ),
        .i_rs1_addr  ( ID_instruction[19:15]  ),
        .i_rs2_addr  ( ID_instruction[24:20]  ),
        .o_rs1_data  ( ID_rs1_data            ),
        .o_rs2_data  ( ID_rs2_data            ),
        // Write port from WB stage
        .i_rd_addr   ( WB_rd_addr             ),
        .i_rd_data   ( WB_final_data          ),
        .i_rd_wren   ( WB_reg_wren            )
    );

    // 2.2 Immediate Generator
    immGen immgen_inst (
        .i_instr  ( ID_instruction ),
        .i_ImmSel ( ID_ImmSel      ),
        .o_imm    ( ID_imm         )
    );

    // 2.4 Control Unit
    ControlUnit control_inst (
        .i_instr     ( ID_instruction       ),
        // Outputs
        .o_rd_wren   ( ID_rd_wren           ),
        .o_insn_vld  ( ID_insn_vld_internal ),
        .o_br_un     ( ID_br_un             ),
        .o_opa_sel   ( ID_opa_sel           ),
        .o_opb_sel   ( ID_opb_sel           ),
        .o_alu_op    ( ID_alu_op            ),
        .o_mem_wren  ( ID_mem_wren          ),
        .o_wb_sel    ( ID_wb_sel            ),
        .o_ImmSel    ( ID_ImmSel            ),
        // Pipeline info
        .o_is_branch ( ID_is_branch         ),
        .o_is_jump   ( ID_is_jump           ), 
        .o_type_jump ( ID_type_jump         ),                  
        .o_is_load   ( ID_is_load           ),
        .o_rs1_used  ( ID_rs1_used          ),
        .o_rs2_used  ( ID_rs2_used          ) 
    );
    assign ID_is_ctrl = ID_is_branch | ID_is_jump;
   
    // forwarding for jal
    logic [31:0] ID_target_pc;
    add_32bit add_pc_jal (
        .A    ( ID_pc_current ),
        .B    ( ID_imm        ),
        .SUM  ( ID_target_pc  ),
        .C_o  ( /* open */    )
    );
   
    // ---- PIPELINE REGISTER: ID -> EX -----------------------------------------
    logic [31:0] EX_pc_current, EX_rs1_data, EX_rs2_data, EX_imm, EX_inst;
    logic [3:0]  EX_alu_op;
    logic        EX_opa_sel, EX_opb_sel, EX_mem_wren, EX_rd_wren;
    logic        EX_wb_sel;
    logic        EX_is_jump, EX_type_jump, EX_is_branch, EX_br_un, EX_is_load;
    logic        EX_br_less, EX_br_equal;

    // Data Registers
    ID_EX_pc_reg   pc_id_ex_reg   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .pc_current_in(ID_pc_current), .pc_current_out(EX_pc_current) );
    ID_EX_rs1_reg  rs1_id_ex_reg  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_rs1_data(ID_rs1_data),      .o_rs1_data(EX_rs1_data) );   
    ID_EX_rs2_reg  rs2_id_ex_reg  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_rs2_data(ID_rs2_data),      .o_rs2_data(EX_rs2_data) );        
    ID_EX_imm_reg  imm_id_ex_reg  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_imm(ID_imm),                .o_imm(EX_imm) );        
    ID_EX_inst_reg inst_id_ex_reg ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_inst(ID_instruction),       .o_inst(EX_inst) );        

    // Control Registers
    pipe_control_4_bit_regis  u1_id_ex_alu_op   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .input_data(ID_alu_op), .output_data(EX_alu_op) );
    pipeline_control_1bit_reg u2_id_ex_opa_sel  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_opa_sel),    .o_data(EX_opa_sel) );
    pipeline_control_1bit_reg u3_id_ex_opb_sel  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_opb_sel),    .o_data(EX_opb_sel) );
    pipeline_control_1bit_reg u4_id_ex_br_un    ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_br_un),      .o_data(EX_br_un) ); 
    pipeline_control_1bit_reg u5_id_ex_mem_wren ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_mem_wren),   .o_data(EX_mem_wren) ); 
    pipeline_control_1bit_reg u6_id_ex_rd_wren  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_rd_wren),    .o_data(EX_rd_wren) );       
    pipeline_control_1bit_reg u7_id_ex_wb_sel   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_wb_sel),     .o_data(EX_wb_sel) ); 
    pipeline_control_1bit_reg u_id_ex_is_branch ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_is_branch),  .o_data(EX_is_branch) );
    pipeline_control_1bit_reg u_id_ex_is_jump   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_is_jump),    .o_data(EX_is_jump) );
    pipeline_control_1bit_reg u_id_ex_type_jump ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_type_jump),  .o_data(EX_type_jump) );
    pipeline_control_1bit_reg u_id_ex_is_load   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0), .i_data(ID_is_load),    .o_data(EX_is_load) );
   
    // ==============================================================================
    // 3. EX STAGE (EXECUTE)
    // ==============================================================================
    logic [31:0] EX_operand_a, EX_operand_b;
    logic [31:0] EX_alu_result;  
    logic [2:0]  EX_funct3;

    // --- FORWARDING LOGIC VARIABLES ---
    logic [1:0]  EX_a_sel_prior;
    logic [1:0]  EX_b_sel_prior;
    logic [31:0] EX_operand_a_prior;
    logic [31:0] EX_operand_b_prior;
    // Nguon forwarding tu MEM va WB
    logic [31:0] MEM_result_data; // Tu tang MEM

    // 3.0 MUX Prior A (Forwarding Logic)
    always_comb begin
        case (EX_a_sel_prior)
            2'b00: EX_operand_a_prior = EX_rs1_data;
            2'b01: EX_operand_a_prior = MEM_result_data;
            2'b10: EX_operand_a_prior = WB_final_data;
            default: EX_operand_a_prior = 32'd0;
        endcase
    end 
   
    // 3.0 MUX Prior B (Forwarding Logic)
    always_comb begin
        case (EX_b_sel_prior)
            2'b00: EX_operand_b_prior = EX_rs2_data;
            2'b01: EX_operand_b_prior = MEM_result_data;
            2'b10: EX_operand_b_prior = WB_final_data;
            default: EX_operand_b_prior = 32'd0;
        endcase
    end 

    // 3.1 MUX A (Select PC or Forwarded Data)
    always_comb begin
        case (EX_opa_sel)
            1'b0: EX_operand_a = EX_operand_a_prior;
            1'b1: EX_operand_a = EX_pc_current;
            default: EX_operand_a = 32'd0;
        endcase
    end 

    // 3.2 MUX B (Select Forwarded Data or Imm)
    always_comb begin
        case (EX_opb_sel)
            1'b0: EX_operand_b = EX_operand_b_prior;
            1'b1: EX_operand_b = EX_imm;
            default: EX_operand_b = 32'd0;
        endcase
    end

    // 3.3 ALU
    alu alu_inst (
        .i_op_a     ( EX_operand_a  ),
        .i_op_b     ( EX_operand_b  ),
        .i_alu_op   ( EX_alu_op     ),
        .o_alu_data ( EX_alu_result )
    );
    assign EX_pc_taken = EX_alu_result; 

    // 3.4 BRC (Branch Comparator)
    brc_32bit brc_inst (
        .i_rs1_data ( EX_operand_a_prior ), // Dung data da forward
        .i_rs2_data ( EX_operand_b_prior ), // Dung data da forward
        .i_br_un    ( EX_br_un    ),
        .o_br_less  ( EX_br_less  ),
        .o_br_equal ( EX_br_equal )
    );      
    //  Adder PC+4 (For JAL/JALR return)
    logic [31:0] EX_pc_add_4;
    add_32bit add_32_mem (
        .A    ( EX_pc_current ),
        .B    ( 32'd4         ),
        .SUM  ( EX_pc_add_4   ),
        .C_o  ( /* open */    )
    );

    // ---- PIPELINE REGISTER: EX -> MEM ----------------------------------------
    logic [31:0] MEM_pc_current, MEM_pc_add_4, MEM_alu_result, MEM_inst;
    logic        MEM_rd_wren;
    logic        MEM_wb_sel;
    logic        MEM_is_jump;

    EX_MEM_pc_reg   pc_ex_mem_reg    ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_pc_ex(EX_pc_current),      .o_pc_mem(MEM_pc_current) );
    EX_MEM_pc_reg   pc4_ex_mem_reg   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_pc_ex(EX_pc_add_4),        .o_pc_mem(MEM_pc_add_4) );
    EX_MEM_inst_reg inst_ex_mem_reg  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_inst(EX_inst),             .o_inst(MEM_inst) );  
    EX_MEM_alu_reg  alu_ex_mem_reg   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_alu_result(EX_alu_result), .o_alu_result(MEM_alu_result) );  
    // Control Signals
    pipeline_control_1bit_reg u1_ex_mem_mem_wren ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_data(EX_mem_wren), .o_data(MEM_mem_wren) ); 
    pipeline_control_1bit_reg u2_ex_mem_rd_wren  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_data(EX_rd_wren),  .o_data(MEM_rd_wren) );       
    pipeline_control_1bit_reg u3_ex_mem_wb_sel   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_data(EX_wb_sel),   .o_data(MEM_wb_sel) );       
    pipeline_control_1bit_reg u4_ex_mem_is_jump  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_data(EX_is_jump),  .o_data(MEM_is_jump) );

    // ==============================================================================
    // 4. MEM STAGE (MEMORY ACCESS) - KET HOP LSU TU PIPELINED I
    // ==============================================================================
    logic [31:0] MEM_load_data;
    // 4.1 LSU (Load Store Unit) - Tu Pipelined I
    lsu lsu_inst (
        .i_clk       ( i_clk             ),
        .i_rstn      ( i_reset           ),
        .i_lsu_addr  ( EX_alu_result     ), // Address from ALU
        .i_st_data   ( EX_operand_b_prior ), // Write Data from rs2
        .i_lsu_wren  ( EX_mem_wren       ), // MemWrite signal
        .o_ld_data   ( MEM_load_data     ),
        .funct3      ( EX_inst[14:12]    ), // Funct3 for LB/LH/LW
        // I/O Ports
        .o_io_ledr(o_io_ledr), .o_io_ledg(o_io_ledg), .o_io_lcd(o_io_lcd),
        .i_io_sw(i_io_sw),
        .o_io_hex0(o_io_hex0), .o_io_hex1(o_io_hex1), .o_io_hex2(o_io_hex2), .o_io_hex3(o_io_hex3),
        .o_io_hex4(o_io_hex4), .o_io_hex5(o_io_hex5), .o_io_hex6(o_io_hex6), .o_io_hex7(o_io_hex7)
    );

    // 4.3 MUX Result (Select PC+4 or ALU Result) - Tu Pipelined II (Logic Forwarding)
    // Day la du lieu se Forward ve EX
    always_comb begin
        case (MEM_is_jump)
            1'b0: MEM_result_data = MEM_alu_result;
            1'b1: MEM_result_data = MEM_pc_add_4;
            default: MEM_result_data = 32'd0;
        endcase
    end 

    // ---- PIPELINE REGISTER: MEM -> WB ----------------------------------------
    logic [31:0] WB_pc_add_4, WB_inst;
    logic        WB_wb_sel;
    logic [31:0] WB_pc_current;
    logic [31:0] WB_result_data; // Du lieu tu MUX 4.3
    logic [31:0] WB_load_data;

    MEM_WB_pc_reg   pc_mem_wb_reg    ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_pc_mem(MEM_pc_current),     .o_pc_wb(WB_pc_current) );
    // Them thanh ghi cho Load Data tu LSU
    MEM_WB_mem_reg WB_load_data_reg ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_mem_data(MEM_load_data),     .o_mem_data(WB_load_data));
    MEM_WB_inst_reg inst_mem_wb_reg ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_inst(MEM_inst),             .o_inst(WB_inst) );
    // Them thanh ghi cho Result Data (de forward)
    MEM_WB_alu_reg result_mem_wb_reg( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_alu_result(MEM_result_data),.o_alu_result(WB_result_data) );

    // Control Signals
    pipeline_control_1bit_reg u10_mem_wb_wb_sel   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_data(MEM_wb_sel),  .o_data(WB_wb_sel) );        
    pipeline_control_1bit_reg u11_mem_wb_rd_wren  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0), .i_stall(1'b0), .i_data(MEM_rd_wren), .o_data(WB_reg_wren) );       

    // ==============================================================================
    // 5. WB STAGE (WRITE BACK)
    // ==============================================================================
    assign WB_rd_addr = WB_inst[11:7];
    always_comb begin
        case (WB_wb_sel)
            1'b0: WB_final_data = WB_result_data;   // R-type, I-type, JAL (Result from MUX 4.3)
            1'b1: WB_final_data = WB_load_data;     // Load (From LSU)
            default: WB_final_data = 32'b0;
        endcase
    end

    // ==============================================================================
    // 6. OUTPUT DEBUG / HAZARD & FORWARDING UNIT
    // ==============================================================================
    // --- Output Assignments ---
    logic EX_valid_inst, MEM_valid_inst, WB_valid_inst;

    pipeline_control_1bit_reg u_valid_id_ex  ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX), .i_stall(1'b0),         .i_data(ID_insn_vld_internal), .o_data(EX_valid_inst) );
    pipeline_control_1bit_reg u_valid_ex_mem ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0),                .i_stall(1'b0),         .i_data(EX_valid_inst), .o_data(MEM_valid_inst) );
    pipeline_control_1bit_reg u_valid_mem_wb ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0),                .i_stall(1'b0),         .i_data(MEM_valid_inst),.o_data(WB_valid_inst) );
   
    assign o_insn_vld = WB_valid_inst;  

    // Control & Mispred Chain
    pipeline_control_1bit_reg u_id_ex_is_ctrl    ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_ID_EX),  .i_stall(1'b0), .i_data(ID_is_ctrl),    .o_data(EX_is_ctrl) );
    pipeline_control_1bit_reg u_ex_mem_is_ctrl   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0),                .i_stall(1'b0), .i_data(EX_is_ctrl),    .o_data(MEM_is_ctrl) );
    pipeline_control_1bit_reg u_ex_mem_mispred   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0),                .i_stall(1'b0), .i_data(EX_is_mispred), .o_data(MEM_is_mispred) );
    pipeline_control_1bit_reg u_mem_wb_is_ctrl   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0),                .i_stall(1'b0), .i_data(MEM_is_ctrl),   .o_data(WB_is_ctrl) );
    pipeline_control_1bit_reg u_mem_wb_mispred   ( .i_clk(i_clk), .i_reset(i_reset), .i_flush(1'b0),                .i_stall(1'b0), .i_data(MEM_is_mispred),.o_data(WB_is_mispred) );

    assign o_ctrl     = WB_is_ctrl;
    assign o_mispred  = WB_is_mispred;
    assign o_pc_debug = WB_pc_current;       

    // --- Hazard Detection Unit ---
    // Trich xuat dia chi tai EX cho Hazard Unit
    logic [4:0] EX_rd_addr;
    logic       EX_reg_we;
    assign EX_rd_addr = EX_inst[11:7];
    assign EX_reg_we  = EX_rd_wren;
   
    logic branch_flush_ID_EX, branch_flush_IF_ID; 
    hazard_detection_unit u_hazard_unit (
        // Input tu ID
        .i_rs1_addr_ID   ( ID_instruction[19:15] ),
        .i_rs2_addr_ID   ( ID_instruction[24:20] ),
        .i_rs1_used_ID   ( ID_rs1_used ), 
        .i_rs2_used_ID   ( ID_rs2_used ),
        // Input tu EX (De check Load-Use Hazard)
        .i_rd_addr_EX    ( EX_rd_addr ), 
        .i_is_load       ( EX_is_load ), // Tu Pipelined II: Chi stall khi Load-Use
        // Input tu MEM (Khong dung cho Forwarding logic, nhung giu de tuong thich khoi)
        .i_rd_addr_MEM   ( MEM_inst[11:7] ), 
        // Input branch Control Hazard
        .i_branch_flush_ID_EX  ( branch_flush_ID_EX ),
        .i_branch_flush_IF_ID  ( branch_flush_IF_ID ),
        // Output
        .o_stall         ( hazard_stall ),
        .o_flush_IF_ID   ( hazard_flush_IF_ID ),
        .o_flush_ID_EX   ( hazard_flush_ID_EX )
    );

    // --- Forwarding Control Unit ---
    // Tu Pipelined II: Dieu khien MUX Prior tai EX
    forwarding_ctr_unit u_forwarding_ctr_unit (
        .i_rs1_EX          ( EX_inst[19:15] ),
        .i_rs2_EX          ( EX_inst[24:20] ),
        .i_rd_MEM          ( MEM_inst[11:7] ),
        .i_reg_we_MEM      ( MEM_rd_wren    ), 
        .i_rd_WB           ( WB_rd_addr     ), 
        .i_reg_we_WB       ( WB_reg_wren    ), 
        .o_mux_a_sel_prior ( EX_a_sel_prior ),
        .o_mux_b_sel_prior ( EX_b_sel_prior )
    );
    logic stack_vld;
    logic BTB_hit;
    logic btb_update_en;
    branch_ctr_unit branch_ctr_unit (    
        .EX_is_branch      ( EX_is_branch ),      
        .EX_is_jal         ( EX_is_jump & EX_type_jump ),
        .EX_is_jalr        ( EX_is_jump & (~EX_type_jump)),
        .EX_funct3         ( EX_inst [14:12] ),
        .EX_br_equal       ( EX_br_equal ),
        .EX_br_less        ( EX_br_less ),
        .EX_target_pc      ( EX_alu_result [31:0] ),
        .EX_pc_plus_4      ( EX_pc_add_4 [31:0] ),      
        .ID_pc             ( ID_pc_current [31:0] ),
        .ID_is_jal         ( ID_is_jump & ID_type_jump ),
        .ID_target_pc      ( ID_target_pc [31:0] ),      
        .IF_pc             ( IF_pc_current [31:0] ),
        .BTB_hit           ( BTB_hit ),
        .stack_valid       ( stack_vld ),
        .o_pc_mux_sel      ( pc_mux_sel ),
        .o_pc_target_out   ( pc_target [31:0] ),
        .o_flush_ID_EX     ( branch_flush_ID_EX ),
        .o_flush_IF_ID     ( branch_flush_IF_ID ),
        .o_btb_update_en   ( btb_update_en ),
        .o_btb_target_data (  ),
        .o_mispred         ( EX_is_mispred )
    );
    stack_ra_unit stack_ra_unit (
        .clk          ( i_clk ),
        .rstn         ( i_reset ),
        .EX_opcode    ( EX_inst [6:0] ),
        .EX_pc_add_4  ( EX_pc_add_4 ),
        .IF_opcode    ( IF_instruction [6:0] ),
        .pc_ra        ( pc_stack ),
        .vld          ( stack_vld ) 
    );
    BTB BTB (
        .i_clk        ( i_clk ),
        .i_rstn       ( i_reset ),
        .i_current_pc ( IF_pc_current ),            
        .o_predict_pc ( pc_btb ),           
        .o_btb_hit    ( BTB_hit ),              
        .i_update_en  ( btb_update_en ),             
        .i_clear_en   ( 1'b0 ),              
        .i_pc_source  ( EX_pc_current ),             
        .i_pc_target  ( EX_alu_result )
    );
endmodule

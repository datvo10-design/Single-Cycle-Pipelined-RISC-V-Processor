module hazard_detection_unit (

    input logic [4:0] i_rs1_addr_ID,
    input logic [4:0] i_rs2_addr_ID,
    input logic       i_rs1_used_ID,  
    input logic       i_rs2_used_ID,  
    
    // INPUT TU TANG EX (Lenh di truoc 1 nhip)
    input  logic [4:0] i_rd_addr_EX,    // tin hieu bao lenh nay ghi vao dau 

    // INPUT TU TANG MEM (Lenh di truoc 2 nhip)
    input  logic [4:0] i_rd_addr_MEM,   // tin hieu bao lenh nay ghi vao dau 

    // INPUT TU TANG ID 
    input logic        i_is_load,          // Tin hieu bao lenh o EX la Load (LW/LH/LB) - load use hazard 
    
    // --- INPUT TU TANG EX (Control Hazard) ---
    input  logic       i_branch_flush_ID_EX,      
    input  logic       i_branch_flush_IF_ID,

    // --- OUTPUT DIEU KHIEN PIPELINE ---
    output logic       o_stall,             // Dung PC va IF/ID
    output logic       o_flush_IF_ID,       // Xoa lenh o IF/ID (Khi Branch Taken)
    output logic       o_flush_ID_EX        // Xoa lenh o ID/EX (Khi Stall - chen NOP vao EX)
);



    // De ket luan co hazard thi phai thoa 4 dieu kien: 
    // i_rs1,2_used (Can dung), i_reg_we (Co ghi), rd_not_zero (Khac 0), rs1,2 trung voi rd
    // ========================================================================
    // 1. logic kiem tra thanh ghi dich khac x0: Dung OR reduction (|): Chi can 1 bit la 1 thi ket qua la 1 -> Khac 0
    
    logic rd_EX_not_zero, rd_MEM_not_zero;
    
    assign rd_EX_not_zero  = |i_rd_addr_EX;
    assign rd_MEM_not_zero = |i_rd_addr_MEM;


    // 2. logic so sanh dia chi rs1,2 = rd: Dung ~(A ^ B): XOR de tim diem khac, OR de gom loi, NOT de dao lai
    // match = 1 neu 2 dia chi giong het nhau
    logic rs1_ID_match_EX, rs2_ID_match_EX;
    logic rs1_ID_match_MEM, rs2_ID_match_MEM;

    assign rs1_ID_match_EX  = ~|(i_rs1_addr_ID ^ i_rd_addr_EX);
    assign rs2_ID_match_EX  = ~|(i_rs2_addr_ID ^ i_rd_addr_EX);
    
    assign rs1_ID_match_MEM = ~|(i_rs1_addr_ID ^ i_rd_addr_MEM);
    assign rs2_ID_match_MEM = ~|(i_rs2_addr_ID ^ i_rd_addr_MEM);
    
    // LOAD-USE HAZARD

    // 4 Dieu kien: Lenh o EX la Load (i_is_load = 1), Lenh o ID can dung rd cua Load, rd khac x0 va rs1 hoac rs2 o ID trung voi rd cua Load
    
    logic load_use_hazard_rs1, load_use_hazard_rs2;
    logic load_use_hazard;

    
    assign load_use_hazard_rs1 = i_is_load & i_rs1_used_ID & rd_EX_not_zero & rs1_ID_match_EX;
                                     
    assign load_use_hazard_rs2 = i_is_load & i_rs2_used_ID & rd_EX_not_zero & rs2_ID_match_EX;
    
    assign load_use_hazard = load_use_hazard_rs1 | load_use_hazard_rs2;    

    
    // ========================================================================
    // 4. LOGIC OUTPUT 

    // load use hazard (Stall)
    // Neu co load use hazard VA KHONG CO Branch Taken -> Thi moi Stall.
    // (Neu dang nhay thi ko can Stall nua, vi lenh hien tai sap bi xoa roi)
    assign o_stall = load_use_hazard & ( ~ ( i_branch_flush_ID_EX | i_branch_flush_IF_ID ) ) ;

    // Flush ID/EX (Chen NOP vao EX), xu ly hau qua cua stall
    // Khi Stall: Ta giu lenh o ID lai, nhung tang EX van chay tiep.
    // De tang EX khong chay lai lenh cu, ta phai bom vao do mot lenh NOP (bong bong).
    assign o_flush_ID_EX = load_use_hazard |  i_branch_flush_ID_EX;
    
    
    // Control Hazard (Branch Taken)
    // Neu Branch Taken -> Lenh dang o IF/ID la rac -> Phai FLUSH IF/ID
    // Luu y: Branch Taken uu tien thap hon load use hazard
    // (Neu Lenh Branch nhay, thi cai lenh ngay sau no du co dinh Data Hazard cung ke, xoa no di la xong)
    assign o_flush_IF_ID = i_branch_flush_IF_ID;

    

endmodule


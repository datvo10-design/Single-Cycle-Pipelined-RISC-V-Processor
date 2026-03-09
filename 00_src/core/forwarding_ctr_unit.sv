module forwarding_ctr_unit (
    // Lay thanh ghi rs1, rs2 cua lenh dang o giai doan EX (Lenh dang can du lieu)
    // Bo Forwarding khong can biet lenh do la ADD, SUB... No chi quan tam den dia chi thanh ghi (rs1, rs2, rd) nam ben trong lenh do thoi
    // Thay vi lay inst 32 bit vao module, chi khai bao dau vao la 5 bit (i_rs1_ex, i_rd_mem...) de code gon hon.
    input logic [4:0] i_rs1_EX,     
    input logic [4:0] i_rs2_EX,

    // Lay Thanh ghi dich (rd) cua lenh dang o giai doan MEM (Lenh dang o thanh ghi EX/MEM)
    input logic [4:0] i_rd_MEM,
    input logic i_reg_we_MEM,             // Tin hieu cho phep ghi (RegWrite)

    // Tu tang WB, lenh dang o thanh ghi MEM/WB)
    input  logic [4:0] i_rd_WB,
    input  logic i_reg_we_WB,             // Tin hieu cho phep ghi (RegWrite)
    
    // Output dieu khien 2 con mux 4-1
    // 00: khong forward, lay data rs1/rs2 tu ID/EX
    // 01: forwarding tu MEM, lay tu EX/MEM (Uu tien cao nhat)
    // 10: forwarding tu WB, lay tu MEM/WB (Uu tien nhi)
    
    output logic [1:0] o_mux_a_sel_prior,        // Tin hieu dieu khien mux A
    output logic [1:0] o_mux_b_sel_prior         // Tin hieu dieu khien mux B
);

    // Khai bao bien de check dieu kien
    // Check rd khac x0, Dung toan tu OR (|)
    logic rd_MEM_not_x0;
    logic rd_WB_not_x0;
    
    assign rd_MEM_not_x0 = |i_rd_MEM;         // Neu bat ky bit nao cua i_rd_mem = 1, thi rd_mem_not_zero = 1
    assign rd_WB_not_x0  = |i_rd_WB;          // Tuong tu tren
    
    // Check trung dia chi: Kiem tra xem cai thanh ghi dang can (rs1) co dung la cai thanh ghi dang ghi (rd) khong.
    // Dung XOR (^): Giong nhau ra 0. Sau do dung OR (|) de xem co bit nao khac 0 ko. Sau do dao nguoc (~) de lay logic "Bang nhau".
    // Vi du rs1 = rd = x1 thi i_rs1_ex ^ i_rd_mem = 0, |(...) thay chi co bit 0 nen = |(...) = 0, dao ~ lai = 1 
    logic rs1_EX_eq_rd_MEM, rs1_EX_eq_rd_WB;
    logic rs2_EX_eq_rd_MEM, rs2_EX_eq_rd_WB;

    assign rs1_EX_eq_rd_MEM = ~|(i_rs1_EX ^ i_rd_MEM);         // rs1_ex == rd_mem
    assign rs1_EX_eq_rd_WB  = ~|(i_rs1_EX ^ i_rd_WB);          // rs1_ex == rd_wb
    assign rs2_EX_eq_rd_MEM = ~|(i_rs2_EX ^ i_rd_MEM);         // rs2_ex == rd_mem
    assign rs2_EX_eq_rd_WB  = ~|(i_rs2_EX ^ i_rd_WB);          // rs2_ex == rd_wb

    // Neu ngo vao la Rs1/rs2 thi khong can check hazard

    // Logic cho mux thu nhat cua A, phai check hazard 
    always_comb begin
        o_mux_a_sel_prior = 2'b00;            // Mac dinh Lay rs1 tu thanh ghi ID/EX, khong can quan tam forwarding rs1
        
        // TH Phai check Hazard
            // Uu tien 1: Forward tu MEM, lay sau mux tai MEM
            // Phai thoa 3 dieu kien sau moi la forwarding tu MEM
            if (i_reg_we_MEM & rd_MEM_not_x0 & rs1_EX_eq_rd_MEM) begin
                o_mux_a_sel_prior = 2'b01;
            end
                
            // Uu tien 2: Forward tu WB, lay sau mux WB
            // Phai thoa 3 dieu kien sau moi la forwarding tu WB
            else if (i_reg_we_WB & rd_WB_not_x0 & rs1_EX_eq_rd_WB) begin
                o_mux_a_sel_prior = 2'b10;
            end
        end
    
    
    
    // Logic cho mux thu nhat cua B, tuong tu mux A
     always_comb begin
        o_mux_b_sel_prior = 2'b00;            // Mac dinh Lay rs2 tu thanh ghi ID/EX, khong can check hazard 
        
        // TH Phai check Hazard
            // Uu tien 1: Forward tu MEM, lay sau mux tai MEM
            // Phai thoa 3 dieu kien sau moi la forwarding tu MEM
            if (i_reg_we_MEM & rd_MEM_not_x0 & rs2_EX_eq_rd_MEM) begin
                o_mux_b_sel_prior = 2'b01;
            end
                
            // Uu tien 2: Forward tu WB, lay sau mux WB
            // Phai thoa 3 dieu kien sau moi la forwarding tu WB
            else if (i_reg_we_WB & rd_WB_not_x0 & rs2_EX_eq_rd_WB) begin
                o_mux_b_sel_prior = 2'b10;
            end
        end

 
endmodule

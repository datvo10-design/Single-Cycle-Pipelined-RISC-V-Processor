// Tao bo BTB cau hinh 2^8 = 256 dong, moi dong gom 1 phan TAG 22 bit va 1 phan dia chi dich 32 bit

module BTB (
    input logic i_clk,
    input logic i_rstn,

    // --- Phan doc (Tai tang IF) ---
    input logic [31:0]  i_current_pc,            // PC dang fetch
    output logic [31:0] o_predict_pc,           // Dia chi dich du doan
    output logic        o_btb_hit,              // 1 = lenh o PC CO trong bang (HIT), 0 = MISS

    // --- Phan cap nhat (Tu tang EX) ---
    input logic        i_update_en,             // Enable de cap nhat BTB
    input logic        i_clear_en,              // Enable xoa entry (khi du doan sai)
    input logic [31:0] i_pc_source,             // PC cua lenh Branch (da troi xuong EX)
    input logic [31:0] i_pc_target              // Dia chi dich thuc su da tinh xong
);

    // chon INDEX_BITS = 8 (2^8=256) 
    // Tinh toan so luong dong dua tren so bit (thay cho ENTRIES)      
    // tinh ra 2^8 = entries 256 dong
    // localparam ENTRIES = 256;        ENTRIES = 2^INDEX_BITS = 2^8
    // Tag lay phan con lai cua PC: 32 bit - 2 bit (align) - INDEX_BITS
    // localparam TAG_BITS = 22;        //  32 - 2 - iNDEX_BITS = 32 - 2 - 8 = 22 bit

    // --- KHAI BAO BO NHO ---
    logic [21:0] tag_mem[0:255];                // Mang luu Tag, la cai ma xac nhan 
    logic [31:0] target_mem [0:255];            // Mang luu Target Address, la dia chi dich can nhay toi
    
    // Khai bao Valid 
    logic [255:0]    valid_mem;                 // Valid bits (1 bit cho moi entry)

    // --- TACH DIA CHI READ
    logic [7:0]     read_index;
    logic [21:0]    read_tag;

    // logic 
    assign read_index = i_current_pc[9:2];
    assign read_tag = i_current_pc[31:10];      // tag 

    // --- TACH DIA CHI WRITE
    logic [7:0] write_index;
    logic [21:0]    write_tag;

    assign write_index = i_pc_source[9:2];
    assign write_tag = i_pc_source[31:10];

    
    // ----------------------------------------------------
    // 1. LOGIC DOC (Combinational)
    always_comb begin
    // BUOC 1: MAC DINH & DOC MEMORY, Gan mac dinh la Miss truoc
    o_btb_hit    = 1'b0;
    o_predict_pc = 32'd0;

    // Kiem tra trong Memory (Neu Valid va khop Tag)
    if (valid_mem[read_index] == 1'b1) begin
        if (tag_mem[read_index] == read_tag) begin
            o_btb_hit    = 1'b1;
            o_predict_pc = target_mem[read_index];
        end
    end

    // BUOC 2: XU LY FORWARDING
    // Neu trong cung 1 cycle, BTB dang doc PC X o IF stage va cap nhat PC X o EX stage --> read-during-write hazard.
	 // neu khong xu ly se lam cho BTB chon dia chi o_predict_pc cũ --> sai, phải cập nhật o_predict_pc = giá trị mới cập nhật ở tầng EX
    // Kiem tra xem co hazard khong? Neu co thi DE LEN ket qua o buoc 1
    
    if (i_update_en == 1'b1) begin                // dk 1: Co dang ghi khong?
        if (write_index == read_index) begin      // dk 2: Co bi trung ngan khong?
            if (write_tag == read_tag) begin      // dk 3: Co dung la lenh nay khong? tranh truong hop trung Index nhung khac Tag
                // neu dung het, phat hien dang ghi dung cho nay -> Phai lay du lieu moi ngay!
                o_btb_hit    = 1'b1;
                o_predict_pc = i_pc_target;       // ghi de len o_predict_pc o buoc 1
            end
        end
    end
end


    // ----------------------------------------------------
    // 2. LOGIC GHI (Synchronous)
    // ----------------------------------------------------
   always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            // Reset 1 phat sach bach luon
            valid_mem <= {256{1'b0}}; 
            // Luu y: Khong can reset tag_mem va target_mem vi valid = 0 thi coi nhu rac
        end
          
        else begin        // TRUONG HOP 1: XOA ENTRY (Du doan sai)
            if (i_clear_en) begin
                valid_mem[write_index] <= 1'b0;  // Xoa Valid bit
            end
          
            else if (i_update_en) begin        // TRUONG HOP 2: CAP NHAT ENTRY (Lenh nhay thuc su)
            valid_mem[write_index]  <= 1'b1;         // set bit Valid len 1
            tag_mem[write_index]    <= write_tag;    // Ghi Tag
            target_mem[write_index] <= i_pc_target;  // Ghi Target
            end
          // TRUONG HOP 3: Khong lam gi (giu nguyen)
        end
     end

endmodule

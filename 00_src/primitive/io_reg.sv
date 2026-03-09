module io_reg (
    input logic          i_clk,
    input logic          i_reset,
    input logic          i_access_en,
    input logic [31:0]   i_wdata,
    input logic [3:0]    i_bmask,
    input logic          i_wren,
    output logic [31:0]  o_data,
    output logic [31:0]  o_io
);
    logic [31:0] io_reg;

    //// Logic Đồng bộ (Ghi và Đọc) ////
    always_ff @( posedge i_clk or negedge i_reset ) begin 
        if ( ~i_reset ) begin 
            io_reg <= 32'd0;
            o_data <= 32'd0; // <--- [SỬA LỖI 2] Reset cả output data
        end else begin 
            // --- Write Logic ---
            if ( i_wren & i_access_en ) begin
                if ( i_bmask[0] ) io_reg [7:0]   <= i_wdata [7:0];
                if ( i_bmask[1] ) io_reg [15:8]  <= i_wdata [15:8]; 
                if ( i_bmask[2] ) io_reg [23:16] <= i_wdata [23:16]; // <--- [SỬA LỖI 1] [23:16]
                if ( i_bmask[3] ) io_reg [31:24] <= i_wdata [31:24];
            end
            
            // --- Read Logic (Synchronous - 1 cycle latency) ---
            // Nếu không chọn (access_en = 0) hoặc đang ghi (wren = 1), trả về 0
            if ( i_access_en & ~i_wren ) begin
                o_data [7:0]   <= i_bmask[0] ? io_reg [7:0]   : 8'b0;
                o_data [15:8]  <= i_bmask[1] ? io_reg [15:8]  : 8'b0;
                o_data [23:16] <= i_bmask[2] ? io_reg [23:16] : 8'b0;
                o_data [31:24] <= i_bmask[3] ? io_reg [31:24] : 8'b0;
            end else begin
                o_data <= 32'd0;
            end
        end
    end

    //// Output liên tục ra ngoại vi (LED, LCD...) ////
    assign o_io = io_reg;

endmodule : io_reg

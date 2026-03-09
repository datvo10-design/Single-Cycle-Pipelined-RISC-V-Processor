// khối PC là một D Flip-Flop (DFF), có nhiệm vụ giữ giá trị địa chỉ lệnh hiện tại và cập nhật mỗi chu kỳ xung clock.	
	
	module PC_reg (
    input  logic        i_clk,    		 // clock
    input  logic        i_rstn,    		 // reset tich cực thấp
    input  logic [31:0] i_pc_next,		 // giá trị PC kế tiếp
	  input logic i_stall,      // 1 = Giữ nguyên (Pause)
	 
    output logic [31:0] o_pc_current    // giá trị PC hiện tại
	 
);

  // ===== Cập nhật PC mỗi cạnh lên của clock =====
  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      o_pc_current <= 32'd0;          // reset PC về 0 khi reset
		end
    else begin
	 if (i_stall) begin
                o_pc_current <= o_pc_current; // stall Giữ nguyên 
            end
            else begin
                o_pc_current <= i_pc_next;    // bình thường, cập nhật PC mới
            end
end
  end

endmodule

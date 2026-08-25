// ============================================================
// Program Counter — 8-bit
// Reset → 0, Load (cho JMP/Branch), Increment +1
// ============================================================
module program_counter(
    input             clk,
    input             reset,
    input             pc_load,       // Nạp giá trị mới (JMP, Branch)
    input             pc_inc,        // Tăng PC + 1
    input      [7:0]  pc_in,         // Giá trị mới khi pc_load = 1
    output reg [7:0]  pc_out         // Giá trị PC hiện tại
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_out <= 8'h00;
        else if (pc_load)
            pc_out <= pc_in;        // Nhảy đến địa chỉ mới
        else if (pc_inc)
            pc_out <= pc_out + 8'd1; // Lệnh tiếp theo
    end

endmodule

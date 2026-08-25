// ============================================================
// RAM dữ liệu — 256 ô nhớ x 8-bit
// Đọc: tổ hợp (combinational)
// Ghi: đồng bộ (posedge clk)
// ============================================================
module ram(
    input             clk,
    input             write_en,      // Cho phép ghi
    input      [7:0]  addr,          // Địa chỉ (0–255)
    input      [7:0]  data_in,       // Dữ liệu ghi vào
    output     [7:0]  data_out       // Dữ liệu đọc ra
);

    reg [7:0] mem [0:255];
    integer i;

    // Khởi tạo toàn bộ RAM = 0
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 8'h00;
    end

    // Đọc — tổ hợp
    assign data_out = mem[addr];

    // Ghi — đồng bộ
    always @(posedge clk) begin
        if (write_en)
            mem[addr] <= data_in;
    end

endmodule

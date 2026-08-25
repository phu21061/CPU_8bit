// ============================================================
// Register File — 8 thanh ghi x 8-bit
// R0 luôn = 0 (hardwired zero)
// 2 cổng đọc đồng thời, 1 cổng ghi đồng bộ
// ============================================================
module register_file(
    input             clk,
    input             reset,
    input             write_en,      // Cho phép ghi
    input      [2:0]  read_addr1,    // Địa chỉ đọc 1 (Rs)
    input      [2:0]  read_addr2,    // Địa chỉ đọc 2 (Rt hoặc Rd)
    input      [2:0]  write_addr,    // Địa chỉ ghi (Rd)
    input      [7:0]  write_data,    // Dữ liệu ghi
    output     [7:0]  read_data1,    // Dữ liệu đọc 1
    output     [7:0]  read_data2     // Dữ liệu đọc 2
);

    reg [7:0] regs [0:7];
    integer i;

    // Đọc — tổ hợp (combinational)
    // R0 luôn trả về 0
    assign read_data1 = (read_addr1 == 3'b000) ? 8'h00 : regs[read_addr1];
    assign read_data2 = (read_addr2 == 3'b000) ? 8'h00 : regs[read_addr2];

    // Ghi — đồng bộ (synchronous), reset bất đồng bộ
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 8'h00;
        end else if (write_en && write_addr != 3'b000) begin
            // Không cho ghi vào R0
            regs[write_addr] <= write_data;
        end
    end

endmodule

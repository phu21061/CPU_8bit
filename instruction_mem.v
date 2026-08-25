// ============================================================
// Instruction Memory (Program ROM) — 256 x 16-bit
// Đọc: tổ hợp (combinational)
// Nạp chương trình từ file program.hex
// ============================================================
module instruction_mem(
    input      [7:0]  addr,          // Địa chỉ từ Program Counter
    output     [15:0] instruction    // Lệnh 16-bit
);

    reg [15:0] mem [0:255];
    integer i;

    // Khởi tạo: tất cả = NOP (F000), sau đó nạp chương trình
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 16'hF000; // NOP mặc định
        $readmemh("program.hex", mem);
    end

    // Đọc — tổ hợp
    assign instruction = mem[addr];

endmodule

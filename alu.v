// ============================================================
// ALU 8-bit — 8 phép toán, 4 cờ trạng thái
// Hoàn toàn tổ hợp (combinational), không cần tín hiệu start
// ============================================================
// Bảng phép toán:
//   0000 = ADD   (A + B)
//   0001 = SUB   (A - B)
//   0010 = AND   (A & B)
//   0011 = OR    (A | B)
//   0100 = XOR   (A ^ B)
//   0101 = NOT   (~A)
//   0110 = SHL   (A << 1)
//   0111 = SHR   (A >> 1)
// ============================================================
module alu(
    input      [7:0]  A,             // Toán hạng A (từ Rs)
    input      [7:0]  B,             // Toán hạng B (từ Rt hoặc Immediate)
    input      [3:0]  alu_op,        // Chọn phép toán
    output reg [7:0]  result,        // Kết quả 8-bit
    output reg        flag_zero,     // Cờ Zero:     result == 0
    output reg        flag_carry,    // Cờ Carry:    tràn không dấu
    output reg        flag_sign,     // Cờ Sign:     bit dấu của result
    output reg        flag_overflow  // Cờ Overflow: tràn có dấu
);

    reg [8:0] temp; // 9-bit để phát hiện carry

    always @(*) begin
        // Giá trị mặc định
        temp          = 9'b0;
        flag_carry    = 1'b0;
        flag_overflow = 1'b0;

        case (alu_op)
            4'b0000: begin // ADD — Cộng
                temp   = {1'b0, A} + {1'b0, B};
                result = temp[7:0];
                flag_carry    = temp[8];
                flag_overflow = (A[7] == B[7]) && (result[7] != A[7]);
            end

            4'b0001: begin // SUB — Trừ (A - B = A + ~B + 1)
                temp   = {1'b0, A} - {1'b0, B};
                result = temp[7:0];
                flag_carry    = temp[8]; // Borrow
                flag_overflow = (A[7] != B[7]) && (result[7] != A[7]);
            end

            4'b0010: begin // AND — Và logic
                result = A & B;
            end

            4'b0011: begin // OR — Hoặc logic
                result = A | B;
            end

            4'b0100: begin // XOR — Hoặc loại trừ
                result = A ^ B;
            end

            4'b0101: begin // NOT — Đảo bit A
                result = ~A;
            end

            4'b0110: begin // SHL — Dịch trái 1 bit
                {flag_carry, result} = {A, 1'b0}; // carry = MSB cũ
            end

            4'b0111: begin // SHR — Dịch phải 1 bit (logic)
                result     = {1'b0, A[7:1]};
                flag_carry = A[0]; // carry = LSB cũ
            end

            default: begin
                result = 8'h00;
            end
        endcase

        // Cờ Zero và Sign luôn được tính từ result
        flag_zero = (result == 8'h00);
        flag_sign = result[7];
    end

endmodule
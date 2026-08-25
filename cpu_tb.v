`timescale 1ns/1ps
// ============================================================
// TESTBENCH — CPU 8-bit
// Chạy chương trình test và kiểm tra kết quả
// ============================================================
module cpu_tb;

    // === Tín hiệu ===
    reg         clk;
    reg         reset;
    wire [7:0]  pc_out;
    wire [7:0]  alu_result_out;
    wire        flag_zero, flag_carry, flag_sign, flag_overflow;

    // === Kết nối CPU ===
    cpu_top uut(
        .clk            (clk),
        .reset          (reset),
        .pc_out         (pc_out),
        .alu_result_out (alu_result_out),
        .flag_zero      (flag_zero),
        .flag_carry     (flag_carry),
        .flag_sign      (flag_sign),
        .flag_overflow  (flag_overflow)
    );

    // === Tạo xung clock: 10ns (5ns high + 5ns low) ===
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // === Bảng mã lệnh cho hiển thị ===
    reg [39:0] opcode_name; // 5 ký tự
    always @(*) begin
        case (uut.CU.opcode)
            4'b0000: opcode_name = "ADD  ";
            4'b0001: opcode_name = "SUB  ";
            4'b0010: opcode_name = "AND  ";
            4'b0011: opcode_name = "OR   ";
            4'b0100: opcode_name = "XOR  ";
            4'b0101: opcode_name = "NOT  ";
            4'b0110: opcode_name = "SHL  ";
            4'b0111: opcode_name = "SHR  ";
            4'b1000: opcode_name = "LDI  ";
            4'b1001: opcode_name = "LOAD ";
            4'b1010: opcode_name = "STORE";
            4'b1011: opcode_name = "CMP  ";
            4'b1100: opcode_name = "JMP  ";
            4'b1101: opcode_name = "BEQ  ";
            4'b1110: opcode_name = "BNE  ";
            4'b1111: opcode_name = "NOP  ";
            default: opcode_name = "???  ";
        endcase
    end

    // === Hiển thị khi hoàn thành mỗi lệnh (cuối EXECUTE) ===
    always @(posedge clk) begin
        if (!reset && uut.CU.state == 2'b10) begin
            #1; // Đợi non-blocking assignments hoàn tất
            $display("  [PC=%2d] %s | R1=%3d R2=%3d R3=%3d R4=%3d R5=%3d R6=%3d R7=%3d | Z=%b C=%b S=%b V=%b",
                     pc_out, opcode_name,
                     uut.RF.regs[1], uut.RF.regs[2], uut.RF.regs[3], uut.RF.regs[4],
                     uut.RF.regs[5], uut.RF.regs[6], uut.RF.regs[7],
                     flag_zero, flag_carry, flag_sign, flag_overflow);
        end
    end

    // === Test chính ===
    integer pass_count;
    integer fail_count;

    task check;
        input [63:0] name;
        input [7:0]  actual;
        input [7:0]  expected;
        begin
            if (actual === expected) begin
                $display("    [PASS] %s = %0d", name, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("    [FAIL] %s = %0d (expected %0d)", name, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("");
        $display("============================================================");
        $display("         8-BIT SIMPLE CPU — TESTBENCH");
        $display("============================================================");
        $display("");

        pass_count = 0;
        fail_count = 0;

        // === RESET ===
        $display("[RESET] Đang reset CPU...");
        reset = 1'b1;
        @(posedge clk); @(posedge clk);
        reset = 1'b0;
        $display("[RESET] Hoàn tất. Bắt đầu thực thi chương trình.\n");
        $display("--- Thực thi từng lệnh ---");

        // === Chờ chương trình chạy ===
        // 14 lệnh thực thi × 3 chu kỳ/lệnh = 42 chu kỳ
        // + thêm vài chu kỳ cho JMP loop
        repeat(55) @(posedge clk);

        // === Kiểm tra kết quả ===
        $display("");
        $display("============================================================");
        $display("         KẾT QUẢ KIỂM TRA");
        $display("============================================================");
        $display("");

        $display("--- Thanh ghi ---");
        check("R0 ", uut.RF.regs[0], 8'd0);
        check("R1 ", uut.RF.regs[1], 8'd10);   // LDI R1, 10
        check("R2 ", uut.RF.regs[2], 8'd5);    // LDI R2, 5
        check("R3 ", uut.RF.regs[3], 8'd15);   // ADD R3 = 10+5
        check("R4 ", uut.RF.regs[4], 8'd5);    // SUB R4 = 10-5
        check("R5 ", uut.RF.regs[5], 8'd15);   // OR  R5 = 10|5 (ghi đè AND)
        check("R6 ", uut.RF.regs[6], 8'd15);   // LOAD R6 = RAM[0] (ghi đè SHR)
        check("R7 ", uut.RF.regs[7], 8'd245);  // NOT R7 = ~10

        $display("");
        $display("--- Bộ nhớ RAM ---");
        check("RAM0", uut.RAM_inst.mem[0], 8'd15); // STORE R3=15

        $display("");
        $display("============================================================");
        if (fail_count == 0)
            $display("  ALL %0d TESTS PASSED!", pass_count);
        else
            $display("  %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("============================================================");
        $display("");

        $finish;
    end

    // === Waveform ===
    // Vivado tự động ghi waveform khi chạy simulation
    // Mở tab Waveform trong Vivado để xem tín hiệu

endmodule

// ============================================================
// TOP MODULE — 8-bit Simple CPU
// Kiến trúc Harvard: Instruction Memory tách biệt Data RAM
// Pipeline 3 giai đoạn: FETCH → DECODE → EXECUTE
// ============================================================
module cpu_top(
    input             clk,           // Xung clock
    input             reset,         // Reset bất đồng bộ (active high)

    // === Debug Outputs ===
    output     [7:0]  pc_out,        // Giá trị Program Counter
    output     [7:0]  alu_result_out,// Kết quả ALU
    output            flag_zero,     // Cờ Zero
    output            flag_carry,    // Cờ Carry
    output            flag_sign,     // Cờ Sign
    output            flag_overflow  // Cờ Overflow
);

    // =====================================================
    //                   WIRE NỘI BỘ
    // =====================================================

    // Program Counter
    wire [7:0] pc;

    // Instruction Memory
    wire [15:0] instruction;

    // Control Unit — tín hiệu điều khiển
    wire        ir_load, pc_inc, pc_load;
    wire        reg_write_en, mem_write_en, flags_en;
    wire [3:0]  alu_op;
    wire        alu_src;
    wire [1:0]  reg_write_src;
    wire [7:0]  pc_target;

    // Control Unit — trường giải mã
    wire [3:0]  opcode;
    wire [2:0]  rd_addr, rs_addr, rt_addr;
    wire [7:0]  imm_ext;

    // Register File
    wire [7:0]  rs_data, rt_rd_data;
    wire [2:0]  rf_read_addr2;

    // ALU
    wire [7:0]  alu_a, alu_b, alu_result;
    wire        alu_zero, alu_carry, alu_sign, alu_ov;

    // Flags Register
    reg         flag_z_reg, flag_c_reg, flag_s_reg, flag_v_reg;

    // RAM
    wire [7:0]  ram_data_out;

    // Write-back MUX
    reg  [7:0]  reg_write_data;

    // =====================================================
    //              1. PROGRAM COUNTER
    // =====================================================
    program_counter PC_inst(
        .clk     (clk),
        .reset   (reset),
        .pc_load (pc_load),
        .pc_inc  (pc_inc),
        .pc_in   (pc_target),
        .pc_out  (pc)
    );

    // =====================================================
    //           2. INSTRUCTION MEMORY
    // =====================================================
    instruction_mem IMEM(
        .addr        (pc),
        .instruction (instruction)
    );

    // =====================================================
    //              3. CONTROL UNIT
    // =====================================================
    control_unit CU(
        .clk           (clk),
        .reset         (reset),
        .instruction   (instruction),
        .flag_zero     (flag_z_reg),
        .current_pc    (pc),
        // Tín hiệu điều khiển
        .ir_load       (ir_load),
        .pc_inc        (pc_inc),
        .pc_load       (pc_load),
        .reg_write_en  (reg_write_en),
        .mem_write_en  (mem_write_en),
        .flags_en      (flags_en),
        .alu_op        (alu_op),
        .alu_src       (alu_src),
        .reg_write_src (reg_write_src),
        // Trường giải mã
        .opcode        (opcode),
        .rd_addr       (rd_addr),
        .rs_addr       (rs_addr),
        .rt_addr       (rt_addr),
        .imm_ext       (imm_ext),
        .pc_target     (pc_target)
    );

    // =====================================================
    //             4. REGISTER FILE
    // =====================================================
    // MUX read_addr2: STORE cần đọc Rd (dữ liệu ghi vào RAM)
    //                 Các lệnh khác đọc Rt (toán hạng ALU)
    assign rf_read_addr2 = mem_write_en ? rd_addr : rt_addr;

    register_file RF(
        .clk         (clk),
        .reset       (reset),
        .write_en    (reg_write_en),
        .read_addr1  (rs_addr),
        .read_addr2  (rf_read_addr2),
        .write_addr  (rd_addr),
        .write_data  (reg_write_data),
        .read_data1  (rs_data),
        .read_data2  (rt_rd_data)
    );

    // =====================================================
    //                  5. ALU
    // =====================================================
    // MUX ALU input B: 0 = từ thanh ghi (Rt), 1 = từ Immediate
    assign alu_a = rs_data;
    assign alu_b = alu_src ? imm_ext : rt_rd_data;

    alu ALU_inst(
        .A             (alu_a),
        .B             (alu_b),
        .alu_op        (alu_op),
        .result        (alu_result),
        .flag_zero     (alu_zero),
        .flag_carry    (alu_carry),
        .flag_sign     (alu_sign),
        .flag_overflow (alu_ov)
    );

    // =====================================================
    //            6. FLAGS REGISTER
    // =====================================================
    // Lưu trữ cờ từ ALU, cập nhật khi flags_en = 1
    // (chỉ cập nhật cho lệnh ALU R-type và CMP)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            flag_z_reg <= 1'b0;
            flag_c_reg <= 1'b0;
            flag_s_reg <= 1'b0;
            flag_v_reg <= 1'b0;
        end else if (flags_en) begin
            flag_z_reg <= alu_zero;
            flag_c_reg <= alu_carry;
            flag_s_reg <= alu_sign;
            flag_v_reg <= alu_ov;
        end
    end

    // =====================================================
    //               7. DATA RAM
    // =====================================================
    // Địa chỉ RAM = kết quả ALU (Rs + Imm cho LOAD/STORE)
    // Dữ liệu ghi = giá trị thanh ghi Rd (qua read_data2 khi STORE)
    ram RAM_inst(
        .clk      (clk),
        .write_en (mem_write_en),
        .addr     (alu_result),
        .data_in  (rt_rd_data),
        .data_out (ram_data_out)
    );

    // =====================================================
    //          8. WRITE-BACK MUX
    // =====================================================
    // Chọn nguồn dữ liệu ghi vào Register File
    always @(*) begin
        case (reg_write_src)
            2'b00:   reg_write_data = alu_result;   // Kết quả ALU
            2'b01:   reg_write_data = ram_data_out;  // Dữ liệu từ RAM
            2'b10:   reg_write_data = imm_ext;       // Giá trị Immediate
            default: reg_write_data = 8'h00;
        endcase
    end

    // =====================================================
    //           9. DEBUG OUTPUTS
    // =====================================================
    assign pc_out         = pc;
    assign alu_result_out = alu_result;
    assign flag_zero      = flag_z_reg;
    assign flag_carry     = flag_c_reg;
    assign flag_sign      = flag_s_reg;
    assign flag_overflow  = flag_v_reg;

endmodule

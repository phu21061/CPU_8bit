// ============================================================
// Control Unit — FSM 3 trạng thái: FETCH → DECODE → EXECUTE
// Giải mã lệnh 16-bit và phát tín hiệu điều khiển
// ============================================================
// Định dạng lệnh:
//   R-type: [15:12] opcode | [11:9] Rd | [8:6] Rs | [5:3] Rt | [2:0] unused
//   I-type: [15:12] opcode | [11:9] Rd | [8:6] Rs | [5:0] Imm6
// ============================================================
module control_unit(
    input             clk,
    input             reset,
    input      [15:0] instruction,   // Lệnh từ Instruction Memory
    input             flag_zero,     // Cờ Zero từ Flags Register
    input      [7:0]  current_pc,    // Giá trị PC hiện tại

    // === Tín hiệu điều khiển ===
    output reg        ir_load,       // Nạp Instruction Register
    output reg        pc_inc,        // Tăng PC + 1
    output reg        pc_load,       // Nạp PC = target (JMP/Branch)
    output reg        reg_write_en,  // Cho phép ghi Register File
    output reg        mem_write_en,  // Cho phép ghi RAM
    output reg        flags_en,      // Cập nhật Flags Register
    output reg [3:0]  alu_op,        // Chọn phép toán ALU
    output reg        alu_src,       // 0 = Rt_data, 1 = Imm cho ALU input B
    output reg [1:0]  reg_write_src, // 00=ALU, 01=RAM, 10=Immediate

    // === Trường đã giải mã ===
    output     [3:0]  opcode,        // Mã lệnh
    output     [2:0]  rd_addr,       // Địa chỉ thanh ghi đích
    output     [2:0]  rs_addr,       // Địa chỉ thanh ghi nguồn 1
    output     [2:0]  rt_addr,       // Địa chỉ thanh ghi nguồn 2
    output     [7:0]  imm_ext,       // Immediate mở rộng dấu (8-bit)
    output reg [7:0]  pc_target      // Địa chỉ đích cho PC
);

    // =================== Trạng thái FSM ===================
    localparam FETCH   = 2'b00;
    localparam DECODE  = 2'b01;
    localparam EXECUTE = 2'b10;

    reg [1:0] state, next_state;

    // =================== Instruction Register ===================
    reg [15:0] ir;

    // State register — đồng bộ, reset bất đồng bộ
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= next_state;
    end

    // Instruction Register — nạp khi ir_load = 1
    always @(posedge clk or posedge reset) begin
        if (reset)
            ir <= 16'h0000;
        else if (ir_load)
            ir <= instruction;
    end

    // =================== Giải mã trường từ IR (tổ hợp) ===================
    assign opcode  = ir[15:12];
    assign rd_addr = ir[11:9];
    assign rs_addr = ir[8:6];
    assign rt_addr = ir[5:3];
    // Mở rộng dấu: 6-bit → 8-bit
    assign imm_ext = {{2{ir[5]}}, ir[5:0]};

    // =================== Địa chỉ nhảy/rẽ nhánh ===================
    wire [7:0] jmp_target    = ir[7:0];                                     // JMP: địa chỉ tuyệt đối
    wire [7:0] branch_target = current_pc + 8'd1 + {{2{ir[5]}}, ir[5:0]};  // BEQ/BNE: PC + 1 + offset

    // =================== Logic FSM (tổ hợp) ===================
    always @(*) begin
        // --- Giá trị mặc định ---
        next_state    = state;
        ir_load       = 1'b0;
        pc_inc        = 1'b0;
        pc_load       = 1'b0;
        reg_write_en  = 1'b0;
        mem_write_en  = 1'b0;
        flags_en      = 1'b0;
        alu_op        = 4'b0000;
        alu_src       = 1'b0;
        reg_write_src = 2'b00;
        pc_target     = 8'h00;

        case (state)
            // ===================== FETCH =====================
            // Nạp lệnh từ Instruction Memory vào IR
            FETCH: begin
                ir_load    = 1'b1;
                next_state = DECODE;
            end

            // ===================== DECODE =====================
            // Giải mã lệnh (tổ hợp từ IR), đọc thanh ghi
            DECODE: begin
                next_state = EXECUTE;
            end

            // ===================== EXECUTE =====================
            // Thực thi: tính toán ALU, ghi kết quả, cập nhật PC
            EXECUTE: begin
                next_state = FETCH;

                case (opcode)
                    // --- R-type: Phép toán số học/logic ---
                    4'b0000: begin // ADD  Rd = Rs + Rt
                        alu_op        = 4'b0000;
                        alu_src       = 1'b0;
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b00;
                        flags_en      = 1'b1;
                        pc_inc        = 1'b1;
                    end

                    4'b0001: begin // SUB  Rd = Rs - Rt
                        alu_op        = 4'b0001;
                        alu_src       = 1'b0;
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b00;
                        flags_en      = 1'b1;
                        pc_inc        = 1'b1;
                    end

                    4'b0010: begin // AND  Rd = Rs & Rt
                        alu_op        = 4'b0010;
                        alu_src       = 1'b0;
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b00;
                        flags_en      = 1'b1;
                        pc_inc        = 1'b1;
                    end

                    4'b0011: begin // OR   Rd = Rs | Rt
                        alu_op        = 4'b0011;
                        alu_src       = 1'b0;
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b00;
                        flags_en      = 1'b1;
                        pc_inc        = 1'b1;
                    end

                    4'b0100: begin // XOR  Rd = Rs ^ Rt
                        alu_op        = 4'b0100;
                        alu_src       = 1'b0;
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b00;
                        flags_en      = 1'b1;
                        pc_inc        = 1'b1;
                    end

                    4'b0101: begin // NOT  Rd = ~Rs
                        alu_op        = 4'b0101;
                        alu_src       = 1'b0;
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b00;
                        flags_en      = 1'b1;
                        pc_inc        = 1'b1;
                    end

                    4'b0110: begin // SHL  Rd = Rs << 1
                        alu_op        = 4'b0110;
                        alu_src       = 1'b0;
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b00;
                        flags_en      = 1'b1;
                        pc_inc        = 1'b1;
                    end

                    4'b0111: begin // SHR  Rd = Rs >> 1
                        alu_op        = 4'b0111;
                        alu_src       = 1'b0;
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b00;
                        flags_en      = 1'b1;
                        pc_inc        = 1'b1;
                    end

                    // --- I-type: Load Immediate ---
                    4'b1000: begin // LDI  Rd = sign_extend(Imm)
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b10; // Từ immediate
                        pc_inc        = 1'b1;
                    end

                    // --- I-type: Load từ RAM ---
                    4'b1001: begin // LOAD  Rd = RAM[Rs + Imm]
                        alu_op        = 4'b0000; // ADD để tính địa chỉ
                        alu_src       = 1'b1;    // B = Immediate
                        reg_write_en  = 1'b1;
                        reg_write_src = 2'b01;   // Từ RAM
                        pc_inc        = 1'b1;
                    end

                    // --- I-type: Store vào RAM ---
                    4'b1010: begin // STORE  RAM[Rs + Imm] = Rd
                        alu_op        = 4'b0000; // ADD để tính địa chỉ
                        alu_src       = 1'b1;    // B = Immediate
                        mem_write_en  = 1'b1;
                        pc_inc        = 1'b1;
                    end

                    // --- R-type: So sánh (chỉ cập nhật flags) ---
                    4'b1011: begin // CMP  flags = Rs - Rt
                        alu_op        = 4'b0001; // SUB
                        alu_src       = 1'b0;
                        flags_en      = 1'b1;
                        pc_inc        = 1'b1;
                        // Không ghi thanh ghi
                    end

                    // --- Nhảy không điều kiện ---
                    4'b1100: begin // JMP  PC = target
                        pc_load       = 1'b1;
                        pc_target     = jmp_target;
                    end

                    // --- Rẽ nhánh: nhảy nếu bằng ---
                    4'b1101: begin // BEQ  if (Z==1) PC = PC+1+offset
                        if (flag_zero) begin
                            pc_load   = 1'b1;
                            pc_target = branch_target;
                        end else begin
                            pc_inc    = 1'b1;
                        end
                    end

                    // --- Rẽ nhánh: nhảy nếu không bằng ---
                    4'b1110: begin // BNE  if (Z==0) PC = PC+1+offset
                        if (!flag_zero) begin
                            pc_load   = 1'b1;
                            pc_target = branch_target;
                        end else begin
                            pc_inc    = 1'b1;
                        end
                    end

                    // --- Không làm gì ---
                    4'b1111: begin // NOP
                        pc_inc        = 1'b1;
                    end

                    default: begin
                        pc_inc        = 1'b1;
                    end
                endcase
            end

            default: begin
                next_state = FETCH;
            end
        endcase
    end

endmodule

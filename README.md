# 8-bit Simple CPU

Đây là một project thiết kế vi xử lý 8-bit (CPU) cơ bản bằng Verilog, được nâng cấp từ kiến trúc 4-bit. CPU sử dụng kiến trúc Harvard với bộ nhớ lệnh và bộ nhớ dữ liệu tách biệt.

## Đặc điểm kiến trúc
- **Data Bus**: 8-bit
- **Register File**: 8 thanh ghi 8-bit (R0–R7), trong đó R0 được hardwired bằng 0 theo chuẩn RISC.
- **ALU**: Hỗ trợ 8 phép toán (ADD, SUB, AND, OR, XOR, NOT, SHL, SHR) và 4 cờ trạng thái (Zero, Carry, Sign, Overflow).
- **Bộ nhớ dữ liệu (RAM)**: 256 byte.
- **Bộ nhớ lệnh (Instruction Memory)**: 256 lệnh x 16-bit.
- **Tập lệnh (Instruction Set)**: 16-bit instruction format hỗ trợ 13 lệnh cơ bản bao gồm load/store, tính toán, và rẽ nhánh.
- **Control Unit**: FSM 3 trạng thái (FETCH → DECODE → EXECUTE).

## Cấu trúc thư mục
- `cpu_top.v`: Module kết nối tất cả các thành phần.
- `cpu_tb.v`: Testbench chạy mô phỏng toàn hệ thống.
- `register_file.v`: Khối thanh ghi.
- `alu.v`: Khối tính toán số học và logic.
- `ram.v`: Khối bộ nhớ dữ liệu.
- `instruction_mem.v`: Bộ nhớ lệnh ROM.
- `program_counter.v`: Bộ đếm chương trình.
- `control_unit.v`: Khối điều khiển trung tâm.
- `program.hex`: File chứa mã máy (hex) để nạp vào ROM khi mô phỏng.

## Hướng dẫn chạy mô phỏng (Simulation) trên Vivado
1. Tạo một project RTL mới trên Vivado.
2. Thêm các file thiết kế (`cpu_top.v`, `register_file.v`, `alu.v`, `ram.v`, `instruction_mem.v`, `program_counter.v`, `control_unit.v`) vào **Design Sources**. Đảm bảo `cpu_top` là top module.
3. Thêm file testbench `cpu_tb.v` và đặc biệt là `program.hex` vào **Simulation Sources**. 
4. Chạy **Run Simulation** -> **Run Behavioral Simulation**.
5. Mở tab Waveform, thiết lập màu nền (nếu cần), và kéo các tín hiệu từ uut vào để quan sát, sau đó chọn **Run All**.

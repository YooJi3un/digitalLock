module DigitalLock(
  input  wire [3:0] KEY,    // 입력 버튼
  input  wire [0:0] SW,     // Reset
  output wire [0:0] LEDG,   // LED 출력
  output wire [6:0] HEX0,   // 7-Segment Display (0)
  output wire [6:0] HEX1,   // 7-Segment Display (1)
  output wire [6:0] HEX2,   // 7-Segment Display (2)
  output wire [6:0] HEX3    // 7-Segment Display (3)
);

  wire seq[0:3]; // 플립플롭 연결 신호
  wire rst_n = ~SW[0];  
  reg [3:0] key_valid; // KEY 입력 횟수 기록
  reg [3:0] display_state; // 상태 (0: Close, 2: Open)

  // 각 KEY 입력의 force_reset 신호
  wire [3:0] force_reset;

  // KEY 입력 로직
  always @(posedge KEY[0] or negedge rst_n) begin
    if (!rst_n) key_valid[0] <= 1'b0; 
    else if (key_valid[0] < 2) key_valid[0] <= key_valid[0] + 1; // 최대 2로 제한
  end

  always @(posedge KEY[1] or negedge rst_n) begin
    if (!rst_n) key_valid[1] <= 1'b0;
    else if (key_valid[1] < 2) key_valid[1] <= key_valid[1] + 1; // 최대 2로 제한
  end

  always @(posedge KEY[2] or negedge rst_n) begin
    if (!rst_n) key_valid[2] <= 1'b0;
    else if (key_valid[2] < 2) key_valid[2] <= key_valid[2] + 1; // 최대 2로 제한
  end

  always @(posedge KEY[3] or negedge rst_n) begin
    if (!rst_n) key_valid[3] <= 1'b0;
    else if (key_valid[3] < 2) key_valid[3] <= key_valid[3] + 1; // 최대 2로 제한
  end

  // force_reset 로직: key_valid가 2 이상이면 강제 초기화
  assign force_reset[0] = (key_valid[0] >= 2); // key_valid[0]가 2 이상이면 초기화
  assign force_reset[1] = (key_valid[1] >= 2);
  assign force_reset[2] = (key_valid[2] >= 2);
  assign force_reset[3] = (key_valid[3] >= 2);

  // 플립플롭 체인 (비밀번호 확인)
  ff ff3(
    .clk(KEY[2]),
    .rst_n(rst_n),
    .force_reset(force_reset[3]),
    .d(1'b1),
    .q(seq[3])
  );

  ff ff2(
    .clk(KEY[3]),
    .rst_n(rst_n),
    .force_reset(force_reset[2]),
    .d(seq[3]),
    .q(seq[2])
  );

  ff ff1(
    .clk(KEY[1]), 
    .rst_n(rst_n),
    .force_reset(force_reset[1]),
    .d(seq[2]),
    .q(seq[1])
  );

  ff ff0(
    .clk(KEY[0]),
    .rst_n(rst_n),
    .force_reset(force_reset[0]),
    .d(seq[1]),
    .q(seq[0])
  );

  // 상태 결정 로직
  wire all_keys_pressed = (key_valid == 4'b1111); // 모든 KEY가 "정확히 한 번씩" 눌렸는지 확인
  wire password_correct = (seq[3] && seq[2] && seq[1] && seq[0]); // 비밀번호 확인

  always @(*) begin
    if (!rst_n) begin
      display_state = 4'd0; // Close 상태 (Reset)
    end else if (all_keys_pressed && password_correct) begin
      display_state = 4'd2; // Open 상태
    end else begin
      display_state = 4'd0; // Close 상태
    end
  end

  // HEX 출력 값 결정
  reg [3:0] hex0_val, hex1_val, hex2_val, hex3_val;

  always @(*) begin
    if (display_state == 4'd2) begin
      hex0_val = 4'd3; // N
      hex1_val = 4'd2; // E
      hex2_val = 4'd1; // P
      hex3_val = 4'd0; // Open 상태
    end else begin
      hex0_val = 4'd2; // F
      hex1_val = 4'd6; // A
      hex2_val = 4'd5; // S
      hex3_val = 4'd4; // S
    end
  end

  // 7-Segment Decoder
  function [6:0] decode_7seg(input [3:0] value);
    case (value)
      4'd0: decode_7seg = 7'b1000000; // 0
      4'd1: decode_7seg = 7'b0001100; // P
      4'd2: decode_7seg = 7'b0000110; // E
      4'd3: decode_7seg = 7'b1001000; // N
      4'd4: decode_7seg = 7'b0010010; // S
      4'd5: decode_7seg = 7'b0001000; // A
      4'd6: decode_7seg = 7'b0001110; // F
      default: decode_7seg = 7'b1111111; // Default blank
    endcase
  endfunction

  // 7-Segment Assignments
  assign HEX0 = decode_7seg(hex0_val);
  assign HEX1 = decode_7seg(hex1_val);
  assign HEX2 = decode_7seg(hex2_val);
  assign HEX3 = decode_7seg(hex3_val);

  // LED
  assign LEDG[0] = (display_state == 4'd2);

endmodule

// 플립플롭 모듈 정의
module ff(
  input wire clk,
  input wire rst_n,
  input wire force_reset, // 강제 초기화 신호
  input wire d,
  output reg q
);

  always @(negedge clk or negedge rst_n or posedge force_reset) begin
    if (!rst_n || force_reset) begin
      q <= 1'b0;  // Reset 또는 강제 초기화 시 q를 0으로 설정
    end else begin
      q <= d;     // 기본 플립플롭 동작
    end
  end

endmodule

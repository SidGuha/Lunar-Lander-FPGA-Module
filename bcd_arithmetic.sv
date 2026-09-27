`default_nettype none
// Empty top module

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);
    logic co;
    logic [3:0] s;


  
endmodule


module fa(
    input logic a, b, ci,
    output logic s, co
);
    assign s = a ^ b ^ ci;
    assign co = (a & b) | (b & ci) | (a & ci);

endmodule

module fa4 (
    input logic [3:0] a, b,
    input logic ci,
    output logic [3:0] s,
    output logic co
);

    logic carr1, carr2, carr3;

    fa f1(.a(a[0]), .b(b[0]), .ci(ci), .s(s[0]), .co(carr1));
    fa f2(.a(a[1]), .b(b[1]), .ci(carr1), .s(s[1]), .co(carr2));
    fa f3(.a(a[2]), .b(b[2]), .ci(carr2), .s(s[2]), .co(carr3));
    fa f4(.a(a[3]), .b(b[3]), .ci(carr3), .s(s[3]), .co(co));    
endmodule

module bcdadd1(
    input logic [3:0] a, b,
    input logic ci,
    output logic [3:0] s,
    output logic co

);

    logic [3:0] corrected_sum;
    logic carry_out;
    fa4 adder(.a(a), .b(b), .ci(ci), .s(corrected_sum), .co(carry_out));

    //if co exists
    assign co = carry_out | (corrected_sum > 4'b1001);
    //add 6
    assign s = co ? (corrected_sum + 4'b0110) : corrected_sum;


endmodule

module bcdadd4(
    input logic [15:0] a, b,
    input logic ci,
    output logic [15:0] s,
    output logic co
);

    logic carry0, carry1, carry2;


    bcdadd1 digit0(.a(a[3:0]), .b(b[3:0]), .ci(ci), .s(s[3:0]), .co(carry0));
    bcdadd1 digit1(.a(a[7:4]), .b(b[7:4]), .ci(carry0), .s(s[7:4]), .co(carry1));
    bcdadd1 digit2(.a(a[11:8]), .b(b[11:8]), .ci(carry1), .s(s[11:8]), .co(carry2));
    bcdadd1 digit3(.a(a[15:12]), .b(b[15:12]), .ci(carry2), .s(s[15:12]), .co(co));






endmodule

module bcd9comp1(
    input logic [3:0] in,
    output logic [3:0] out
);

    always_comb begin

        case(in)
            4'b0000: out = 4'b1001;
            4'b0001: out = 4'b1000;
            4'b0010: out = 4'b0111;
            4'b0011: out = 4'b0110;
            4'b0100: out = 4'b0101;
            4'b0101: out = 4'b0100;
            4'b0110: out = 4'b0011;
            4'b0111: out = 4'b0010;
            4'b1000: out = 4'b0001;
            4'b1001: out = 4'b0000;
            default: out = 4'b0000; 
        endcase
    end


endmodule

module bcdaddsub4(
    input logic [15:0] a, b,
    input logic op, 
    output logic [15:0] s,
    //output logic co
);
    logic [15:0] b_temp;
    bcd9comp1 comp0(.in(b[3:0]), .out(b_temp[3:0]));
    bcd9comp1 comp1(.in(b[7:4]), .out(b_temp[7:4]));
    bcd9comp1 comp2(.in(b[11:8]), .out(b_temp[11:8]));
    bcd9comp1 comp3(.in(b[15:12]), .out(b_temp[15:12]));
    
    logic [15:0] b_in;


   always_comb begin
    if (op == 1) begin
        b_in = b_temp;
        
    end 
    else
    begin
        b_in = b;
        
        
    end
    
   end
   
    bcdadd4 adder(.a(a), .b(b_in), .ci(op), .s(s), .co());


endmodule
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

  // Your code goes here...
    lunarlander ll (
        .hz100(hz100), .reset(reset), .in(pb[19:0]), 
        .red(red), .green(green),                       // for crashed/landed
        .ss0(ss0), .ss1(ss1), .ss2(ss2), .ss3(ss3),     // for values
        .ss5(ss5), .ss6(ss6), .ss7(ss7)                 // for display message
    );
  
endmodule
// Add more modules down here...

module lunarlander #(
    parameter FUEL=16'h800,
    parameter ALTITUDE=16'h4500,
    parameter VELOCITY=16'h0,
    parameter THRUST=16'h5,
    parameter GRAVITY=16'h5
)
(
    input logic hz100, reset,
    input logic [19:0] in,
    output logic [7:0] ss7, ss6, ss5, 
    output logic [7:0] ss3, ss2, ss1, ss0,
    output logic red, green
);
endmodule

module keysync (
    input logic clk,
    input logic rst,
    input logic [19:0] keyin,
    output logic [4:0] keyout,
    output logic keyclk
);
    
    assign keyout[0] = keyin[1] | keyin[3] | keyin[5] | 
                    keyin[7] | keyin[9] | keyin[11] |
                    keyin[13] | keyin[15] | keyin[17] |
                    keyin[19];


    assign keyout[1] = keyin[2] | keyin[3] | keyin[6] |
                    keyin[7] | keyin[10] | keyin[11] |
                    keyin[14] | keyin[15] | keyin[18] |
                    keyin[19];

    assign keyout[2] = keyin[4] | keyin[5] | keyin[6] |
                    keyin[7] | keyin[12] | keyin[13] |
                    keyin[14] | keyin[15];
    
    assign keyout[3] = keyin[8] | keyin[9] | keyin[10] |
                    keyin[11] | keyin[12] | keyin[13] |
                    keyin[14] | keyin[15];
    
    assign keyout[4] = keyin[16] | keyin[17] | keyin[18] |
                    keyin[19];


    logic signal_press;
    assign signal_press = |keyin;

    logic ff1, ff2;

    always_ff @( posedge clk or posedge rst ) begin
        
        if (rst) begin
            ff1 <= 1'b0;
            ff2 <= 1'b0;
           
        end 
        else begin
            ff1 <= signal_press;
            ff2 <= ff1;
            
        end


    end

    assign keyclk = ff2;

endmodule

module clock_psc (
    input logic clk,
    input logic rst,
    input logic [7:0] lim,
    output logic hzX
);
// Your code goes here...
    logic [7:0] count;
    logic hzX_loop;
    


    always_ff @( posedge clk or posedge rst ) begin 
        if (rst == 1) begin
            hzX_loop <= 0;
            count <= 0;
        end
        else begin

            if (lim != 0) begin
            if (count == lim) begin
                hzX_loop <= ~hzX_loop;
                count <= 0;
            end
            else begin
                count <= count + 1;
            end

        end

        end

        
        


        
    end

    assign hzX = (lim == 0) ? clk : hzX_loop;
endmodule

module ssdec(
    input logic [3:0] in,
    input logic enable,
    output logic [6:0] out
);

//manuallly assign all seven 
//got from the github ref file

    logic [6:0] light [15:0];

    //nums
    assign light[0] = 7'b0111111; 
    assign light[1] = 7'b0000110;
    assign light[2] = 7'b1011011;    
    assign light[3] = 7'b1001111;
    assign light[4] = 7'b1100110;
    assign light[5] = 7'b1101101;
    assign light[6] = 7'b1111101;
    assign light[7] = 7'b0000111;
    assign light[8] = 7'b1111111;
    assign light[9] = 7'b1100111;

    //letters
    assign light[10] = 7'b1110111;
    assign light[11] = 7'b1111100;
    assign light[12] = 7'b0111001;
    assign light[13] = 7'b1011110;
    assign light[14] = 7'b1111001;
    assign light[15] = 7'b1110001;


    assign out = enable ? light[in] : 7'b0000000;



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
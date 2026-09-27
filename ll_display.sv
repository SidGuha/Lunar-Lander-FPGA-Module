
module ll_display (
    input logic clk,
    input logic rst,
    input logic land,
    input logic crash,

    input logic [3:0] disp_ctrl,

    input logic [15:0] alt,
    input logic [15:0] vel,
    input logic [15:0] fuel,
    input logic [15:0] thrust,

    output logic [7:0] ss7,
    output logic [7:0] ss6,
    output logic [7:0] ss5,

    output logic [7:0] ss3,
    output logic [7:0] ss2,
    output logic [7:0] ss1,
    output logic [7:0] ss0,

    output logic red,
    output logic green
);

    //which thingy to display
    logic [3:0] mode;

    always_ff @( posedge clk or posedge rst ) begin 
        if (rst) begin
            mode<= 4'b1000; 
        end
        else if (disp_ctrl != 4'b0000) 
        begin
            mode <= disp_ctrl;
        end
        
        
    end

    logic [15:0] int_value;

    //check if vel is negative    

    logic check;

    

    always_comb begin 
        case (mode)
            4'b1000: int_value = alt;
            4'b0100: int_value = vel;
            4'b0010: int_value = fuel;
            4'b0001: int_value = thrust;
            default: int_value = alt;
        endcase
        
    end

    assign check = (int_value[15:12] == 4'd9) ? 1 : 0;

    logic [15:0] temp_neg_val;
    bcdaddsub4 as0(.a(16'b0), .b(int_value), .op(1), .s(temp_neg_val)); 

    logic [15:0] val_fin;
    assign val_fin = (check) ? temp_neg_val : int_value;

    logic [6:0] ss3_test;

    ssdec d0(.in(val_fin[3:0]), .enable(1'b1), .out(ss0[6:0]));

    logic enable_1;
    assign enable_1 = (val_fin[15:4] != 0) ? 1 : 0;
    ssdec d1(.in(val_fin[7:4]), .enable(enable_1), .out(ss1[6:0]));

    logic enable_2;
    assign enable_2 = (val_fin[15:8] != 0) ? 1 : 0;
    ssdec d2(.in(val_fin[11:8]), .enable(enable_2), .out(ss2[6:0]));

    logic enable_3;
    assign enable_3 = (val_fin[15:12] != 0) ? 1 : 0;
    ssdec d3(.in(val_fin[15:12]), .enable(enable_3), .out(ss3_test[6:0]));


    always_comb begin 
        if (check) begin
            ss3 = 8'b01000000;
            
        end
        else 
        begin
            ss3 = {1'b0, ss3_test};
            
        end
        
    end

    assign ss0[7] = 0;
    assign ss1[7] = 0;
    assign ss2[7] = 0;
    



    always_comb begin 
        case (mode)
            4'b1000: {ss7, ss6, ss5} = 24'b01110111_00111000_01111000;  // alt
            4'b0100: {ss7, ss6, ss5} = 24'b00111110_01111001_00111000;  // vel
            4'b0010: {ss7, ss6, ss5} = 24'b01101111_01110111_01101101; // gas
            4'b0001: {ss7, ss6, ss5} = 24'b01111000_01110110_01010000;  // thr
            default: {ss7, ss6, ss5} = 24'b01110111_00111000_01111000;  // default to ALT
        endcase
    end
    assign red = crash;
    assign green = land;


endmodule
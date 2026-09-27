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

    logic [15:0] alt;
    logic [15:0] vel;
    logic [15:0] fuel;
    logic [15:0] thrust;
    logic [15:0] alt_n;
    logic [15:0] vel_n;
    logic [15:0] fuel_n;
    logic [15:0] thrust_n;
    logic [3:0] disp_ctrl;

    logic land;
    logic crash;
    logic wen;

    logic [4:0] keyout;
    logic keyclk;
    logic clk;

    keysync keys(.clk(hz100), .rst(reset), .keyin(in), .keyout(keyout), .keyclk(keyclk));

    always_ff @(posedge keyclk) 
    begin
        if (~keyout[4]) 
        begin
            thrust_n <= {12'b0, keyout[3:0]};
        end
    end

    always_comb begin
        case(keyout)
            5'b10000: disp_ctrl = 4'b0001;
            5'b10001: disp_ctrl = 4'b0010;
            5'b10010: disp_ctrl = 4'b0100;
            5'b10011: disp_ctrl = 4'b1000;
            default: disp_ctrl = 4'b0000;
        endcase
    end

    clock_psc clock_module(.clk(hz100), .lim(8'd24), .rst(reset), .hzX(clk));

    ll_alu alu(.alt(alt), .vel(vel), .fuel(fuel), .thrust(thrust), .alt_n(alt_n), .vel_n(vel_n), .fuel_n(fuel_n));
    

    ll_control control(.clk(clk), .rst(reset), .alt(alt), .vel(vel), .land(land), .crash(crash), .wen(wen));

    ll_memory memory(.clk(clk), .rst(reset), .wen(wen), .alt_n(alt_n), .vel_n(vel_n), .fuel_n(fuel_n), .thrust_n(thrust_n), .alt(alt), .vel(vel), .fuel(fuel), .thrust(thrust));

    ll_display display(.clk(keyclk), .rst(reset), .land(land), .crash(crash), .disp_ctrl(disp_ctrl), .alt(alt), .vel(vel), .fuel(fuel), .thrust(thrust), .ss7(ss7), .ss6(ss6), .ss5(ss5), .ss3(ss3), .ss2(ss2), .ss1(ss1), .ss0(ss0), .red(red), .green(green));
  
  
endmodule


// CLOCK PRESCALER MODULE
module clock_psc (
    input logic clk,
    input logic rst,
    input logic [7:0] lim,
    output logic hzX
    );

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


// KEYSYNC MODULE 
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

// MEMORY
module ll_memory(
    input logic clk,
    input logic rst,
    input logic wen,

    input logic [15:0] alt_n,
    input logic [15:0] vel_n,
    input logic [15:0] fuel_n,
    input logic [15:0] thrust_n,

    output logic [15:0] alt,
    output logic [15:0] vel,
    output logic [15:0] fuel,
    output logic [15:0] thrust

);

    parameter [15:0] ALTITUDE = 16'h4500;
    parameter [15:0] VELOCITY = 16'h0;
    parameter [15:0] FUEL = 16'h800;
    parameter [15:0] THRUST = 16'h5;

    always_ff @( posedge clk or posedge rst) begin 
        
            
        if (rst) begin
            alt <= ALTITUDE;
            vel <= VELOCITY;
            fuel <= FUEL;
            thrust <= THRUST;

        end

        else
        begin
            if (wen) begin
                alt <= alt_n;
                vel <= vel_n;
                fuel <= fuel_n;
                thrust <= thrust_n;
                
            end
            
        end

        
    end
endmodule

// CONTROL MODULE
module ll_control (
    input logic clk,
    input logic rst,
    input logic [15:0] alt,
    input logic [15:0] vel,
    
    output logic land,
    output logic crash,
    output logic wen
);

    logic [15:0] sum_alt_vel;

    

    bcdaddsub4 alt_plus_vel(
        .a(alt),
        .b(vel),
        .op(1'b0),
        .s(sum_alt_vel)
    );
    logic int_gnd;
    //hit ground or nah

    assign int_gnd = (sum_alt_vel == 16'h0) || (sum_alt_vel[15:12] == 4'd9) ? 1 : 0;

    //test safe land
    //test crash land
    logic int_crash, int_land;





    always_comb begin 
        if (int_gnd == 1 && vel < 16'h9970) 
        begin
            int_crash = 1;
            int_land = 0;
        end
        else if (int_gnd == 1 && vel >= 16'h9970) 
        begin
            int_land = 1;
            int_crash = 0;
        end
        else 
        begin
            int_land = 0;
            int_crash = 0;
        end
    

        
    end 

    always_ff @( posedge clk or posedge rst ) begin 

        if (rst == 1) begin
            land <= 0;
            crash <= 0;
            wen <= 0;
        end
        else
        begin
            wen <= ~int_land & ~int_crash;            
            land <= int_land;
            crash <= int_crash;
        end
        
        
    end
endmodule

// ALU MODULE
module ll_alu (
    input logic [15:0] alt,
    input logic [15:0] vel,
    input logic [15:0] fuel,
    input logic [15:0] thrust,

    output logic [15:0] alt_n,
    output logic [15:0] vel_n,
    output logic [15:0] fuel_n
);



    parameter GRAVITY = 16'h5;

    logic [15:0] altc;
    logic [15:0] velc;
    logic [15:0] fuelc;

    bcdaddsub4 add_alt (
        .a(alt),
        .b(vel),
        .op(1'b0),
        .s(altc)
    );

    bcdaddsub4 fuel_sub (
        .a(fuel),
        .b(thrust),
        .op(1'b1),
        .s(fuelc)
    );

    logic [15:0] vel1;

    bcdaddsub4 grav0(
        .a(vel),
        .b(GRAVITY),
        .op(1'b1),
        .s(vel1)
    );

    logic [15:0] thrust_used;

    assign thrust_used = (fuel == 16'h0) ? 16'h0 : thrust;
    
    bcdaddsub4 add_thrust (
        .a(vel1),
        .b(thrust_used),
        .op(1'b0),
        .s(velc)
    );



    always_comb  begin
        if (altc == 16'h0 || altc[15:12] == 4'd9) begin
            alt_n = 16'h0;
            vel_n = 16'h0;
        end 
        else begin
            alt_n = altc;
            vel_n = velc;
            
        end

        if (fuelc == 16'h0 || fuelc[15:12] == 4'd9) begin
            fuel_n = 16'h0;
        end 
        else begin
            fuel_n = fuelc;
        end


        
    end
endmodule

// DISPLAY MODULE
    
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
// Your code goes here...
    //which thingy to display
    logic [3:0] mode;

    always_ff @( posedge clk or posedge rst ) begin 
        if (rst) begin
            mode<= 4'b0001; 
        end
        else if (disp_ctrl != 4'b0000) 
        begin
            mode <= disp_ctrl;
        end
        
        
    end

    logic [15:0] int_value;

    //check if vel is negative    

    logic check;

    //assign check = (int_value[15:12] == 4'd9) ? 1 : 0;

    always_comb begin 
        case (mode)
            4'b1000: int_value = thrust;
            4'b0100: int_value = fuel;
            4'b0010: int_value = vel;
            4'b0001: int_value = alt;
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
    //assign ss3[7] = 0;



    always_comb begin 
        case (mode)
            4'b1000: {ss7, ss6, ss5} = 24'b01111000_01110110_01010000;  // thrust (says THR)
            4'b0100: {ss7, ss6, ss5} = 24'b01101111_01110111_01101101;  // fuel (says GAS)
            4'b0010: {ss7, ss6, ss5} = 24'b00111110_01111001_00111000;  // VEL
            4'b0001: {ss7, ss6, ss5} = 24'b01110111_00111000_01111000;  // ALT
            default: {ss7, ss6, ss5} = 24'b01110111_00111000_01111000;  // default to ALT
        endcase
    end
    assign red = crash;
    assign green = land;


endmodule

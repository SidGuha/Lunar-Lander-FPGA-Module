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

    assign int_gnd = ((sum_alt_vel == 16'h0) || (sum_alt_vel[15:12] == 4'd9)) ? 1 : 0;

    //test safe land
    //test crash land
    logic int_crash, int_land;
    

    //intermediate vasr
    logic land_n;
    logic crash_n;
    logic wen_n;


    logic vel_neg;
    logic var_fast;



    assign vel_neg = (vel[15:12] == 4'h9) ? 1 : 0;

    assign var_fast = (vel_neg) && (vel < 16'h9970);



    always_comb begin 

        land_n = land;

        crash_n = crash;
        wen_n = wen;
        if (land == 0 && crash == 0) 
        begin
            
        
            if (int_gnd == 1 && var_fast) 
            begin
                int_crash = 1;
                int_land = 0;
                crash_n = 1;
                wen_n = 0;

            end
            else if (int_gnd == 1) 
            begin
                int_land = 1;
                int_crash = 0;
                land_n = 1;
                wen_n = 0;
            end
            else 
            begin
                int_land = 0;
                int_crash = 0;
                wen_n = 1;
            end
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
            wen <= wen_n;            
            land <= land_n;
            crash <= crash_n;
        end
        
        
    end







endmodule
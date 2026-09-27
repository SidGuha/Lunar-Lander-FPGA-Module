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
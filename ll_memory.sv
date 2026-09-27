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
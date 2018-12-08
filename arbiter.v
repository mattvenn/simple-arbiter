`default_nettype none

module arbiter
#(
    parameter       NUM_WRITERS = 2
)
(
    input                           i_clk,
    input                           i_reset,

    input [7:0]                     i_data,     // incoming data bus
    input [NUM_WRITERS-1:0]         i_req,      // write request from Writer module
    output reg [NUM_WRITERS-1:0]    o_busy,     // busy line, Writer must keep data

    output                          o_we,       // write to FIFO
    output [7:0]                    o_data      // data out
);
    
    initial begin
        o_busy = {NUM_WRITERS{1'b1}};
    end

    always @(posedge i_clk) begin
        o_busy[0] <= 0;
    end

    `ifdef FORMAL
        
        // past valid signal
        reg f_past_valid = 0;
        always @(posedge i_clk)
            f_past_valid <= 1'b1;

        // start in i_reset
        initial restrict(i_reset);
        initial assert(o_busy == {NUM_WRITERS{1'b1}});

        // count busy lines
        reg [1:0] busy_lines;  //initialize count variable.

        integer i;
        always @(*) begin
            busy_lines = 0;
            for(i=0;i<NUM_WRITERS;i=i+1)
                if(o_busy[i] == 1'b1)
                    busy_lines = busy_lines + 1;
        end
            
        
        always @(posedge i_clk)
            if(f_past_valid)
                assert(busy_lines >= NUM_WRITERS -1);

        always @(posedge i_clk)
            cover(busy_lines == NUM_WRITERS - 1);

    `endif
endmodule

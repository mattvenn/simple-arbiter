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

    reg [$clog2(NUM_WRITERS)-1:0] next_access = 0;

    // pass data straight through
    assign o_data = i_data;

    // bus arbiter
    always @(posedge i_clk) begin
        if(&o_busy) begin
            if(i_req) begin
                for(i=0;i<NUM_WRITERS;i=i+1)
                    if(i_req[i])
                        next_access <= i;
                o_busy[next_access] <= 0;
            end
        end else
            o_busy <= {NUM_WRITERS{1'b1}};
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
        reg [$clog2(NUM_WRITERS):0] busy_lines;  //initialize count variable.
        integer i;
        always @(*) begin
            busy_lines = 0;
            for(i=0;i<NUM_WRITERS;i=i+1)
                if(o_busy[i] == 1'b1)
                    busy_lines = busy_lines + 1;
        end
        
        // assert that only one writer gets access at once
        always @(posedge i_clk)
            assert(busy_lines >= NUM_WRITERS -1);

        // assume writers don't drop request line until getting access
        always @(posedge i_clk)
            if(f_past_valid) begin
                for(i=0;i<NUM_WRITERS;i=i+1) begin
                    if($past(o_busy[i]))
                        assume($stable(i_req[i]));
                end
            end

        // assume that in data is ZZ until busy line goes low
        always @(posedge i_clk)
            if(&o_busy)
                assume(i_data == 8'hZZ);

        // cover the case when all writers are requesting at once
        always @(posedge i_clk)
            cover(&i_req);

    `endif
endmodule

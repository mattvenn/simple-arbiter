`default_nettype none

module arbiter
#(
    parameter       NUM_WRITERS = 2
)
(
    input                           i_clk,
    input                           i_reset,

    input [NUM_WRITERS-1:0]         i_req,      // write request from Writer module
    output reg [NUM_WRITERS-1:0]    o_busy,     // busy line, Writer must keep data

    output                          o_we,       // write to FIFO
);
    
    initial begin
        o_busy = {NUM_WRITERS{1'b1}};
        next_access = 0;
    end

    reg [$clog2(NUM_WRITERS)-1:0] next_access = 0;

    // bus arbiter
    always @(posedge i_clk) begin
        if(&o_busy) begin
            if(i_req) begin
                for(i=0;i<NUM_WRITERS;i=i+1)
                    if(i_req[i])
                        next_access = i;
                o_busy[next_access] <= 0;
            end
        end else
            o_busy <= {NUM_WRITERS{1'b1}};
    end

    `ifdef FORMAL

        writer #(.COUNTER_MAX(3)) writer_0 (.i_clk(i_clk), .i_reset(i_reset), .i_busy(o_busy[0]), .o_req(i_req[0]));    
        writer #(.COUNTER_MAX(3)) writer_1 (.i_clk(i_clk), .i_reset(i_reset), .i_busy(o_busy[1]), .o_req(i_req[1]));    
        
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

        // count request lines
        reg [$clog2(NUM_WRITERS):0] req_lines;  //initialize count variable.
        always @(*) begin
            req_lines = 0;
            for(i=0;i<NUM_WRITERS;i=i+1)
                if(i_req[i] == 1'b1)
                    req_lines = req_lines + 1;
        end
        
        // assert that only one writer gets access at once
        always @(posedge i_clk)
            assert(busy_lines >= NUM_WRITERS -1);

        // assert that nothing requesting, all lines are busy
        always @(posedge i_clk)
            if(f_past_valid)
                if($past(!i_reset) && req_lines == 0)
                    assert(&o_busy);

        // assert that if nothing requesting, when req recieved, get access next clock
        always @(posedge i_clk)
            if(f_past_valid)
                for(i=0;i<NUM_WRITERS;i=i+1)
                    if($past(!i_reset) && !i_reset && &o_busy && $past(i_req[i]) && $past(req_lines == 1))
                        assert(!$past(o_busy[i]));

        // assume writers don't drop request line until getting access
        /*
        always @(posedge i_clk)
            if(f_past_valid) begin
                for(i=0;i<NUM_WRITERS;i=i+1) begin
                    if($past(o_busy[i]))
                        assume($stable(i_req[i]));
                end
            end
        */

        // cover the case when all writers are requesting at once
        always @(posedge i_clk)
            if(f_past_valid)
                cover($past(!i_reset) && &i_req);

    `endif
endmodule

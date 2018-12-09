`default_nettype none

module arbiter
#(
    parameter       NUM_WRITERS = 2
)
(
    input                           i_clk,
    input                           i_reset,

    input [NUM_WRITERS*8-1:0]       i_data,     // input data for all the writers
    input [NUM_WRITERS-1:0]         i_req,      // write request from Writer module
    output reg [NUM_WRITERS-1:0]    o_busy,     // busy line, Writer must keep data
    output reg [7:0]                o_data,

    output reg                      o_we,       // write to FIFO
);
    
    initial begin
        o_busy = {NUM_WRITERS{1'b1}};
        next_access = 0;
    end

    reg [$clog2(NUM_WRITERS)-1:0] next_access = 0;

    always @(posedge i_clk) begin
        for(i=0;i<NUM_WRITERS;i=i+1)
            if(i_req[i] && !o_busy[i])
                o_data <= i_data[i*8+7:i*8];

        o_we <= ! &o_busy;
    end

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
        // create the writer modules
        generate
            genvar j;
            for(j=0;j<NUM_WRITERS;j=j+1)
                writer #(.COUNTER_MAX(3+j)) writer_inst (.i_clk(i_clk), .i_reset(i_reset), .i_busy(o_busy[j]), .o_req(i_req[j]), .o_data(i_data[j*8+7:j*8]));
        endgenerate

        reg [3:0] records;
        reg o_re = 0; // never read from the fifo
        fifo fifo_inst(.clk(i_clk), .reset(i_reset), .re(o_re), .we(o_we), .wdata(o_data), .records(records));
        
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

        // assert that o_we goes high when write is requested
        always @(posedge i_clk)
            if(f_past_valid)
                if($past(!i_reset) && $past(busy_lines == 1))
                    assert(o_we);

        // assert that once o_we is high, data out is stable
        always @(posedge i_clk)
            if(f_past_valid)
                if($past(o_we))
                    assert($stable(o_data));

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

        always @(posedge i_clk)
            cover(records == 4);
    `endif
endmodule

`default_nettype none

module writer
#(
    parameter       COUNTER_MAX = 5,
    parameter       DATA_W      = 8
)
(
    input               i_clk,
    input               i_reset,
    
    input               i_busy,
    output reg          o_req,
    output reg [DATA_W-1:0]    o_data
);

    localparam STATE_START  = 0;
    localparam STATE_RUN    = 1;
    localparam STATE_REQ    = 2;
    localparam STATE_END    = 3;

    reg [$clog2(STATE_END)-1:0] state = STATE_RUN;
    reg [$clog2(COUNTER_MAX)-1:0] counter = 0;

//    assign o_data = (i_busy == 0 && o_req == 1) ? counter : 8'hZZ;

    always @(posedge i_clk) begin
        if(i_reset) begin
            state <= STATE_START;
            counter <= 0;
            o_req <= 0;
        end else case(state)
            STATE_START: begin
                counter <= 0;
                o_req <= 0;
                state <= STATE_RUN;
            end

            STATE_RUN: begin
                counter <= counter + 1;
                if(counter == COUNTER_MAX - 1)
                    state <= STATE_REQ;
            end

            STATE_REQ: begin
                o_req <= 1;
                o_data <= counter;
                if(i_busy == 0) begin
                    state <= STATE_START;
                    o_req <= 0;
                end
            end
        endcase
    end    

    `ifdef FORMAL
        
        // past valid signal
        reg f_past_valid = 0;
        always @(posedge i_clk)
            f_past_valid <= 1'b1;

        // start in i_reset
        initial restrict(i_reset);

        // don't let induction get counter over limit
        always @(posedge i_clk)
            assume(counter <= COUNTER_MAX);

        // state machine stays bounded
        always @(posedge i_clk)
            assert(state < STATE_END);

        // after requesting, don't drop till get no busy, and don't change data
        always @(posedge i_clk)
            if(f_past_valid)
                if(!$past(i_reset) && $past(o_req) && $past(i_busy)) begin
                    assert($stable(o_req));
                    assert($stable(o_data));
                end

        // after getting no busy, assert req is dropped after 1 cycle
        always @(posedge i_clk)
            if(f_past_valid)
                if(!$past(i_reset) && $past(o_req) && $past(!i_busy))
                    assert(!o_req);


        // cover requesting write while arbiter is busy
        always @(posedge i_clk)
            if(f_past_valid)
                cover(state == STATE_REQ && o_req && i_busy);

    `endif
endmodule

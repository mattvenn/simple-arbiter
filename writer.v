`default_nettype none

module writer
#(
    parameter       COUNTER_MAX = 10
)
(
    input           i_clk,
    input           i_reset,
    
    input           i_busy,
    output reg      o_req,
    output [7:0]    o_data
);

    localparam STATE_START  = 1;
    localparam STATE_RUN    = 2;
    localparam STATE_REQ    = 3;
    localparam STATE_END    = 4;

    reg [$clog2(STATE_END)-1:0] state = STATE_RUN;
    reg [7:0] counter = 0;

    assign o_data = (i_busy == 0 && o_req == 1) ? counter : 8'hZZ;

    always @(posedge i_clk) begin
        if(i_reset) begin
            state <= STATE_START;
            counter <= 0;
            o_req <= 0;
        end
        case(state)
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

        always @(posedge i_clk)
            assert(state < STATE_END);

        always @(posedge i_clk)
            if(f_past_valid)
                cover(state == STATE_REQ && o_req == 1 && i_busy == 1);

    `endif
endmodule

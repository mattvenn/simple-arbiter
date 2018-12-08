`default_nettype none

module writer
#(
    parameter       COUNTER_MAX = 10
)
(
    input           clk,
    input           reset,
    
    input           busy,
    output reg      req,
    output [7:0]    data
);

    localparam STATE_START  = 1;
    localparam STATE_RUN    = 2;
    localparam STATE_REQ    = 3;
    localparam STATE_END    = 4;

    reg [$clog2(STATE_END)-1:0] state = STATE_RUN;
    reg [7:0] counter = 0;

    assign data = (busy == 0 && req == 1) ? counter : 8'hZZ;

    always @(posedge clk) begin
        if(reset) begin
            state <= STATE_START;
            counter <= 0;
            req <= 0;
        end
        case(state)
            STATE_START: begin
                counter <= 0;
                req <= 0;
                state <= STATE_RUN;
            end

            STATE_RUN: begin
                counter <= counter + 1;
                if(counter == COUNTER_MAX - 1)
                    state <= STATE_REQ;
            end

            STATE_REQ: begin
                req <= 1;
                if(busy == 0) begin
                    state <= STATE_START;
                    req <= 0;
                end
            end
        endcase
    end    

    `ifdef FORMAL
        
        // past valid signal
        reg f_past_valid = 0;
        always @(posedge clk)
            f_past_valid <= 1'b1;

        // start in reset
        initial restrict(reset);

        always @(posedge clk)
            assert(state < STATE_END);

        always @(posedge clk)
            if(f_past_valid)
                cover(state == STATE_REQ && req == 1 && busy == 1);

    `endif
endmodule

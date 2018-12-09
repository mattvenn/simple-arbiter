/*
FIFO

Matt Venn 2017

*/
`default_nettype none
module fifo #(
parameter DW = 8,  // data width
parameter AW = 3)  // address width
(
	input wire clk,
    input wire reset,

    input wire [DW-1: 0] wdata, // input
    input wire we,

    output reg [DW-1: 0] rdata, // output
    input wire re,

    output reg [AW-1: 0] records = 0,
    output wire overflow 
    );

    localparam NPOS = 2 ** AW;

    reg [AW-1: 0] rd_ptr = 0;
    reg [AW-1: 0] wr_ptr = 0;

    reg [DW-1: 0] bram [0: NPOS-1];

    assign overflow = (records >= NPOS-1);


    always @(posedge clk) begin
        if(reset) begin
            rd_ptr <= 0;
            wr_ptr <= 0;
            records <= 0;
        end else begin
          if(re) begin
              if(records > 0) begin
                  rd_ptr <= rd_ptr + 1;
                  records <= records - 1;
              end
          end
          if(we) begin
              if(records < NPOS - 1) begin
                  wr_ptr <= wr_ptr + 1;
                records <= records + 1;
              end
          end
        end
    end

    always @(posedge clk) begin
        if (!reset && re && (records > 0))
            rdata <= bram[rd_ptr];
    end

    always @(posedge clk) begin
        if (!reset && we && (records < NPOS - 1))
            bram[wr_ptr] <= wdata;
    end


    `ifdef FORMAL
        // all this mostly from https://zipcpu.com/blog/2017/10/19/formal-intro.html

        // past valid signal
        reg f_past_valid = 0;
        always @(posedge clk)
            f_past_valid <= 1'b1;

        // start in reset
        initial begin
            assume(reset);
            assume(bram[0] == 0);
            assume(bram[1] == 0);
            assume(bram[2] == 0);
            assume(bram[3] == 0);
            assume(bram[4] == 0);
            assume(bram[5] == 0);
            assume(bram[6] == 0);
            assume(bram[7] == 0);
        end



        // check overflow goes high with enough records
        always @(posedge clk)
            if(records >= NPOS - 1)
                assert(overflow);

        // check everything is zeroed on the reset signal
        always @(posedge clk)
            if (f_past_valid) begin
                if ($past(reset)) begin
                    assert(rd_ptr == 0);
                    assert(wr_ptr == 0);
                    assert(records == 0);
                    assert(overflow == 0);
                end
            end
                    
        // assert that read pointer doesn't change in underflow condition
        always @(posedge clk)
            if (f_past_valid && !$past(reset))
                if (($past(re))&&($past(records == 0)))
                    assert(rd_ptr == $past(rd_ptr));

        // assert that write pointer doesn't change in overflow condition
        always @(posedge clk)
            if (f_past_valid && !$past(reset))
                if (($past(we))&&($past(overflow)))
                    assert(wr_ptr == $past(wr_ptr));

        always @(posedge clk) begin
            cover(f_past_valid && we);
            cover(overflow);
            if(f_past_valid)
                cover($past(records == 0 && we == 1) && bram[wr_ptr] == 4);
        end

    `endif

endmodule

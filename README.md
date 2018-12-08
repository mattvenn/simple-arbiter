# FIFO arbiter

many modules want to store records to a FIFO. Instead of using 1 FIFO per module,
use an arbiter to grant FIFO write access.

## FIFO definition

just the data writing side

    input [7:0] i_data,                     // data input
    input i_we,                             // high to write the data to FIFO

## Writer module definition

    output [7:0] o_data,                    // data to write Z when arbiter is busy
    output o_req,                           // signal ready to write data
    input  i_busy,                          // arbiter busy

## Arbiter module definition

    input [7:0] i_data,                     // incoming data bus
    input [NUM_WRITERS-1:0] i_req           // write request from Writer module
    output [NUM_WRITERS-1:0] o_busy         // busy line, Writer must keep data

    output o_we,                            // write to FIFO
    output [7:0] o_data                     // data out

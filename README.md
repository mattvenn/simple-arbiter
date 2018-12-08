# FIFO arbiter

many modules want to store records to a FIFO. Instead of using 1 FIFO per module,
use an arbiter to grant FIFO write access.

## FIFO definition

just the data writing side

    input [7:0] wdata,                      // data input
    input we,                               // high to write the data to FIFO

## Writer module definition

    output [7:0] data,                      // data to write Z when arbiter is busy
    output re,                              // when the data is ready to be read
    input  busy,                            // arbiter busy

## Arbiter module definition

    input [7:0] i_data,                     // incoming data bus
    input [NUM_MODULES-1:0] req             // write request from Writer module
    output [NUM_MODULES-1:0] busy           // busy line, Writer must keep data

    output we,                              // write to FIFO
    output [7:0] o_data                     // data out

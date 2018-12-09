# FIFO arbiter

many modules want to store records to a FIFO. Instead of using 1 FIFO per module,
use an arbiter to grant FIFO write access.

## FIFO definition

just the data writing side

    input [7:0] i_data,                     // data input
    input i_we,                             // high to write the data to FIFO

## Writer module definition

    output [7:0] o_data,                    // data to write
    output o_req,                           // signal ready to write data
    input  i_busy,                          // arbiter busy

## Arbiter module definition

    input [NUM_WRITERS*8-1:0] i_data,       // incoming data bus
    input [NUM_WRITERS-1:0] i_req           // write request from Writer module
    output [NUM_WRITERS-1:0] o_busy         // busy line, Writer must keep data

    output o_we,                            // write to FIFO
    output [7:0] o_data                     // data out

# Questions

## bus sharing

tried to use a single 8 bit bus with writers setting output to z when not
granted access. This didn't work with yosys tristate stuff.

So made a i_data large enough for all o_data. But get this warning:

    Warning: multiple conflicting drivers for arbiter.\i_data [1]:

Also, any way of parameterising the input into multiple ports instead of one
large bus?

Also, if bus can be set to zz, could I avoid channeling all writer's o_data into
i_data? And join all the o_data into 1 bus and then connect this direct to fifo.

## assumption/assume affects cover

writer.v asserts that it will behave correctly in terms of not dropping req
until !busy. arbiter.v assumes this behaviour. With both assumption and
assertion the cover never works.

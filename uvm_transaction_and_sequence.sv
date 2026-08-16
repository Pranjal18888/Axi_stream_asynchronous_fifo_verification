//=====================================================================
// axis_async_testbench.sv
// Complete UVM Testbench for AXI4-Stream Asynchronous FIFO (dual clock)
// EDA Playground -> "Testbench Files" section me daalein
//=====================================================================
`include "uvm_macros.svh"
import uvm_pkg::*;

//=====================================================================
// 1) Sequence Item / Transaction
//=====================================================================
class axis_transaction extends uvm_sequence_item;

  rand bit [31:0]   tdata;
  rand bit          tlast;
       int unsigned wait_cycles;

  constraint data_range_c { tdata < 32'h1000_0000; }

  `uvm_object_utils_begin(axis_transaction)
    `uvm_field_int(tdata,       UVM_ALL_ON)
    `uvm_field_int(tlast,       UVM_ALL_ON)
    `uvm_field_int(wait_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "axis_transaction");
    super.new(name);
  endfunction

endclass : axis_transaction


//=====================================================================
// 2) Sequence - random length packets (TLAST har packet ke end pe)
//=====================================================================
class axis_packet_sequence extends uvm_sequence #(axis_transaction);
  `uvm_object_utils(axis_packet_sequence)

  int num_packets       = 4;
  int max_beats_per_pkt = 5;

  function new(string name = "axis_packet_sequence");
    super.new(name);
  endfunction

  task body();
    axis_transaction tr;
    int beats;

    repeat (num_packets) begin
      beats = $urandom_range(1, max_beats_per_pkt);
      for (int i = 0; i < beats; i++) begin
        tr = axis_transaction::type_id::create("tr");
        start_item(tr);
        if (!tr.randomize() with { tlast == (i == beats-1); })
          `uvm_error("SEQ", "Randomization failed")
        finish_item(tr);
      end
    end
  endtask

endclass : axis_packet_sequence

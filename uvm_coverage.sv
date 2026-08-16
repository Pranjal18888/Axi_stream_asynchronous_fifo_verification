//=====================================================================
// 7) Functional Coverage
//=====================================================================
class axis_coverage extends uvm_subscriber #(axis_transaction);
  `uvm_component_utils(axis_coverage)

  axis_transaction tr;

  covergroup cg;
    option.per_instance = 1;

    cp_data : coverpoint tr.tdata {
      bins low  = {[0             : 32'h0555_5555]};
      bins mid  = {[32'h0555_5556 : 32'h0AAA_AAAA]};
      bins high = {[32'h0AAA_AAAB : 32'h0FFF_FFFF]};
    }

    cp_tlast : coverpoint tr.tlast {
      bins last_beat = {1};
      bins mid_beat  = {0};
    }

    cp_wait : coverpoint tr.wait_cycles {
      bins zero_wait  = {0};
      bins one_wait   = {1};
      bins multi_wait = {[2:$]};
    }

    cx_last_wait : cross cp_tlast, cp_wait;

  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function void write(axis_transaction t);
    tr = t;
    cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("===> Functional Coverage = %0.2f%%", cg.get_coverage()), UVM_NONE)
  endfunction

endclass : axis_coverage

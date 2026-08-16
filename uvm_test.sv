//=====================================================================
// 9) Test
//=====================================================================
class axis_base_test extends uvm_test;
  `uvm_component_utils(axis_base_test)

  axis_env env;

  function new(string name = "axis_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = axis_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);
    axis_packet_sequence seq;
    phase.raise_objection(this);
    seq = axis_packet_sequence::type_id::create("seq");
    seq.num_packets       = 5;
    seq.max_beats_per_pkt = 6;
    seq.start(env.agt.sqr);
    #2000;
    phase.drop_objection(this);
  endtask

endclass : axis_base_test

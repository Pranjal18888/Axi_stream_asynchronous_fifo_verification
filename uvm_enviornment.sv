//=====================================================================
// 8) Environment
//=====================================================================
class axis_env extends uvm_env;
  `uvm_component_utils(axis_env)

  axis_agent        agt;
  axis_scoreboard    scb;
  axis_in_listener   in_lsnr;
  axis_out_listener  out_lsnr;
  axis_coverage      cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt      = axis_agent::type_id::create("agt", this);
    scb      = axis_scoreboard::type_id::create("scb", this);
    in_lsnr  = axis_in_listener::type_id::create("in_lsnr", this);
    out_lsnr = axis_out_listener::type_id::create("out_lsnr", this);
    cov      = axis_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    in_lsnr.scb  = scb;
    out_lsnr.scb = scb;
    agt.mon.ap_in.connect(in_lsnr.analysis_export);
    agt.mon.ap_out.connect(out_lsnr.analysis_export);
    agt.mon.ap_out.connect(cov.analysis_export);
  endfunction

endclass : axis_env

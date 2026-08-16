//=====================================================================
// 4) Monitor
//=====================================================================
class axis_monitor extends uvm_monitor;
  `uvm_component_utils(axis_monitor)

  virtual axis_if vif;
  uvm_analysis_port #(axis_transaction) ap_in;
  uvm_analysis_port #(axis_transaction) ap_out;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap_in  = new("ap_in", this);
    ap_out = new("ap_out", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axis_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "Virtual interface not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    fork
      monitor_input();
      monitor_output();
    join
  endtask

  task monitor_input();
    axis_transaction tr;
    int wait_cycles;
    forever begin
      @(posedge vif.s_aclk);
      if (vif.s_tvalid) begin
        wait_cycles = 0;
        while (!vif.s_tready) begin
          wait_cycles++;
          @(posedge vif.s_aclk);
        end
        tr = axis_transaction::type_id::create("tr");
        tr.tdata       = vif.s_tdata;
        tr.tlast       = vif.s_tlast;
        tr.wait_cycles = wait_cycles;
        ap_in.write(tr);
      end
    end
  endtask

  task monitor_output();
    axis_transaction tr;
    int wait_cycles;
    forever begin
      @(posedge vif.m_aclk);
      if (vif.m_tvalid) begin
        wait_cycles = 0;
        while (!vif.m_tready) begin
          wait_cycles++;
          @(posedge vif.m_aclk);
        end
        tr = axis_transaction::type_id::create("tr");
        tr.tdata       = vif.m_tdata;
        tr.tlast       = vif.m_tlast;
        tr.wait_cycles = wait_cycles;
        ap_out.write(tr);
      end
    end
  endtask

endclass : axis_monitor

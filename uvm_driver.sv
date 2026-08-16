//=====================================================================
// 3) Driver
//=====================================================================
class axis_driver extends uvm_driver #(axis_transaction);
  `uvm_component_utils(axis_driver)

  virtual axis_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axis_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "Virtual interface not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    vif.s_tvalid = 1'b0;
    vif.s_tdata  = 32'h0;
    vif.s_tlast  = 1'b0;
    vif.m_tready = 1'b0;

    wait (vif.s_aresetn == 1'b1 && vif.m_aresetn == 1'b1);

    fork
      drive_source();
      drive_sink();
    join
  endtask

  task drive_source();
    axis_transaction tr;
    forever begin
      seq_item_port.get_next_item(tr);

      if ($urandom_range(0, 3) == 0)
        repeat ($urandom_range(1, 2)) @(posedge vif.s_aclk);

      @(posedge vif.s_aclk);
      vif.s_tdata  <= tr.tdata;
      vif.s_tlast  <= tr.tlast;
      vif.s_tvalid <= 1'b1;

      do begin
        @(posedge vif.s_aclk);
      end while (!vif.s_tready);

      vif.s_tvalid <= 1'b0;
      seq_item_port.item_done();
    end
  endtask

  task drive_sink();
    forever begin
      @(posedge vif.m_aclk);
      vif.m_tready <= $urandom_range(0, 1);
    end
  endtask

endclass : axis_driver

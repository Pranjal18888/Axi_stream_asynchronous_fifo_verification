//=====================================================================
// 10) Top Module - DUAL CLOCK generation (real CDC scenario)
//=====================================================================
module tb_top;

  // Write domain clock: 100 MHz (10ns period)
  bit s_aclk;
  bit s_aresetn;
  always #5 s_aclk = ~s_aclk;

  // Read domain clock: ~143 MHz (7ns period) - jaan-boojh kar alag rakha
  // hai taaki real clock-domain-crossing test ho
  bit m_aclk;
  bit m_aresetn;
  always #3.5 m_aclk = ~m_aclk;

  initial begin
    s_aclk    = 0;
    s_aresetn = 0;
    #20 s_aresetn = 1;
  end

  initial begin
    m_aclk    = 0;
    m_aresetn = 0;
    #23 m_aresetn = 1;   // thoda alag timing se reset release - realistic
  end

  axis_if vif (s_aclk, s_aresetn, m_aclk, m_aresetn);

  axis_async_fifo #(.DEPTH(8), .DW(32)) dut (
    .s_aclk    (s_aclk),
    .s_aresetn (s_aresetn),
    .s_tdata   (vif.s_tdata),
    .s_tvalid  (vif.s_tvalid),
    .s_tready  (vif.s_tready),
    .s_tlast   (vif.s_tlast),

    .m_aclk    (m_aclk),
    .m_aresetn (m_aresetn),
    .m_tdata   (vif.m_tdata),
    .m_tvalid  (vif.m_tvalid),
    .m_tready  (vif.m_tready),
    .m_tlast   (vif.m_tlast)
  );

  initial begin
    uvm_config_db#(virtual axis_if)::set(null, "*", "vif", vif);
  end

  initial begin
    run_test("axis_base_test");
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end

endmodule : tb_top

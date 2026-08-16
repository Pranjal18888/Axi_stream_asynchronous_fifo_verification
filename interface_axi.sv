=====================================================================

interface axis_if (
  input bit s_aclk,
  input bit s_aresetn,
  input bit m_aclk,
  input bit m_aresetn
);

  // Slave side (write / source domain)
  logic [31:0] s_tdata;
  logic        s_tvalid;
  logic        s_tready;
  logic        s_tlast;

  // Master side (read / sink domain)
  logic [31:0] m_tdata;
  logic        m_tvalid;
  logic        m_tready;
  logic        m_tlast;

  //-------------------------------------------------------------
  // SVA Assertions - write domain (s_aclk)
  //-------------------------------------------------------------
  property p_s_tvalid_stable;
    @(posedge s_aclk) disable iff (!s_aresetn)
    (s_tvalid && !s_tready) |=> s_tvalid;
  endproperty
  a_s_tvalid_stable: assert property (p_s_tvalid_stable)
    else $error("[AXIS_ASSERT] S_TVALID, S_TREADY se pehle hi deassert ho gaya");

  property p_s_tdata_stable;
    @(posedge s_aclk) disable iff (!s_aresetn)
    (s_tvalid && !s_tready) |=> $stable(s_tdata);
  endproperty
  a_s_tdata_stable: assert property (p_s_tdata_stable)
    else $error("[AXIS_ASSERT] S_TDATA wait ke dauran change ho gaya");

  property p_s_tlast_stable;
    @(posedge s_aclk) disable iff (!s_aresetn)
    (s_tvalid && !s_tready) |=> $stable(s_tlast);
  endproperty
  a_s_tlast_stable: assert property (p_s_tlast_stable)
    else $error("[AXIS_ASSERT] S_TLAST wait ke dauran change ho gaya");

  property p_reset_tvalid_low;
    @(posedge s_aclk)
    $rose(s_aresetn) |-> !s_tvalid;
  endproperty
  a_reset_tvalid_low: assert property (p_reset_tvalid_low)
    else $error("[AXIS_ASSERT] Reset ke baad S_TVALID high hai");

  //-------------------------------------------------------------
  // SVA Assertions - read domain (m_aclk)
  //-------------------------------------------------------------
  property p_m_tvalid_stable;
    @(posedge m_aclk) disable iff (!m_aresetn)
    (m_tvalid && !m_tready) |=> m_tvalid;
  endproperty
  a_m_tvalid_stable: assert property (p_m_tvalid_stable)
    else $error("[AXIS_ASSERT] M_TVALID, M_TREADY se pehle hi deassert ho gaya (DUT bug)");

  property p_m_tdata_stable;
    @(posedge m_aclk) disable iff (!m_aresetn)
    (m_tvalid && !m_tready) |=> $stable(m_tdata);
  endproperty
  a_m_tdata_stable: assert property (p_m_tdata_stable)
    else $error("[AXIS_ASSERT] M_TDATA wait ke dauran change ho gaya (DUT bug)");

endinterface : axis_if

//=====================================================================
// axis_async_testbench.sv
// Pure SystemVerilog Testbench for AXI4-Stream Asynchronous FIFO
// (dual clock domain) - NO UVM
// Contains: transaction class, driver tasks (per clock domain),
//           monitor tasks, scoreboard (queue-based), coverage
// EDA Playground -> "Testbench Files" section me daalein
// (Design file: axis_async_design.sv -> "Design Files")
//=====================================================================

//---------------------------------------------------------------
// 1) Transaction (plain SV class)
//---------------------------------------------------------------
class axis_txn;
  rand bit [31:0] data;
  rand bit        last;

  // Constraint: data ek readable range me rakho (coverage bins ke liye)
  constraint data_range_c { data < 32'h1000_0000; }
endclass


//---------------------------------------------------------------
// 2) Testbench Top
//---------------------------------------------------------------
module tb_top;

  //-------------------------------------------------------------
  // Dual clock generation - real CDC scenario
  //-------------------------------------------------------------
  bit s_aclk;      // write / source domain - 100 MHz
  bit s_aresetn;
  always #5 s_aclk = ~s_aclk;

  bit m_aclk;      // read / sink domain - ~143 MHz (jaan-boojh kar alag)
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
    #23 m_aresetn = 1;   // dono domains ka reset alag time pe release - realistic
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

  //-------------------------------------------------------------
  // Scoreboard storage (expected queue - in-order compare)
  //-------------------------------------------------------------
  bit [31:0] exp_data_q [$];
  bit        exp_last_q [$];

  int num_checked = 0;
  int num_errors  = 0;

  //-------------------------------------------------------------
  // Functional Coverage
  //-------------------------------------------------------------
  bit [31:0] cov_data;
  bit        cov_last;
  int        cov_wait;

  covergroup axis_cg;
    option.per_instance = 1;

    cp_data : coverpoint cov_data {
      bins low  = {[0             : 32'h0555_5555]};
      bins mid  = {[32'h0555_5556 : 32'h0AAA_AAAA]};
      bins high = {[32'h0AAA_AAAB : 32'h0FFF_FFFF]};
    }

    cp_last : coverpoint cov_last {
      bins last_beat = {1};
      bins mid_beat  = {0};
    }

    cp_wait : coverpoint cov_wait {
      bins zero_wait  = {0};
      bins one_wait   = {1};
      bins multi_wait = {[2:$]};
    }

    cx_last_wait : cross cp_last, cp_wait;

  endgroup

  axis_cg cg = new();

  //-------------------------------------------------------------
  // Driver: source side (s_aclk domain) - sequencer-jaisa item generate
  // karke bhejta hai
  //-------------------------------------------------------------
  task automatic drive_source(int num_packets, int max_beats_per_pkt);
    axis_txn tr;
    int beats;

    forever begin
      if (num_packets <= 0) return;

      beats = $urandom_range(1, max_beats_per_pkt);
      for (int i = 0; i < beats; i++) begin
        tr = new();
        if (!tr.randomize())
          $error("Randomization failed");
        tr.last = (i == beats - 1);

        // Kabhi-kabhi source-side gap dalo (upstream stall simulate karna)
        if ($urandom_range(0, 3) == 0)
          repeat ($urandom_range(1, 2)) @(posedge s_aclk);

        @(posedge s_aclk);
        vif.s_tdata  <= tr.data;
        vif.s_tlast  <= tr.last;
        vif.s_tvalid <= 1'b1;

        do begin
          @(posedge s_aclk);
        end while (!vif.s_tready);

        vif.s_tvalid <= 1'b0;
      end

      num_packets--;
    end
  endtask

  //-------------------------------------------------------------
  // Driver: sink side (m_aclk domain, alag clock!) - random backpressure
  //-------------------------------------------------------------
  task automatic drive_sink();
    forever begin
      @(posedge m_aclk);
      vif.m_tready <= $urandom_range(0, 1);
    end
  endtask

  //-------------------------------------------------------------
  // Monitor: input side (s_aclk domain) - FIFO me jo gaya, expected me daalo
  //-------------------------------------------------------------
  task automatic monitor_input();
    forever begin
      @(posedge s_aclk);
      if (vif.s_tvalid && vif.s_tready) begin
        exp_data_q.push_back(vif.s_tdata);
        exp_last_q.push_back(vif.s_tlast);
      end
    end
  endtask

  //-------------------------------------------------------------
  // Monitor: output side (m_aclk domain) - FIFO se jo nikla, compare karo
  // + coverage sample bhi yahin
  //-------------------------------------------------------------
  task automatic monitor_output();
    bit [31:0] exp_d;
    bit        exp_l;
    int        wait_cycles;

    forever begin
      @(posedge m_aclk);
      if (vif.m_tvalid) begin
        wait_cycles = 0;
        while (!vif.m_tready) begin
          wait_cycles++;
          @(posedge m_aclk);
        end

        num_checked++;

        if (exp_data_q.size() == 0) begin
          num_errors++;
          $error("Output beat aaya lekin expected queue empty hai (unexpected data)");
        end
        else begin
          exp_d = exp_data_q.pop_front();
          exp_l = exp_last_q.pop_front();

          if (exp_d !== vif.m_tdata || exp_l !== vif.m_tlast) begin
            num_errors++;
            $error("MISMATCH: expected data=0x%0h last=%0b, got data=0x%0h last=%0b",
                    exp_d, exp_l, vif.m_tdata, vif.m_tlast);
          end
          else begin
            $display("[SCB] MATCH data=0x%0h last=%0b wait=%0d",
                      vif.m_tdata, vif.m_tlast, wait_cycles);
          end
        end

        cov_data = vif.m_tdata;
        cov_last = vif.m_tlast;
        cov_wait = wait_cycles;
        cg.sample();
      end
    end
  endtask

  //-------------------------------------------------------------
  // Test sequence control
  //-------------------------------------------------------------
  initial begin
    vif.s_tvalid = 1'b0;
    vif.s_tdata  = 32'h0;
    vif.s_tlast  = 1'b0;
    vif.m_tready = 1'b0;

    wait (s_aresetn == 1'b1 && m_aresetn == 1'b1);

    fork
      drive_source(5, 6);   // 5 packets, max 6 beats each
      drive_sink();
      monitor_input();
      monitor_output();
    join_none

    // Test ko chalne ka time do, phir results print karke khatam karo
    #2000;

    $display("=====================================================");
    $display("===> Total Checked = %0d | Errors = %0d | Pending = %0d",
              num_checked, num_errors, exp_data_q.size());
    if (num_errors == 0 && exp_data_q.size() == 0)
      $display("===> TEST PASSED <===");
    else
      $display("===> TEST FAILED <===");
    $display("===> Functional Coverage = %0.2f%%", cg.get_coverage());
    $display("=====================================================");

    $finish;
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end

endmodule : tb_top

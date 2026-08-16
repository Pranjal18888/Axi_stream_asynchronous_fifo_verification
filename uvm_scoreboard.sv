//=====================================================================
// 6) Scoreboard
//=====================================================================
class axis_scoreboard extends uvm_component;
  `uvm_component_utils(axis_scoreboard)

  axis_transaction expected_q[$];
  int num_checked = 0;
  int num_errors  = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void push_expected(axis_transaction t);
    expected_q.push_back(t);
  endfunction

  function void check_actual(axis_transaction t);
    axis_transaction exp_tr;
    num_checked++;

    if (expected_q.size() == 0) begin
      num_errors++;
      `uvm_error("SCB", "Output beat aaya lekin expected queue empty hai (unexpected data)")
      return;
    end

    exp_tr = expected_q.pop_front();
    if (exp_tr.tdata !== t.tdata || exp_tr.tlast !== t.tlast) begin
      num_errors++;
      `uvm_error("SCB", $sformatf("MISMATCH: expected data=0x%0h last=%0b, got data=0x%0h last=%0b",
                 exp_tr.tdata, exp_tr.tlast, t.tdata, t.tlast))
    end
    else begin
      `uvm_info("SCB", $sformatf("MATCH data=0x%0h last=%0b wait=%0d",
                 t.tdata, t.tlast, t.wait_cycles), UVM_LOW)
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf("===> Total Checked = %0d | Errors = %0d | Pending = %0d",
               num_checked, num_errors, expected_q.size()), UVM_NONE)
    if (num_errors == 0 && expected_q.size() == 0)
      `uvm_info("SCB", "===> TEST PASSED <===", UVM_NONE)
    else
      `uvm_error("SCB", "===> TEST FAILED <===")
  endfunction

endclass : axis_scoreboard


class axis_in_listener extends uvm_subscriber #(axis_transaction);
  `uvm_component_utils(axis_in_listener)
  axis_scoreboard scb;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void write(axis_transaction t);
    if (scb != null) scb.push_expected(t);
  endfunction
endclass : axis_in_listener


class axis_out_listener extends uvm_subscriber #(axis_transaction);
  `uvm_component_utils(axis_out_listener)
  axis_scoreboard scb;
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
  function void write(axis_transaction t);
    if (scb != null) scb.check_actual(t);
  endfunction
endclass : axis_out_listener

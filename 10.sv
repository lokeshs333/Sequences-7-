`include "uvm_macros.svh"
import uvm_pkg::*;

//////////////////////////////////////////////////
// Sequence item representing a single transaction.
//////////////////////////////////////////////////
class transaction extends uvm_sequence_item;

  rand bit [3:0] a;
  rand bit [3:0] b;
       bit [4:0] y;

  function new(input string inst = "transaction");
    super.new(inst);
  endfunction

  // Register transaction fields
  `uvm_object_utils_begin(transaction)
    `uvm_field_int(a, UVM_DEFAULT)
    `uvm_field_int(b, UVM_DEFAULT)
    `uvm_field_int(y, UVM_DEFAULT)
  `uvm_object_utils_end

endclass

//////////////////////////////////////////////////
// First sequence sending three transactions.
//////////////////////////////////////////////////
class sequence1 extends uvm_sequence #(transaction);
  `uvm_object_utils(sequence1)

  transaction trans;

  function new(input string inst = "seq1");
    super.new(inst);
  endfunction

  virtual task body();

    repeat (3) begin

      `uvm_info("SEQ1", "SEQ1 Started", UVM_NONE);

      // Create and send transaction
      trans = transaction::type_id::create("trans");

      start_item(trans);
      assert(trans.randomize());
      finish_item(trans);

      `uvm_info("SEQ1", "SEQ1 Ended", UVM_NONE);

    end

  endtask

endclass

//////////////////////////////////////////////////
// Second sequence demonstrating sequencer grab.
//////////////////////////////////////////////////
class sequence2 extends uvm_sequence #(transaction);
  `uvm_object_utils(sequence2)

  transaction trans;

  function new(input string inst = "seq2");
    super.new(inst);
  endfunction

  virtual task body();

    // Immediately take exclusive control
    grab(m_sequencer);

    repeat (3) begin

      `uvm_info("SEQ2", "SEQ2 Started", UVM_NONE);

      trans = transaction::type_id::create("trans");

      start_item(trans);
      assert(trans.randomize());
      finish_item(trans);

      `uvm_info("SEQ2", "SEQ2 Ended", UVM_NONE);

    end

    // Release sequencer
    ungrab(m_sequencer);

  endtask

endclass

//////////////////////////////////////////////////
// Driver receiving transactions from the sequencer.
//////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)

  transaction t;
  virtual adder_if aif;

  function new(input string inst = "DRV", uvm_component c);
    super.new(inst, c);
  endfunction

  // Create transaction object
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    t = transaction::type_id::create("TRANS");
  endfunction

  // Receive transactions from the sequencer
  virtual task run_phase(uvm_phase phase);

    forever begin
      seq_item_port.get_next_item(t);
      seq_item_port.item_done();
    end

  endtask

endclass

//////////////////////////////////////////////////
// Agent containing the driver and sequencer.
//////////////////////////////////////////////////
class agent extends uvm_agent;
  `uvm_component_utils(agent)

  driver d;
  uvm_sequencer #(transaction) seq;

  function new(input string inst = "AGENT", uvm_component c);
    super.new(inst, c);
  endfunction

  // Create driver and sequencer
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    d   = driver::type_id::create("DRV", this);
    seq = uvm_sequencer#(transaction)::type_id::create("seq", this);
  endfunction

  // Connect sequencer to driver
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    d.seq_item_port.connect(seq.seq_item_export);
  endfunction

endclass

//////////////////////////////////////////////////
// Environment containing the agent.
//////////////////////////////////////////////////
class env extends uvm_env;
  `uvm_component_utils(env)

  agent a;

  function new(input string inst = "ENV", uvm_component c);
    super.new(inst, c);
  endfunction

  // Create agent
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    a = agent::type_id::create("AGENT", this);
  endfunction

endclass

//////////////////////////////////////////////////
// Test demonstrating sequencer grab/ungrab.
//////////////////////////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)

  sequence1 s1;
  sequence2 s2;
  env e;

  function new(input string inst = "TEST", uvm_component c);
    super.new(inst, c);
  endfunction

  // Create environment and sequences
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    e  = env::type_id::create("ENV", this);
    s1 = sequence1::type_id::create("s1");
    s2 = sequence2::type_id::create("s2");
  endfunction

  // Run both sequences in parallel
  virtual task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    fork
      s1.start(e.a.seq, null, 100);
      s2.start(e.a.seq, null, 200);
    join

    phase.drop_objection(this);

  endtask

endclass

//////////////////////////////////////////////////
// Top-level testbench
// Starts the UVM test.
//////////////////////////////////////////////////
module tb;

initial begin
  run_test("test");
end

endmodule



















What this example demonstrates
sequence2 uses grab() to obtain immediate exclusive ownership of the sequencer.
Once the sequencer is grabbed, all other sequences are blocked until ungrab() is called.
During the grab period, sequence2 sends all three transactions without interruption.
After calling ungrab(), other waiting sequences (such as sequence1) are allowed to continue.
Unlike arbitration, grab() bypasses normal sequencer scheduling and priorities.

Grab/UnGrab flow:

Sequence1              Sequence2
    │                      │
    │                  grab()
    │                      │
    │                  Txn 1
    │                  Txn 2
    │                  Txn 3
    │                  ungrab()
    │                      │
    ▼                      ▼
      Sequencer available
             │
             ▼
        Sequence1 runs

Note: grab() has a higher priority than normal arbitration and even lock(). A grabbed sequencer cannot service any other sequence until ungrab() is called.

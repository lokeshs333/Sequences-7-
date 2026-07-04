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
// Second sequence sending three transactions.
//////////////////////////////////////////////////
class sequence2 extends uvm_sequence #(transaction);
  `uvm_object_utils(sequence2)

  transaction trans;

  function new(input string inst = "seq2");
    super.new(inst);
  endfunction

  virtual task body();

    repeat (3) begin

      `uvm_info("SEQ2", "SEQ2 Started", UVM_NONE);

      // Create and send transaction
      trans = transaction::type_id::create("trans");

      start_item(trans);
      assert(trans.randomize());
      finish_item(trans);

      `uvm_info("SEQ2", "SEQ2 Ended", UVM_NONE);

    end

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
// Test demonstrating STRICT_FIFO arbitration.
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

  // Run sequences using STRICT_FIFO arbitration
  virtual task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    // Enable FIFO arbitration with priority support
    e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_FIFO);

    fork
      // Lower priority sequence
      s1.start(e.a.seq, null, 100);

      // Higher priority sequence
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
Two sequences execute simultaneously on the same sequencer.
The sequencer arbitration mode is set to UVM_SEQ_ARB_STRICT_FIFO.
sequence1 is started with priority 100, while sequence2 is started with priority 200.
Since STRICT_FIFO supports priorities, the higher-priority sequence (sequence2) is granted access before the lower-priority sequence whenever both are waiting.
If two sequences have the same priority, requests are served in FIFO order.

STRICT_FIFO arbitration flow:

Sequence1 (Priority = 100)
          │
          │
Sequence2 (Priority = 200)
          │
          ▼
   UVM_SEQ_ARB_STRICT_FIFO
          │
   Higher Priority First
          │
          ▼
        Driver
          │
          ▼
         DUT

Note: UVM_SEQ_ARB_STRICT_FIFO combines priority-based scheduling with FIFO ordering. Priority is checked first, and among sequences with equal priority, the one that requested the sequencer first is granted access first.

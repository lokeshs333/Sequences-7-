///////////////////////
/*
Sequencer Arbitration Modes
---------------------------
SEQ_ARB_FIFO           : Default FIFO scheduling (priority ignored)
SEQ_ARB_WEIGHTED       : Weighted arbitration
SEQ_ARB_RANDOM         : Random sequence selection
SEQ_ARB_STRICT_FIFO    : FIFO with priority support
SEQ_ARB_STRICT_RANDOM  : Random with priority support
SEQ_ARB_USER           : User-defined arbitration
*/
//////////////////////////////////////////////////////

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
// First sequence generating one transaction.
//////////////////////////////////////////////////
class sequence1 extends uvm_sequence #(transaction);
  `uvm_object_utils(sequence1)

  transaction trans;

  function new(input string inst = "seq1");
    super.new(inst);
  endfunction

  virtual task body();

    trans = transaction::type_id::create("trans");

    `uvm_info("SEQ1", "SEQ1 Started", UVM_NONE);

    start_item(trans);
    trans.randomize();
    finish_item(trans);

    `uvm_info("SEQ1", "SEQ1 Ended", UVM_NONE);

  endtask

endclass

//////////////////////////////////////////////////
// Second sequence generating one transaction.
//////////////////////////////////////////////////
class sequence2 extends uvm_sequence #(transaction);
  `uvm_object_utils(sequence2)

  transaction trans;

  function new(input string inst = "seq2");
    super.new(inst);
  endfunction

  virtual task body();

    trans = transaction::type_id::create("trans");

    `uvm_info("SEQ2", "SEQ2 Started", UVM_NONE);

    start_item(trans);
    trans.randomize();
    finish_item(trans);

    `uvm_info("SEQ2", "SEQ2 Ended", UVM_NONE);

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

  // Receive sequence items
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

  // Connect sequencer and driver
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
// Test that starts two sequences simultaneously
// on the same sequencer.
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

    // Example:
    // e.a.seq.set_arbitration(UVM_SEQ_ARB_STRICT_RANDOM);

    fork
      s2.start(e.a.seq);
      s1.start(e.a.seq);
    join

    phase.drop_objection(this);

  endtask

endclass

//////////////////////////////////////////////////
// Top-level testbench
// Starts the UVM test.
//////////////////////////////////////////////////
module ram_tb;

initial begin
  run_test("test");
end

endmodule















What this example demonstrates
Two independent sequences (sequence1 and sequence2) are started concurrently on the same sequencer.
Since only one sequence can access the driver at a time, the sequencer arbitration mechanism decides which sequence gets the next grant.
By default, the sequencer uses UVM_SEQ_ARB_FIFO, where the first requesting sequence is granted first.
Uncommenting set_arbitration() allows you to experiment with different arbitration policies such as UVM_SEQ_ARB_RANDOM or UVM_SEQ_ARB_STRICT_RANDOM.
Each sequence generates one randomized transaction using start_item() and finish_item().

Parallel sequence execution:

            Test
             │
       ┌─────┴─────┐
       ▼           ▼
   Sequence1   Sequence2
       │           │
       └─────┬─────┘
             ▼
        Sequencer
   (Arbitration Logic)
             │
             ▼
          Driver
             │
             ▼
            DUT

Note: When multiple sequences run on the same sequencer, the arbitration mode determines which sequence is granted access to the driver next.

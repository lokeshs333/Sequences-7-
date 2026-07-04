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
    `uvm_field_int(a,UVM_DEFAULT)
    `uvm_field_int(b,UVM_DEFAULT)
    `uvm_field_int(y,UVM_DEFAULT)
  `uvm_object_utils_end

endclass

//////////////////////////////////////////////////
// Sequence generating five randomized transactions
// using the `uvm_do macro.
//////////////////////////////////////////////////
class sequence1 extends uvm_sequence #(transaction);
  `uvm_object_utils(sequence1)

  transaction trans;

  function new(string path = "sequence1");
    super.new(path);
  endfunction

  // Generate and send transactions
  virtual task body();

    repeat (5) begin

      // Create, randomize, and send transaction
      `uvm_do(trans)

      `uvm_info("SEQ",
        $sformatf("a : %0d b : %0d", trans.a, trans.b),
        UVM_NONE);

    end

  endtask

endclass

//////////////////////////////////////////////////
// Driver that receives sequence items from the
// sequencer.
//////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)

  transaction trans;

  function new(input string inst = "DRV", uvm_component c);
    super.new(inst,c);
  endfunction

  // Receive transactions from the sequencer
  virtual task run_phase(uvm_phase phase);

    trans = transaction::type_id::create("trans");

    forever begin

      seq_item_port.get_next_item(trans);

      `uvm_info("DRV",
        $sformatf("a : %0d b : %0d", trans.a, trans.b),
        UVM_NONE);

      seq_item_port.item_done();

    end

  endtask

endclass

//////////////////////////////////////////////////
// Agent containing the driver and sequencer.
//////////////////////////////////////////////////
class agent extends uvm_agent;
  `uvm_component_utils(agent)

  uvm_sequencer #(transaction) seqr;
  driver d;

  function new(string path = "agent", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  // Create driver and sequencer
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    d    = driver::type_id::create("DRV", this);
    seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
  endfunction

  // Connect sequencer to driver
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass

//////////////////////////////////////////////////
// Environment that creates the agent and starts
// the sequence.
//////////////////////////////////////////////////
class env extends uvm_env;
  `uvm_component_utils(env)

  agent a;
  sequence1 s1;

  function new(string path = "env", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  // Create agent and sequence
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    a  = agent::type_id::create("a", this);
    s1 = sequence1::type_id::create("s1");
  endfunction

  // Start the sequence on the sequencer
  virtual task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    s1.start(a.seqr);

    phase.drop_objection(this);

  endtask

endclass

//////////////////////////////////////////////////
// Test that creates the environment.
//////////////////////////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)

  env e;

  function new(string path = "test", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  // Create environment
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    e = env::type_id::create("e", this);
  endfunction

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
transaction defines the sequence item exchanged between the sequence and driver.
The sequence uses the uvm_do macro, which automatically creates, randomizes, sends the transaction, and waits for completion.
repeat(5) generates five randomized transactions.
The driver receives each transaction using get_next_item() and completes it using item_done().
The sequence is started from the environment using s1.start(a.seqr).

uvm_do internal flow:

`uvm_do(trans)
      │
      ▼
Create Transaction
      │
      ▼
Randomize Transaction
      │
      ▼
start_item()
      │
      ▼
finish_item()
      │
      ▼
Driver : get_next_item()
      │
      ▼
item_done()

Note: The uvm_do macro is a convenient shorthand for creating, randomizing, sending, and completing a sequence item, reducing the amount of boilerplate code required in a sequence.

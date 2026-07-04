//////////////////////////////////////////////////////

`include "uvm_macros.svh"
import uvm_pkg::*;

/////////////////////////////////////////////////////////////
// Sequence item representing a single transaction.
/////////////////////////////////////////////////////////////
class transaction extends uvm_sequence_item;
  
  rand bit [3:0] a;
  rand bit [3:0] b;
       bit [4:0] y;

  function new(input string path = "transaction");
    super.new(path);
  endfunction

  // Register transaction fields
  `uvm_object_utils_begin(transaction)
    `uvm_field_int(a, UVM_DEFAULT)
    `uvm_field_int(b, UVM_DEFAULT)
    `uvm_field_int(y, UVM_DEFAULT)
  `uvm_object_utils_end

endclass

/////////////////////////////////////////////////////////////
// Basic sequence demonstrating pre_body(), body()
// and post_body() execution.
/////////////////////////////////////////////////////////////
class sequence1 extends uvm_sequence #(transaction);
  `uvm_object_utils(sequence1)

  function new(input string path = "sequence1");
    super.new(path);
  endfunction

  // Executed before body()
  virtual task pre_body();
    `uvm_info("SEQ1", "PRE-BODY EXECUTED", UVM_NONE);
  endtask

  // Main sequence body
  virtual task body();
    `uvm_info("SEQ1", "BODY EXECUTED", UVM_NONE);
  endtask

  // Executed after body()
  virtual task post_body();
    `uvm_info("SEQ1", "POST-BODY EXECUTED", UVM_NONE);
  endtask
  
endclass

/////////////////////////////////////////////////////////////
// Driver that receives sequence items from the sequencer.
/////////////////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)

  transaction t;

  function new(input string path = "DRV", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  // Create transaction object
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t = transaction::type_id::create("t");
  endfunction

  // Receive sequence items from the sequencer
  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(t);

      // Apply transaction to DUT

      seq_item_port.item_done();
    end
  endtask

endclass

/////////////////////////////////////////////////////////////
// Agent containing the driver and sequencer.
/////////////////////////////////////////////////////////////
class agent extends uvm_agent;
  `uvm_component_utils(agent)

  driver d;
  uvm_sequencer #(transaction) seqr;

  function new(input string path = "agent", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  // Create driver and sequencer
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    d    = driver::type_id::create("d", this);
    seqr = uvm_sequencer#(transaction)::type_id::create("seqr", this);
  endfunction

  // Connect driver and sequencer
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction

endclass

/////////////////////////////////////////////////////////////
// Environment containing the agent.
/////////////////////////////////////////////////////////////
class env extends uvm_env;
  `uvm_component_utils(env)

  agent a;

  function new(input string path = "env", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  // Create agent
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    a = agent::type_id::create("a", this);
  endfunction

endclass

/////////////////////////////////////////////////////////////
// Test that creates the environment and starts
// the sequence.
/////////////////////////////////////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)

  sequence1 seq1;
  env e;

  function new(input string path = "test", uvm_component parent = null);
    super.new(path, parent);
  endfunction

  // Create environment and sequence
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    e    = env::type_id::create("e", this);
    seq1 = sequence1::type_id::create("seq1");
  endfunction

  // Start the sequence on the sequencer
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    seq1.start(e.a.seqr);

    phase.drop_objection(this);
  endtask

endclass

/////////////////////////////////////////////////////////
// Top-level testbench
// Starts the UVM test.
/////////////////////////////////////////////////////////
module ram_tb;

initial begin
  run_test("test");
end

endmodule











What this example demonstrates
transaction defines the sequence item exchanged between the sequence and driver.
sequence1 demonstrates the execution order of pre_body() → body() → post_body().
The sequencer controls the flow of sequence items to the driver.
The driver requests items using get_next_item() and notifies completion using item_done().
The agent contains and connects the sequencer and driver.
The test starts the sequence using seq1.start(e.a.seqr).

Sequence execution flow:

test
   │
   ▼
sequence.start(sequencer)
   │
   ▼
pre_body()
   │
   ▼
body()
   │
   ▼
post_body()

Transaction flow:

Sequence
    │
    ▼
Sequencer
    │
    ▼
Driver (get_next_item)
    │
    ▼
Apply to DUT
    │
    ▼
item_done()

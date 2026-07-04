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
// Sequence demonstrating manual transaction flow
// using start_item() and finish_item().
//////////////////////////////////////////////////
class sequence1 extends uvm_sequence #(transaction);
  `uvm_object_utils(sequence1)

  transaction trans;

  function new(string path = "sequence1");
    super.new(path);
  endfunction

  // Generate and send five transactions
  virtual task body();

    repeat (5) begin

      // Create transaction
      trans = transaction::type_id::create("trans");

      // Request sequencer grant
      start_item(trans);

      // Randomize transaction
      assert(trans.randomize());

      // Send transaction to the driver
      finish_item(trans);

      `uvm_info("SEQ",
        $sformatf("a : %0d b : %0d", trans.a, trans.b),
        UVM_NONE);

    end

  endtask

endclass

//////////////////////////////////////////////////
// Driver that receives transactions from the
// sequencer.
//////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)

  transaction trans;

  function new(input string inst = "DRV", uvm_component c);
    super.new(inst, c);
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

  // Start the sequence
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
start_item() and finish_item() provide manual control over transaction execution.
start_item() requests permission from the sequencer before the transaction is modified.
After receiving the grant, the transaction is randomized using randomize().
finish_item() sends the completed transaction to the driver.
The driver receives each transaction using get_next_item() and completes it using item_done().
This approach provides more flexibility than the uvm_do macro, allowing custom processing between start_item() and finish_item().

Transaction flow:

Create Transaction
        │
        ▼
start_item()
        │
        ▼
Randomize Transaction
        │
        ▼
finish_item()
        │
        ▼
Driver : get_next_item()
        │
        ▼
Apply to DUT
        │
        ▼
item_done()

////////////////////////
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
    `uvm_field_int(a,UVM_DEFAULT)
    `uvm_field_int(b,UVM_DEFAULT)
    `uvm_field_int(y,UVM_DEFAULT)
  `uvm_object_utils_end

endclass

//////////////////////////////////////////////////
// Sequence demonstrating the low-level sequence
// handshake with the driver.
//////////////////////////////////////////////////
class sequence1 extends uvm_sequence #(transaction);
  `uvm_object_utils(sequence1)

  transaction trans;

  function new(input string inst = "seq1");
    super.new(inst);
  endfunction

  virtual task body();

    `uvm_info("SEQ1", "Transaction object created", UVM_NONE);

    // Create transaction
    trans = transaction::type_id::create("trans");

    // Wait until sequencer grants access
    `uvm_info("SEQ1", "Waiting for grant from driver", UVM_NONE);
    wait_for_grant();

    // Randomize transaction
    `uvm_info("SEQ1", "Grant received, randomizing transaction", UVM_NONE);
    assert(trans.randomize());

    // Send transaction to driver
    `uvm_info("SEQ1", "Sending request to driver", UVM_NONE);
    send_request(trans);

    // Wait for driver completion
    `uvm_info("SEQ1", "Waiting for item_done()", UVM_NONE);
    wait_for_item_done();

    `uvm_info("SEQ1", "Sequence completed", UVM_NONE);

  endtask

endclass

//////////////////////////////////////////////////
// Driver that receives transactions from the
// sequencer.
//////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
  `uvm_component_utils(driver)

  transaction t;
  virtual adder_if aif;

  function new(input string inst = "DRV", uvm_component c);
    super.new(inst, c);
  endfunction

  // Create transaction and get interface
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    t = transaction::type_id::create("TRANS");

    if(!uvm_config_db#(virtual adder_if)::get(this,"","aif",aif))
      `uvm_info("DRV","Unable to access Interface",UVM_NONE);
  endfunction

  // Receive and process sequence items
  virtual task run_phase(uvm_phase phase);

    forever begin

      `uvm_info("DRV","Sending grant to sequence",UVM_NONE);

      seq_item_port.get_next_item(t);

      // Apply transaction to DUT

      `uvm_info("DRV","Applying transaction to DUT",UVM_NONE);

      `uvm_info("DRV","Sending item_done()",UVM_NONE);

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
    super.new(inst,c);
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
    super.new(inst,c);
  endfunction

  // Create agent
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    a = agent::type_id::create("AGENT", this);
  endfunction

endclass

//////////////////////////////////////////////////
// Test that creates the environment and starts
// the sequence.
//////////////////////////////////////////////////
class test extends uvm_test;
  `uvm_component_utils(test)

  sequence1 s1;
  env e;

  function new(input string inst = "TEST", uvm_component c);
    super.new(inst,c);
  endfunction

  // Create environment and sequence
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    e  = env::type_id::create("ENV", this);
    s1 = sequence1::type_id::create("s1");
  endfunction

  // Start the sequence
  virtual task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    s1.start(e.a.seq);

    phase.drop_objection(this);

  endtask

endclass

//////////////////////////////////////////////////
// Top-level testbench
// Shares the virtual interface and starts UVM.
//////////////////////////////////////////////////
module ram_tb;

  adder_if aif();

  initial begin
    uvm_config_db#(virtual adder_if)::set(null, "*", "aif", aif);
    run_test("test");
  end

  // Enable waveform dumping
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

endmodule










What this example demonstrates
The sequence uses the low-level sequencer handshake API instead of start_item() and finish_item().
wait_for_grant() requests permission from the sequencer before sending a transaction.
After receiving the grant, the sequence randomizes the transaction and calls send_request().
The driver receives the transaction using get_next_item(), processes it, and signals completion using item_done().
wait_for_item_done() blocks the sequence until the driver finishes processing the current transaction.
This example illustrates the complete handshake between the sequence, sequencer, and driver.

Sequence–Driver handshake:

Sequence
   │
   ▼
wait_for_grant()
   │
   ▼
Grant from Sequencer
   │
   ▼
Randomize Transaction
   │
   ▼
send_request()
   │
   ▼
Driver : get_next_item()
   │
   ▼
Apply Transaction to DUT
   │
   ▼
item_done()
   │
   ▼
wait_for_item_done() returns

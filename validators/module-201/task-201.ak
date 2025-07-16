use aiken/primitive/bytearray
use aiken/primitive/string
use aiken/crypto.{blake2b_224, blake2b_256, VerificationKeyHash}
// use aiken/collection/dict
use aiken/collection/list
use aiken/interval
// use cardano/script_context.{Minting, ScriptContext}
use cardano/transaction.{ValidityRange, Transaction, Input, Output, NoDatum, OutputReference, placeholder}
use cardano/assets.{from_lovelace}
use cardano/address.{Address, VerificationKey}

/// Get the hash224 generator for a given random ByteArray.
///```aiken
///let khash224 = get_hash224_generator("random_string")
///```
fn get_hash224_generator(random: ByteArray) -> ByteArray {
  blake2b_224(random)
}

/// Get the hash224 generator for a given random ByteArray.
///```aiken
///let khash256 = get_hash256_generator("random_string")
///```
fn get_hash256_generator(random: ByteArray) -> ByteArray {
  blake2b_256(random)
}

/// Get the output reference generator for a given transaction ID and index.
///```aiken
///let out_ref = get_output_reference_generatror(1, 0)
///```
/// This function creates an `OutputReference` with the transaction ID and index.
/// It uses the `get_hash256_generator` to create a hash of the transaction ID.
/// The `OutputReference` is used to reference a specific output in a transaction.
/// The `transaction_id` is a hash of the transaction ID, and the `output_index
fn get_output_reference_generatror(tx_id: Int, idx: Int) -> OutputReference {
  let tx_id_b: ByteArray = bytearray.from_string(string.from_int(tx_id))
  OutputReference {
    transaction_id: get_hash256_generator(tx_id_b),
    output_index: idx,
  }
  
}

/// Prepare an input for a transaction.
/// This function creates an `Input` with a specific output reference, owner, and amount.
///```aiken
///let input = prepare_input(1, 0, "GimbaLabs", 10_000_000)
///```
/// The `out_ref_id` is the transaction ID, `out_ref_idx` is the output index,
/// `owner` is the owner of the input, and `amount` is the amount of ADA to be transferred.
/// The `owner` is a `ByteArray` that represents the owner's address.
/// The function returns an `Input` that can be used in a transaction.
/// The `Input` contains an `OutputReference` and an `Output`.
/// The `OutputReference` is created using the `get_output_reference_generatror` function
/// and the `Output` is created with the owner's address, amount, and other properties.
/// The `Output` contains the address, value, datum, and reference script.
/// The `address` is created using the `VerificationKey` of the owner.
/// The `value` is created using the `from_lovelace` function to convert the amount from lovelace to ADA.
/// The `datum` is set to `NoDatum`, indicating that there is no associated data.
/// The `reference_script` is set to `None`, indicating that there is no reference script.
/// The function returns the `Input` that can be used in a transaction.
/// The `Input` is used to reference a specific output in a transaction.
/// The `OutputReference` is used to reference a specific output in a transaction.
/// The `Output` is used to create a new output in a transaction.
/// The `Output` contains the address, value, datum, and reference script.
/// The `address` is created using the `VerificationKey` of the owner.
/// The `value` is created using the `from_lovelace` function to convert the      
fn prepare_input(out_ref_id: Int, out_ref_idx: Int, owner: ByteArray, amount: Int) -> Input {
  let outr: OutputReference = get_output_reference_generatror(out_ref_id, out_ref_idx)
  let vkSender: ByteArray = get_hash224_generator(owner)  
  let addrSender = Address {
    payment_credential: VerificationKey(vkSender),
    stake_credential: None,
  }

  Input {
    output_reference: outr,
    output: Output {
      address: addrSender,
      value: from_lovelace(amount),
      datum: NoDatum,
      reference_script: None,
    }
  }
}


/// Prepare an output for a transaction.
/// This function creates an `Output` with a specific owner and amount.
///```aiken
///let output = prepare_output("GimbaLabs", 9_000_000)
///```
/// The `owner` is a `ByteArray` that represents the owner's address.
/// The `amount` is the amount of ADA to be transferred.
/// The function returns an `Output` that can be used in a transaction.
/// The `Output` contains the address, value, datum, and reference script.
/// The `address` is created using the `VerificationKey` of the owner.
/// The `value` is created using the `from_lovelace` function to convert the      
fn prepare_output(owner: ByteArray, amount: Int) -> Output {
  let vkReciber: ByteArray = get_hash224_generator(owner)  
  let addrReceiber = Address {
    payment_credential: VerificationKey(vkReciber),
    stake_credential: None,
  }
  Output {
      address: addrReceiber,
      value: from_lovelace(amount),
      datum: NoDatum,
      reference_script: None,
  }
  
}

/// Prepare a transaction with a list of inputs, outputs, and a validity range.
/// This function creates a `Transaction` with the specified inputs, outputs, and validity range.
///```aiken     
///  let tx = prepare_tx(input_list, output_list, vr)   
///```
/// The `input_list` is a list of `Input` objects, the `output_list` is a list of `Output` objects,
/// and the `vr` is a `ValidityRange` that specifies the validity period of the transaction.
/// The function returns a `Transaction` that can be used in a validator.
/// The `Transaction` contains the inputs, outputs, validity range, and fee.
/// The `inputs` are the list of inputs that reference previous outputs.
/// The `outputs` are the list of outputs that will be created in the transaction.    
fn prepare_tx(input_list: List<Input>, output_list: List<Output>, vr: ValidityRange) -> Transaction {
  Transaction {
    ..placeholder,
    inputs: input_list,
    outputs: output_list,
    validity_range: vr,
    fee: 1_000_000,
  }
}

// ==============================================
//         Important Stuff validator
// ==============================================

validator task_201_important_stuff {
  // Write a validator that succeeds on any transaction with exactly one input and exactly one output, that allows anyone to claim a UTxO before a specified deadline.
  spend(_d, _r, _utxo, transaction: Transaction) -> Bool {
    // Check if there is exactly one input and one output
    let tx = transaction
    let validity_range = tx.validity_range
    let inputs_count = list.length(tx.inputs)
    let outputs_count = list.length(tx.outputs)

    trace(string.concat(@"inputs_count: ", string.from_int(inputs_count)))
    trace(string.concat(@"outputs_count: ", string.from_int(outputs_count))) 

    let is_before = interval.is_entirely_before(validity_range, 200)

    let check_inputs = inputs_count == 1
    let check_outputs = outputs_count == 1

    check_inputs? && check_outputs? && is_before?
  }
  else(_) {
    fail  
  } 
}

validator task_201_important_stuff_sidan{
  // Test Sidan code
  spend(_d, _r, _utxo, tx: Transaction) -> Bool {
    let Transaction { inputs, outputs, .. } = tx
    when (inputs, outputs) is {
      // Only true when there is only 1 input & 1 output
      ([_], [_]) -> True
      _ -> False
    }
  }
  else(_) {
    fail  
  }
}

// ==============================================
//             TESTS important stuff
// ==============================================

test task_201_test_important_stuff_succeed_spending_validator() {
  trace @"validate for task_201 spending transaction with one input and one output before deadline"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 9_000_000)]
  let vr: ValidityRange = interval.between(100, 199)

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_important_stuff.spend(None, None, get_output_reference_generatror(0, 0), tx)
  test_result?
}

test task_201_test_important_stuff_fail_range() {
    trace @"validate for task_201 spending transaction fail before range limit"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 9_000_000)]
  let vr: ValidityRange = interval.between(100, 210)

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_important_stuff.spend(None, None, get_output_reference_generatror(0, 0), tx)
  !test_result?
}

test task_201_test_important_stuff_fail_multiple_inputs() {
    trace @"validate for task_201 spending transaction fail multiple inputs"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 9_000_000)]
  let vr: ValidityRange = interval.between(100, 190)

  let input_two: Input = prepare_input(2, 0, "estADA", 5_000_000)
  let input_list: List<Input> = list.push(input_list, input_two)

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_important_stuff.spend(None, None, get_output_reference_generatror(0, 0), tx)
  !test_result?
}

test task_201_test_important_stuff_fail_multiple_outputs() {
    trace @"validate for task_201 spending transaction fail multiple outputs"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 5_000_000)]
  let vr: ValidityRange = interval.between(100, 190)

  let output_two: Output = prepare_output("estADA", 4_000_000)
  let output_list: List<Output> = list.push(output_list, output_two)

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_important_stuff.spend(None, None, get_output_reference_generatror(0, 0), tx)
  !test_result?
}

test task_201_test_important_stuff_fail_multiple_outputs_Sidan() {
    trace @"validate for task_201 spending transaction fail multiple outputs for Sidan validator"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 5_000_000)]
  let vr: ValidityRange = interval.between(100, 190)

  let output_two: Output = prepare_output("estADA", 4_000_000)
  let output_list: List<Output> = list.push(output_list, output_two)

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_important_stuff_sidan.spend(None, None, get_output_reference_generatror(0, 0), tx)
  !test_result?
}

// ==============================================
//         Neat Stuff validator
// ==============================================


pub type Redeemer201 {
  signer: VerificationKeyHash
}

validator task_201_neat_stuff_succeed_spending_validator{
// Write a validator that succeeds on any transaction that is signed by a the holder a public key hash that is specified in a redeemer. Do you think that this is a useful validator?
  spend(_d, redeemer: Redeemer201, _utxo, tx: Transaction) -> Bool {
    let Transaction { inputs, .. } = tx
    let tx_signer: VerificationKeyHash = redeemer.signer
    trace(string.concat(@"signer: ", bytearray.to_hex(tx_signer)))
    // Check if the transaction is signed by the specified signer
    let is_signed = list.any(inputs, fn(input) {
      let signer_vk = input.output.address.payment_credential
      trace@"signer_vk: "
      trace(signer_vk)
      signer_vk == VerificationKey(tx_signer)
    })  
    is_signed?
  }
  else(_) {
    fail  
  }
}

// ==============================================
//             TESTS neat stuff
// ==============================================

test task_201_test_neat_stuff_spend_succesful() {
  trace @"validate for task_201 spending transaction neat stuff succesful same signer"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 9_000_000)]
  let vr: ValidityRange = interval.between(100, 190)
  let redeemer_201: Redeemer201 = Redeemer201 { signer: get_hash224_generator("GimbaLabs") }

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_neat_stuff_succeed_spending_validator.spend(None, redeemer_201, get_output_reference_generatror(0, 0), tx)
  test_result?
}

test task_201_test_neat_stuff_spend_succesful_multiple_inputs() {
  trace @"validate for task_201 spending transaction neat stuff succesful same signer in multiple inputs"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("estADA", 14_000_000)]
  let vr: ValidityRange = interval.between(100, 190)
  let redeemer_201: Redeemer201 = Redeemer201 { signer: get_hash224_generator("estADA") }

  let input_two: Input = prepare_input(2, 0, "estADA", 5_000_000)
  let input_list: List<Input> = list.push(input_list, input_two)

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_neat_stuff_succeed_spending_validator.spend(None, redeemer_201, get_output_reference_generatror(0, 0), tx)
  test_result?
}

test task_201_test_neat_stuff_spend_fail() {
  trace @"validate for task_201 spending transaction neat stuff fail diferent signer"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("estADA", 9_000_000)]
  let vr: ValidityRange = interval.between(100, 190)
  let redeemer_201: Redeemer201 = Redeemer201 { signer: get_hash224_generator("estADA") }

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_neat_stuff_succeed_spending_validator.spend(None, redeemer_201, get_output_reference_generatror(0, 0), tx)
  !test_result?
}

// ==============================================
//         Tough Stuff validator
// ==============================================

validator task_201_tough_stuff_succeed_spending_validator(limit: Int) {
// Write a validator that succeeds before a deadline if it sends outputs to at least two different addresses, and that succeeds after a deadline only if the transaction is signed by some "administrator".
  spend(_d, redeemer: Redeemer201, _utxo, tx: Transaction) -> Bool {
    let Transaction { inputs, outputs, .. } = tx

    let validity_range = tx.validity_range
    let is_before = interval.is_entirely_before(validity_range, limit)

    let administrator: VerificationKeyHash = redeemer.signer
    trace(string.concat(@"signer: ", bytearray.to_hex(administrator)))
    // Check if the transaction is signed by the administrator
    let is_administrator_signed = list.any(inputs, fn(input) {
      let signer_vk = input.output.address.payment_credential
      trace@"signer_vk: "
      trace(signer_vk)
      signer_vk == VerificationKey(administrator)
    })  
    let different_output_addresses = list.any(outputs, fn(output) {
      let output_address = output.address.payment_credential
      // trace@"output_address: "
      // trace(output_address)
      list.any(outputs, fn(other_output) {
        let other_output_address = other_output.address.payment_credential
        trace@"other_output_address: "
        trace(other_output_address)
        output_address != other_output_address
      })
    })

    is_before? && is_administrator_signed? && different_output_addresses?

  }
  else(_) {
    fail  
  }
}

// ==============================================
//         TEST Tough Stuff
// ==============================================

test task_201_test_tough_stuff_succeed_spending_validator() {
  trace @"validate for task_201 spending transaction tough stuff succesful"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 9_000_000)]
  let vr: ValidityRange = interval.before(199)

  let input_two: Input = prepare_input(2, 1, "administrator", 5_000_000)
  let input_list: List<Input> = list.push(input_list, input_two)

  let output_two: Output = prepare_output("estADA", 5_000_000)
  let output_list: List<Output> = list.push(output_list, output_two)

  let redeemer_administrator: Redeemer201 = Redeemer201 { signer: get_hash224_generator("administrator") }

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_tough_stuff_succeed_spending_validator.spend(200, None, redeemer_administrator, get_output_reference_generatror(0, 0), tx)
  test_result?
}

test task_201_test_tough_stuff_fail_deadline() {
  trace @"validate for task_201 spending transaction tough stuff fail bad deadline"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 9_000_000)]
  let vr: ValidityRange = interval.before(200)

  let input_two: Input = prepare_input(2, 1, "administrator", 5_000_000)
  let input_list: List<Input> = list.push(input_list, input_two)

  let output_two: Output = prepare_output("estADA", 5_000_000)
  let output_list: List<Output> = list.push(output_list, output_two)

  let redeemer_administrator: Redeemer201 = Redeemer201 { signer: get_hash224_generator("administrator") }

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_tough_stuff_succeed_spending_validator.spend(200, None, redeemer_administrator, get_output_reference_generatror(0, 0), tx)
  !test_result?
}

test task_201_test_tough_stuff_fail_administrator_sign() {
  trace @"validate for task_201 spending transaction tough stuff fail no administrator input"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 9_000_000)]
  let vr: ValidityRange = interval.before(199)

  let input_two: Input = prepare_input(2, 1, "estADA", 5_000_000)
  let input_list: List<Input> = list.push(input_list, input_two)

  let output_two: Output = prepare_output("estADA", 5_000_000)
  let output_list: List<Output> = list.push(output_list, output_two)

  let redeemer_administrator: Redeemer201 = Redeemer201 { signer: get_hash224_generator("administrator") }

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_tough_stuff_succeed_spending_validator.spend(200, None, redeemer_administrator, get_output_reference_generatror(0, 0), tx)
  !test_result?
}

test task_201_test_tough_stuff_fail_one_output() {
  trace @"validate for task_201 spending transaction tough stuff only one output"
  let input_list: List<Input> = [prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let output_list: List<Output> = [prepare_output("GimbaLabs", 14_000_000)]
  let vr: ValidityRange = interval.before(199)

  let input_two: Input = prepare_input(2, 1, "administrator", 5_000_000)
  let input_list: List<Input> = list.push(input_list, input_two)

  let redeemer_administrator: Redeemer201 = Redeemer201 { signer: get_hash224_generator("administrator") }

  let tx = prepare_tx(input_list, output_list, vr)

  let test_result = task_201_tough_stuff_succeed_spending_validator.spend(200, None, redeemer_administrator, get_output_reference_generatror(0, 0), tx)
  !test_result?
}
// module lib/estADA/mytools
use aiken/primitive/bytearray
use aiken/primitive/string
use aiken/crypto.{blake2b_224, blake2b_256}//, VerificationKeyHash}
// use aiken/collection/dict
// use aiken/collection/list
// use aiken/interval
// use cardano/script_context.{Minting, ScriptContext}
use cardano/transaction.{ValidityRange, Transaction, Input, Output, NoDatum, OutputReference, placeholder}
use cardano/assets.{PolicyId, Value, from_lovelace, add}
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

pub fn getHash(encode: ByteArray, random: ByteArray) -> ByteArray {
  when encode is {
    "blake2b_224" -> get_hash224_generator(random)
    "blake2b_256" -> get_hash256_generator(random)
     _ -> ""
  }
}

///// Get the policy ID generator for a given random ByteArray.
///```aiken
///let policy_id = get_policiy_id_generic("random_string")
///```
/// This function creates a policy ID by hashing the random ByteArray using blake2b_224.
/// The policy ID is used to identify a specific policy in the Cardano blockchain.
/// The `random` parameter is a `ByteArray` that represents the random input.
/// The function returns a `PolicyId` that can be used in transactions.
/// The `PolicyId` is a hash of the random input, which is used to create
/// a unique identifier for the policy.
pub fn get_policiyId(random: ByteArray) -> PolicyId {
  getHash("blake2b_224", random)
}

/// Get the output reference generator for a given transaction ID and index.
///```aiken
///let out_ref = get_output_reference_generatror(1, 0)
///```
/// This function creates an `OutputReference` with the transaction ID and index.
/// It uses the `get_hash256_generator` to create a hash of the transaction ID.
/// The `OutputReference` is used to reference a specific output in a transaction.
/// The `transaction_id` is a hash of the transaction ID, and the `output_index
pub fn get_output_reference_generatror(tx_id: Int, idx: Int) -> OutputReference {
  let tx_id_b: ByteArray = bytearray.from_string(string.from_int(tx_id))
  let tx_hash: ByteArray = getHash("blake2b_256", tx_id_b)
  OutputReference {
    //transaction_id: get_hash256_generator(tx_id_b),
    transaction_id: tx_hash,
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
pub fn prepare_input(out_ref_id: Int, out_ref_idx: Int, owner: ByteArray, amount: Int) -> Input {
  let outr: OutputReference = get_output_reference_generatror(out_ref_id, out_ref_idx)
  let vkSender: ByteArray = getHash("blake2b_224", owner)  
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
pub fn prepare_output(receiver: ByteArray, amount: Int, policy: PolicyId, name: ByteArray, token_amount: Int) -> Output {
  let vkReciver: ByteArray = getHash("blake2b_224", receiver)  
  let addrReceiber = Address {
    payment_credential: VerificationKey(vkReciver),
    stake_credential: None,
  }
  let value: Value = from_lovelace(amount)
  let output_value: Value = add(value, policy, name, token_amount)

  Output {
      address: addrReceiber,
      value: output_value,
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
pub fn prepare_tx(input_list: List<Input>, output_list: List<Output>, vr: ValidityRange) -> Transaction {
  Transaction {
    ..placeholder,
    inputs: input_list,
    outputs: output_list,
    validity_range: vr,
    fee: 1_000_000,
  }
}
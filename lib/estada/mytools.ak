use aiken/crypto.{blake2b_224, blake2b_256}
use aiken/primitive/bytearray
use aiken/primitive/string
use cardano/address.{Address, VerificationKey}
use cardano/assets.{AssetName, PolicyId, Value, add, from_lovelace, merge}
use cardano/transaction.{
  Input, NoDatum, Output, OutputReference, Transaction, ValidityRange,
  placeholder,
}

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

/// Get the hash generator for a given encode and random ByteArray.
///```aiken
///let hash = getHash("blake2b_224", "random_string")
///```
pub fn getHash(encode: ByteArray, random: ByteArray) -> ByteArray {
  when encode is {
    "blake2b_224" -> get_hash224_generator(random)
    "blake2b_256" -> get_hash256_generator(random)
    _ -> ""
  }
}

/// Add a value to a value with a specific policy ID and asset name.
///```aiken
/// let list_of_assets: Value = add_value_to_value(
///    from_lovelace(0),
///    policy_id_1,
///    token_name_1,
///    1
///  )
///```
pub fn add_value_to_value(
  value: Value,
  policy_id: PolicyId,
  asset_name: AssetName,
  amount: Int,
) -> Value {
  let assets: Value = add(value, policy_id, asset_name, amount)
  assets
}

/// This function creates a policy ID by hashing the random ByteArray using blake2b_224.
///```aiken
///let policy_id = get_policiy_id_generic("random_string")
///```
pub fn get_policiyId(random: ByteArray) -> PolicyId {
  getHash("blake2b_224", random)
}

/// This function creates an `OutputReference` with the transaction ID and index.
///```aiken
///let out_ref = get_output_reference_generatror(1, 0)
///```
pub fn get_output_reference_generatror(tx_id: Int, idx: Int) -> OutputReference {
  let tx_id_b: ByteArray = bytearray.from_string(string.from_int(tx_id))
  let tx_hash: ByteArray = getHash("blake2b_256", tx_id_b)
  OutputReference {
    //transaction_id: get_hash256_generator(tx_id_b),
    transaction_id: tx_hash,
    output_index: idx,
  }
}

/// Get the address generator for a given verification key and optional stake credential.
///```aiken
///let address = get_address("verification_key", None)
///```
pub fn get_address(
  verification_key: ByteArray,
  stake_credential: Option<ByteArray>,
) -> Address {
  let vk: ByteArray = getHash("blake2b_224", verification_key)
  let addr: Address =
    when stake_credential is {
      None -> address.from_verification_key(vk)
      Some(sc) ->
        address.with_delegation_key(
          address.from_verification_key(vk),
          getHash("blake2b_224", sc),
        )
    }
  addr
}

/// This function creates an `Input` with a specific output reference, owner, ADA amount and optional `Value`.
///```aiken
///let input = prepare_input(1, 0, "GimbaLabs", 10_000_000, None)
///```
pub fn prepare_input(
  out_ref_id: Int,
  out_ref_idx: Int,
  owner: ByteArray,
  amount: Int,
  extra_value: Option<Value>,
) -> Input {
  let outr: OutputReference =
    get_output_reference_generatror(out_ref_id, out_ref_idx)
  let vkSender: ByteArray = getHash("blake2b_224", owner)
  let addrSender =
    Address {
      payment_credential: VerificationKey(vkSender),
      stake_credential: None,
    }
  let tx_value: Value = from_lovelace(amount)
  let output_value: Value =
    when extra_value is {
      None -> tx_value
      Some(extra_value) -> merge(tx_value, extra_value)
    }

  Input {
    output_reference: outr,
    output: Output {
      address: addrSender,
      value: output_value,
      datum: NoDatum,
      reference_script: None,
    },
  }
}

/// This function creates an `Output` with a specific receiver and amount, that can be used in a transaction.
///```aiken
///let output = prepare_output("GimbaLabs", 9_000_000, None)
///```
pub fn prepare_output(
  receiver: ByteArray,
  amount: Int,
  extra_value: Option<Value>,
) -> Output {
  let vkReciver: ByteArray = getHash("blake2b_224", receiver)
  let addrReceiber =
    Address {
      payment_credential: VerificationKey(vkReciver),
      stake_credential: None,
    }
  let tx_value: Value = from_lovelace(amount)
  let output_value: Value =
    when extra_value is {
      None -> tx_value
      Some(extra_value) -> merge(tx_value, extra_value)
    }
  Output {
    address: addrReceiber,
    value: output_value,
    datum: NoDatum,
    reference_script: None,
  }
}

/// This function creates an `Output` with a specific owner, ADA amount, policy ID,
/// asset name, and token amount.
///```aiken
///let output_token = prepare_output_token("GimbaLabs", 9_000_000, "policy_id", "token_name", 100)
///```
pub fn prepare_output_token(
  receiver: ByteArray,
  amount: Int,
  policy: PolicyId,
  name: ByteArray,
  token_amount: Int,
) -> Output {
  let vkReciver: ByteArray = getHash("blake2b_224", receiver)
  let addrReceiber =
    Address {
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
pub fn prepare_tx(
  input_list: List<Input>,
  output_list: List<Output>,
  vr: ValidityRange,
) -> Transaction {
  Transaction {
    ..placeholder,
    inputs: input_list,
    outputs: output_list,
    validity_range: vr,
    fee: 1_000_000,
  }
}

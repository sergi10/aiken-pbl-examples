use aiken/primitive/bytearray
use aiken/primitive/string
use aiken/crypto.{blake2b_224, blake2b_256}
use aiken/collection/dict
use aiken/collection/list
use aiken/interval
// use cardano/script_context.{Minting, ScriptContext}
use cardano/transaction.{ValidityRange, Transaction, Input, Output, NoDatum, OutputReference, placeholder}
use cardano/assets.{PolicyId, from_asset, from_lovelace}
use cardano/address.{Address, VerificationKey}
// use mocktail.{mock_utxo_ref}

// Build a legit mock tx with all spending, minting, locking, and unlocking
// spending:    
//   - Address: Verify signer
//   - Time: Verify validity_range: ValidityRange,
// Minting:
//   - PolicyID: Verify signer
// Locking:
//   - redeemers: Pairs<ScriptPurpose, Redeemer>,
//   - datums: Dict<DataHash, Data>,
// UnLocking:
//   - redeemers: Pairs<ScriptPurpose, Redeemer>,
//   - datums: Dict<DataHash, Data>,

// Purpose	    Target	            What for
// mint	        PolicyId	        minting / burning of assets
// spend	    OutputReference	    spending of transaction outputs
// withdraw	    Credential	        withdrawing staking rewards

fn get_policy_id_103() -> PolicyId {
  blake2b_224("aiken_policy_id_103")
  // @"83F150B143CBDDDA384B80ABE99E3352BDA898F444FA25ECB3D27B02"
}

fn get_token_name_103() -> ByteArray {
  "token_task103"
}

fn get_policiy_id_generic(random: ByteArray) -> PolicyId {
  // trace @"get_policiy_id_generic"
  // trace(random)
  random
}

fn get_hash224_generator(random: ByteArray) -> ByteArray {
  // trace @"get_hash224_generator"
  // trace(blake2b_224(random))
  blake2b_224(random)
}

fn get_hash_256_generator(random: ByteArray) -> ByteArray {
  
  // trace @"get_hash_256_generator"
  // trace(blake2b_256(random))
  blake2b_256(random)
}

fn get_name_generator(random: ByteArray) -> ByteArray {
  // trace @"get_name_generator"
  // trace(random)
  random
}

fn get_output_reference_generatror(tx_id: Int, idx: Int) -> OutputReference {
  let tx_id_b: ByteArray = bytearray.from_string(string.from_int(tx_id))
  // trace @"get_output_reference_generatror"
  // trace(tx_id_b)
  OutputReference {
    transaction_id: get_hash_256_generator(tx_id_b),
    output_index: idx,
  }
  
}

fn prepare_tx(policyID: ByteArray, name: ByteArray, quantity: Int, vr: ValidityRange) -> Transaction {
  
  let outr: OutputReference = get_output_reference_generatror(1, 0)
  let vkSender: ByteArray = get_hash224_generator("1")  
  let vkReciber: ByteArray = get_hash224_generator("2") 
  let addrSender = Address {
    payment_credential: VerificationKey(vkSender),
    stake_credential: None,
  }
  let addrReceiber = Address {
    payment_credential: VerificationKey(vkReciber),
    stake_credential: None,
  }

  let input =
    Input {
      output_reference: outr,
      output: Output {
        address: addrSender,
        value: from_lovelace(10_000_000),
        datum: NoDatum,
        reference_script: None,
      },
    }

  let output =
    Output {
      address: addrReceiber,
      value: from_lovelace(9_000_000),
      datum: NoDatum,
      reference_script: None,
    }

  Transaction {
    ..placeholder,
    inputs: [input],
    outputs: [output],
    mint: from_asset(policyID, name, quantity),
    validity_range: vr,
    fee: 1_000_000,
  }
}

validator task103 {
  spend(_d, _r, own_ref: OutputReference, transaction: Transaction) -> Bool {
    let Transaction { inputs, .. } = transaction
    expect Some(in) = list.find(inputs, fn(input) { input.output_reference == own_ref })
    // - Address: Verify signer
    let signer = in.output.address.payment_credential
    // trace(string.concat(@"signer: ", bytearray.to_hex(signer)))
    let well_signed = signer == VerificationKey(get_hash224_generator("1"))
    
    // - Time: Verify validity_range: ValidityRange,
    let valid_range: ValidityRange = transaction.validity_range
    let after = interval.is_entirely_after(valid_range, 10) 
    let before = interval.is_entirely_before(valid_range, 100)

    well_signed? && after? && before?
    

    // expect [Pair(asset_name, amount)] = assets.tokens(mint, get_policy_id_103()) |> dict.to_pairs()
    // trace(string.concat(@"asset_name: ", bytearray.to_hex(asset_name)))
    // trace(string.concat(@"amount: ", string.from_int(amount)))
    // amount == 1 && asset_name == get_token_name_103() && get_policy_id_103() == get_policy_id_103()
  }
 
  mint(_rdmr: Data, policy_id: PolicyId, transaction: Transaction) -> Bool {
    let Transaction { mint, .. } = transaction
    // - Minting: Verify minting
    expect [Pair(asset_name, amount)] =  assets.tokens(mint, policy_id) |> dict.to_pairs()
    trace(string.concat(@"policy_id: ", bytearray.to_hex(policy_id)))
    trace(string.concat(@"asset_name: ", bytearray.to_hex(asset_name)))
    trace(string.concat(@"amount: ", string.from_int(amount)))
    amount == 1 && asset_name == get_token_name_103() && policy_id == get_policy_id_103()
  }
  
//   withdraw() {
//     todo @"redeem"
//     let signer = inputs[0].output.address.payment_credential.verification_key
//     trace(string.concat(@"signer: ", bytearray.to_hex(signer))) 
//   }
}

test task_m103_policyID() {
  let pID = get_policy_id_103()
  trace(string.concat(@"pID: ", bytearray.to_hex(pID)))
  // trace( pID)
  bytearray.to_hex(pID) == @"83F150B143CBDDDA384B80ABE99E3352BDA898F444FA25ECB3D27B02"
}

test task_m103_policyID_mint() {
  let pID = get_policy_id_103()
  let vr: ValidityRange = interval.before(0)
  let tx = prepare_tx(pID, get_token_name_103(), 1, vr)
  let test_result = task103.mint(Void, pID, tx)
  test_result?
}

test task_m103_policyID_mint_bad_policyID() {
  let pID = get_policiy_id_generic(get_hash224_generator(""))
  let vr: ValidityRange = interval.before(0)
  let tx = prepare_tx(pID, get_token_name_103(), 1, vr)
  let test_result = task103.mint(Void, pID, tx)
  !test_result?
}

test task_m103_policyID_mint_bad() {
  let pID = get_policiy_id_generic(get_hash224_generator(""))
  let vr: ValidityRange = interval.before(0)
  let tx = prepare_tx(pID, get_name_generator("estADA"), 5, vr)
  let test_result = task103.mint(Void, pID, tx)
  !test_result?
}

test task_m103_policyID_spend() {
  let datum103 = None
  let redimer103 = Void
  let outr: OutputReference = get_output_reference_generatror(1, 0)

  let pID = get_policy_id_103()
  let vr: ValidityRange = interval.between(11, 99)
  let tx = prepare_tx(pID, get_token_name_103(), -1, vr)

  let test_result = task103.spend(datum103, redimer103, outr, tx)
  test_result?
}

test task_m103_policyID_spend_before_validity() {
  let datum103 = None
  let redimer103 = Void
  let outr: OutputReference = get_output_reference_generatror(1, 0)

  let vr: ValidityRange = interval.after(100)
  let pID = get_policy_id_103()
  let tx = prepare_tx(pID, get_token_name_103(), -1, vr)

  let after_100 = task103.spend(datum103, redimer103, outr, tx)
  !after_100?
}

test task_m103_policyID_spend_affter_validity() {
  let datum103 = None
  let redimer103 = Void
  let outr: OutputReference = get_output_reference_generatror(1, 0)

  let vr: ValidityRange = interval.before(10)
  let pID = get_policy_id_103()
  let tx = prepare_tx(pID, get_token_name_103(), -1, vr)

  let before_10 = task103.spend(datum103, redimer103, outr, tx)
  !before_10?
}
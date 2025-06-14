use cardano/script_context.{Minting, ScriptContext}
use cardano/transaction.{OutputReference, Transaction, placeholder}
use cardano/assets.{PolicyId, AssetName, from_asset, to_dict, quantity_of}
use mocktail.{mock_utxo_ref}
use aiken/primitive/bytearray
use aiken/primitive/string
use aiken/crypto.{blake2b_224}
use aiken/collection/dict


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

fn get_policy_id_generator() -> PolicyId {
  blake2b_224("")
}

fn get_token_name_103() -> ByteArray {
  "token_task103"
}

fn get_name_generator() -> ByteArray {
  "estADA"
}

validator task103 {
//   spend(_d, _r, own_ref: OutputReference, transaction: Transaction) -> Bool {
//     todo @"redeem"
//   }
 
  mint(_rdmr: Data, policy_id: PolicyId, transaction: Transaction) -> Bool {
    let Transaction { mint, .. } = transaction
    expect [Pair(asset_name, amount)] =  assets.tokens(mint, policy_id) |> dict.to_pairs()
    trace(string.concat(@"policy_id: ", bytearray.to_hex(policy_id)))
    trace(string.concat(@"asset_name: ", bytearray.to_hex(asset_name)))
    trace(string.concat(@"amount: ", string.from_int(amount)))
    // let minToken = Transaction.mint.assets.tokens(policy_id)
    // expect Some(amount) 
    // expect Some(asset_name) 
    // let mint_token = assets.tokens(mint, policy_id) |> dict.to_pairs()
    // let amount = quantity_of(mint, policy_id, get_token_name_103())
    // tokens.get(get_token_name())
    // expect Some(a_name) = tokens.get_asset_name()
    
    amount == 1 && asset_name == get_token_name_103() && policy_id == get_policy_id_103()


  }
  
//   withdraw() {
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
  let tx = Transaction {
    ..placeholder,
    mint: from_asset(pID, get_token_name_103(), 1),
  }
  let test_result = task103.mint(Void, pID, tx)
  test_result?
}

test task_m103_policyID_mint_bad_policyID() {
  let pID = get_policy_id_generator()
  let tx = Transaction {
    ..placeholder,
    mint: from_asset(pID, get_token_name_103(), 1),
  }
  let test_result = task103.mint(Void, pID, tx)
  !test_result?
}

test task_m103_policyID_mint_bad() {
  let pID = get_policy_id_generator()
  let tx = Transaction {
    ..placeholder,
    mint: from_asset(pID, get_name_generator(), 5),
  }
  let test_result = task103.mint(Void, pID, tx)
  !test_result?
}
use aiken/primitive/string
use aiken/collection/list
use aiken/collection/dict
use aiken/interval
use cardano/transaction.{Transaction, Input, Output, OutputReference, placeholder }//ValidityRange, NoDatum, OutputReference, }
use cardano/assets.{PolicyId, AssetName, Value, from_asset, quantity_of, tokens, ada_policy_id}//, from_lovelace, add}
use cardano/address.{Address, VerificationKey, from_verification_key}

use estada/mytools as mytools

// ==============================================
//         Exercise 1 Validator
// ==============================================

validator task_202_exercise1{
// Write and test a minting validator that mints only when the minted tokens are shared equally among two addresses.
// Half of the tokens must go to the party that is signing the transaction, and the other half must be sent to some other address.
  mint(_rdmr: Data, policy_id: PolicyId, tx: Transaction) -> Bool {
    let Transaction {outputs, mint, .. } = tx

    // Check if there are exactly two outputs
    if list.length(outputs) == 2 {
      when outputs is{ 
        [output1, output2]  -> {
        // Check if the value of both outputs assets amounts are the same
        // trace @"output1.value: "
        // trace(output1.value, policy_id)
        // trace @"output2.value: "
        // trace(output2.value)
        expect [Pair(asset_name, amount)] =  assets.tokens(mint, policy_id) |> dict.to_pairs()
        trace(string.concat(@"asset_name: ", string.from_bytearray(asset_name)))
        trace(string.concat(string.from_bytearray(asset_name), string.concat( @" amount: ", string.from_int(amount))))
        trace(string.concat(@"output1 amount: ", string.from_int(quantity_of(output1.value, policy_id, asset_name))))
        trace(string.concat(@"output2 amount: ", string.from_int(quantity_of(output2.value, policy_id, asset_name))))
        let is_same_value = quantity_of(output1.value, policy_id, asset_name) == quantity_of(output2.value, policy_id, asset_name)        
        
        // Check if the owner address recive minted tokens, his address must be in the outputs
        let signer_opt = list.head(tx.extra_signatories)
        trace @"signer_opt: "
        trace(signer_opt)
        let is_owner_recive_tokens = when signer_opt is {
          Some(signer) -> {
            let owner_address = address.from_verification_key(signer)
            trace @"owner_address: "
            trace(owner_address)
            list.any(outputs, fn(output) {output.address == owner_address })
          }
          _ -> fail
        }

        // Check if the mint tokens are shared by two diferent address in outputs
        trace @"output1.address: "
        trace(output1.address)
        trace @"output2.address: "
        trace(output2.address)
        let is_diferent_address = output1.address != output2.address
        is_same_value? && is_diferent_address? && is_owner_recive_tokens? 
        }
      _ -> False
      
      }
    }
      else{
        trace @"There are not two outputs"
        False
        }
  }

  else(_) {
    fail  
  }
}

// ==============================================
//         Exercise 1 Tests
// ==============================================

test test_task_202_exercise_1_succeed_mint_validator() {
  let policy_id_202: PolicyId = mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let list_of_assets: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: Input = mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, None)
  let input_two: Input = mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = list.push([input_one], input_two)
  let output_one: Output = mytools.prepare_output("GimbaLabs", 7_000_000, policy_id_202, token_name_202, 10)
  let output_two: Output = mytools.prepare_output("estADA", 7_000_000, policy_id_202, token_name_202, 10)
  let output_list: List<Output> = list.push([output_one], output_two)

  let tx = Transaction{
    ..placeholder,
    inputs: input_list,
    outputs: output_list,
    fee: 1_000_000,
    mint: list_of_assets,
    validity_range:  interval.everything,
    extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
  } 

  let mint_NFTs_succes = task_202_exercise1.mint(Void, policy_id_202, tx)
  mint_NFTs_succes?
}

test test_task_202_exercise_1_fail_by_diferent_amount_tokens_mint() {
  let policy_id_202: PolicyId = mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let list_of_assets: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: Input = mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, None)
  let input_two: Input = mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = list.push([input_one], input_two)
  let output_one: Output = mytools.prepare_output("GimbaLabs", 7_000_000, policy_id_202, token_name_202, 15)
  let output_two: Output = mytools.prepare_output("estADA", 7_000_000, policy_id_202, token_name_202, 5)
  let output_list: List<Output> = list.push([output_one], output_two)

  let tx = Transaction{
    ..placeholder,
    inputs: input_list,
    outputs: output_list,
    fee: 1_000_000,
    mint: list_of_assets,
    validity_range:  interval.everything,
    extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
  } 

  let mint_NFTs_succes = task_202_exercise1.mint(Void, policy_id_202, tx)
  !mint_NFTs_succes?
}

test test_task_202_exercise_1_fail_by_signer_not_recive_tokens_mint() {
  let policy_id_202: PolicyId = mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let list_of_assets: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: Input = mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, None)
  let input_two: Input = mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = list.push([input_one], input_two)
  let output_one: Output = mytools.prepare_output("administrador", 7_000_000, policy_id_202, token_name_202, 10)
  let output_two: Output = mytools.prepare_output("estADA", 7_000_000, policy_id_202, token_name_202, 10)
  let output_list: List<Output> = list.push([output_one], output_two)

  let tx = Transaction{
    ..placeholder,
    inputs: input_list,
    outputs: output_list,
    fee: 1_000_000,
    mint: list_of_assets,
    validity_range:  interval.everything,
    extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
  } 

  let mint_NFTs_succes = task_202_exercise1.mint(Void, policy_id_202, tx)
  !mint_NFTs_succes?
}

test test_task_202_exercise_1_fail_by_only_one_address_get_tokens() {
  let policy_id_202: PolicyId = mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let list_of_assets: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: Input = mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, None)
  let input_two: Input = mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = list.push([input_one], input_two)
  let output_one: Output = mytools.prepare_output("GimbaLabs", 7_000_000, policy_id_202, token_name_202, 20)
  // let output_two: Output = mytools.prepare_output("estADA", 7_000_000, policy_id_202, token_name_202, 10)
  // let output_list: List<Output> = list.push([output_one], output_two)

  let tx = Transaction{
    ..placeholder,
    inputs: input_list,
    outputs: [output_one],
    fee: 1_000_000,
    mint: list_of_assets,
    validity_range:  interval.everything,
    extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
  } 

  let mint_NFTs_succes = task_202_exercise1.mint(Void, policy_id_202, tx)
  !mint_NFTs_succes?
}

// ==============================================
//         Exercise 2 Validator
// ==============================================
// Write and test a validator that splits a payment equally between two user wallets. 
// This validator should unlock a UTxO and share all of its token equally among two wallets that are specified in the redeemer.

pub type Redeemer202 {
  addr1: Address,
  addr2: Address
}

validator task_202_exercise2{
  spend(_d, redeemer: Option<Redeemer202>, own_input: OutputReference, transaction: Transaction) -> Bool {
    let Transaction { inputs, outputs, .. } = transaction
    expect Some(own_ref) = list.find(inputs, fn(input) { input.output_reference == own_input })
    // get tokens from input
    let input_value = own_ref.output.value
    trace input_value

    let is_equitable_distribution = when outputs is{ 
        [output1, output2]  -> {

        // Search for PolicyId in different input tokens
        let policies = assets.policies(input_value)
        trace @"policies: "
        trace policies  
        // For each policyID search the token name and check if the amount of tokens is the same in both outputs
        // and if the amount of tokens is half of the total amount in the input
        // let is_equitable_distribution =  list.all(policies, fn(policy_id) {    
        let policy_without_ada = list.filter(policies, fn(policy_id){policy_id != ada_policy_id})
        let is_equitable =  list.all(policy_without_ada, fn(policy_id) {        
          let token_dict = assets.tokens(input_value, policy_id)
          let token_names = dict.keys(token_dict)
          trace token_names
          list.all(token_names, fn(asset_name) {
            let total = assets.quantity_of(input_value, policy_id, asset_name)
            trace string.concat(@"total: ", string.from_int(total))
            let half = total / 2
            trace string.concat(@"half: ", string.from_int(half))
            let out1 = assets.quantity_of(output1.value, policy_id, asset_name)
            trace string.concat(@"out1: ", string.from_int(out1))
            let out2 = assets.quantity_of(output2.value, policy_id, asset_name)
            trace string.concat(@"out2: ", string.from_int(out2))
            out1 == out2 && out2 == half
          })
        })
        let is_addresses_in_outputs = when redeemer is {
          Some(Redeemer202 { addr1, addr2 }) -> {
            trace @"output1.address: "
            trace(output1.address)
            trace @"redeemer.addr1: "
            trace(addr1)
            trace @"output2.address: "
            trace(output2.address)
            trace @"redeemer.addr2: "
            trace(addr2)
            let is_address1 = output1.address == addr1 || output1.address == addr2
            let is_address2 = output2.address == addr2 || output2.address == addr1
            is_address1 && is_address2
          }
          _ -> fail
        }
        is_equitable? && is_addresses_in_outputs?
       }
      _ -> False
      // trace @"There are not two outputs"

    }
    is_equitable_distribution?
  }
  else(_) {
    fail
  }
}
  

// ==============================================
//         Exercise 2 Tests
// ==============================================

test test_task_202_exercise_2_success_spend() {
  let policy_id_202: PolicyId = mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let token_value: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: Input = mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, Some(token_value))
  let input_two: Input = mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = list.push([input_one], input_two)
  let output_one: Output = mytools.prepare_output("GimbaLabs", 5_000_000, policy_id_202, token_name_202, 10)
  let output_two: Output = mytools.prepare_output("estADA", 5_000_000, policy_id_202, token_name_202, 10)
  let output_list: List<Output> = list.push([output_one], output_two)

  let inref: OutputReference = mytools.get_output_reference_generatror(1, 0)
  let tx = Transaction{
    ..placeholder,
    inputs: input_list,
    outputs: output_list,
    fee: 1_000_000,
    validity_range:  interval.everything,
    extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
  
  }
  let redeemer_202 = Some(Redeemer202 {addr1: output_one.address, addr2: output_two.address})
 
  let result = task_202_exercise2.spend(None, redeemer_202, inref, tx)
  result?
}
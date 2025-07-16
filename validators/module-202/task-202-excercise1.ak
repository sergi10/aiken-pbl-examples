use aiken/primitive/string
use aiken/collection/list
use aiken/collection/dict
use aiken/interval
use cardano/transaction.{Transaction, Input, Output, placeholder }//ValidityRange, NoDatum, OutputReference, }
use cardano/assets.{PolicyId, AssetName, Value, from_asset, quantity_of}//, from_lovelace, add}
use cardano/address//.{Address, VerificationKey, from_verification_key}

use estada/mytools as mytools

// ==============================================
//         Exercise 1
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
        trace @"output1.value: "
        trace(output1.value, policy_id)
        trace @"output2.value: "
        trace(output2.value)
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
      else{fail}
  }

  else(_) {
    fail  
  }
}

// ==============================================
//         Exercise 1 Tests
// ==============================================

test task_202_test_exercise_1_succeed_mint_validator() {
  //let policy_id_202: PolicyId = get_hash256_generator("GimbaLabs") 
  let policy_id_202: PolicyId = mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let list_of_assets: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: List<Input> = [mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000)]
  let input_two: Input = mytools.prepare_input(2, 1, "administrator", 5_000_000)
  let input_list: List<Input> = list.push(input_one, input_two)
  let output_one: List<Output> = [mytools.prepare_output("GimbaLabs", 7_000_000, policy_id_202, token_name_202, 10)]
  let output_two: Output = mytools.prepare_output("estADA", 7_000_000, policy_id_202, token_name_202, 10)
  let output_list: List<Output> = list.push(output_one, output_two)

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
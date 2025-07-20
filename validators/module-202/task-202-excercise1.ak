// use aiken/builtin.{debug}
use aiken/collection/dict
use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/interval
use aiken/primitive/string
//, from_lovelace, add}
use cardano/address.{Address}
use cardano/assets.{
  AssetName, PolicyId, Value, ada_policy_id, from_asset, merge, quantity_of,
}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, ValidityRange,
  placeholder,
}
use estada/mytools as mytools

// ==============================================
//         Exercise 1 Validator
// ==============================================

validator task_202_exercise1 {
  // Write and test a minting validator that mints only when the minted tokens are shared equally among two addresses.
  // Half of the tokens must go to the party that is signing the transaction, and the other half must be sent to some other address.
  mint(_rdmr: Data, policy_id: PolicyId, tx: Transaction) {
    let Transaction { outputs, mint, .. } = tx

    // Check if there are exactly two outputs
    if list.length(outputs) == 2 {
      when outputs is {
        [output1, output2] -> {
          // Check if the value of both outputs assets amounts are the same
          // trace @"output1.value: "
          // trace(output1.value)
          // trace @"output2.value: "
          // trace(output2.value)
          expect [Pair(asset_name, amount)] =
            assets.tokens(mint, policy_id) |> dict.to_pairs()
          trace string.concat(
            @"asset_name: ",
            string.from_bytearray(asset_name),
          )
          trace string.concat(
            string.from_bytearray(asset_name),
            string.concat(@" amount: ", string.from_int(amount)),
          )
          trace string.concat(
            @"output1 amount: ",
            string.from_int(quantity_of(output1.value, policy_id, asset_name)),
          )
          trace string.concat(
            @"output2 amount: ",
            string.from_int(quantity_of(output2.value, policy_id, asset_name)),
          )
          let is_same_value =
            quantity_of(output1.value, policy_id, asset_name) == quantity_of(
              output2.value,
              policy_id,
              asset_name,
            )
          // Check if the owner address recive minted tokens, his address must be in the outputs
          let signer_opt = list.head(tx.extra_signatories)
          trace @"signer_opt: "
          trace signer_opt
          let is_owner_recive_tokens =
            when signer_opt is {
              Some(signer) -> {
                let owner_address = address.from_verification_key(signer)
                trace @"owner_address: "
                trace owner_address
                list.any(
                  outputs,
                  fn(output) { output.address == owner_address },
                )
              }
              _ -> fail
            }

          // Check if the mint tokens are shared by two diferent address in outputs
          trace @"output1.address: "
          trace output1.address
          trace @"output2.address: "
          trace output2.address
          let is_diferent_address = output1.address != output2.address
          is_same_value? && is_diferent_address? && is_owner_recive_tokens?
        }
        _ -> False
      }
    } else {
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
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let list_of_assets: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: Input =
    mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, None)
  let input_two: Input =
    mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = list.push([input_one], input_two)
  let output_one: Output =
    mytools.prepare_output_token(
      "GimbaLabs",
      7_000_000,
      policy_id_202,
      token_name_202,
      10,
    )
  let output_two: Output =
    mytools.prepare_output_token(
      "estADA",
      7_000_000,
      policy_id_202,
      token_name_202,
      10,
    )
  let output_list: List<Output> = list.push([output_one], output_two)

  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      mint: list_of_assets,
      validity_range: interval.everything,
      extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
    }

  let mint_NFTs_succes = task_202_exercise1.mint(Void, policy_id_202, tx)
  mint_NFTs_succes?
}

test test_task_202_exercise_1_fail_by_diferent_amount_tokens_mint() {
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let list_of_assets: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: Input =
    mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, None)
  let input_two: Input =
    mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = list.push([input_one], input_two)
  let output_one: Output =
    mytools.prepare_output_token(
      "GimbaLabs",
      7_000_000,
      policy_id_202,
      token_name_202,
      15,
    )
  let output_two: Output =
    mytools.prepare_output_token(
      "estADA",
      7_000_000,
      policy_id_202,
      token_name_202,
      5,
    )
  let output_list: List<Output> = list.push([output_one], output_two)

  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      mint: list_of_assets,
      validity_range: interval.everything,
      extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
    }

  let mint_NFTs_succes = task_202_exercise1.mint(Void, policy_id_202, tx)
  !mint_NFTs_succes?
}

test test_task_202_exercise_1_fail_by_signer_not_recive_tokens_mint() {
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let list_of_assets: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: Input =
    mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, None)
  let input_two: Input =
    mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = list.push([input_one], input_two)
  let output_one: Output =
    mytools.prepare_output_token(
      "administrador",
      7_000_000,
      policy_id_202,
      token_name_202,
      10,
    )
  let output_two: Output =
    mytools.prepare_output_token(
      "estADA",
      7_000_000,
      policy_id_202,
      token_name_202,
      10,
    )
  let output_list: List<Output> = list.push([output_one], output_two)

  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      mint: list_of_assets,
      validity_range: interval.everything,
      extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
    }

  let mint_NFTs_succes = task_202_exercise1.mint(Void, policy_id_202, tx)
  !mint_NFTs_succes?
}

test test_task_202_exercise_1_fail_by_only_one_address_get_tokens() {
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let list_of_assets: Value = from_asset(policy_id_202, token_name_202, 20)
  let input_one: Input =
    mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, None)
  let input_two: Input =
    mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = list.push([input_one], input_two)
  let output_one: Output =
    mytools.prepare_output_token(
      "GimbaLabs",
      7_000_000,
      policy_id_202,
      token_name_202,
      20,
    )

  // let output_two: Output = mytools.prepare_output("estADA", 7_000_000, policy_id_202, token_name_202, 10)
  // let output_list: List<Output> = list.push([output_one], output_two)
  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: [output_one],
      fee: 1_000_000,
      mint: list_of_assets,
      validity_range: interval.everything,
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
  addr2: Address,
}

validator task_202_exercise2 {
  spend(
    _d,
    redeemer: Option<Redeemer202>,
    own_input: OutputReference,
    transaction: Transaction,
  ) {
    let Transaction { inputs, outputs, .. } = transaction
    expect Some(own_ref) =
      list.find(inputs, fn(input) { input.output_reference == own_input })
    // get tokens from input
    let input_value = own_ref.output.value

    // trace input_value
    let is_equitable_distribution =
      when outputs is {
        [output1, output2] -> {
          // Search for PolicyId in different input tokens
          let policies = assets.policies(input_value)
          trace @"policies: "
          trace policies
          // For each policyID search the token name and check if the amount of tokens is the same in both outputs
          // and if the amount of tokens is half of the total amount in the input
          // including ADA
          // let policy_list =  list.all(policies, fn(policy_id)     
          // whitout ADA
          let policy_list =
            list.filter(policies, fn(policy_id) { policy_id != ada_policy_id })
          let is_equitable =
            list.all(
              policy_list,
              fn(policy_id) {
                let token_dict = assets.tokens(input_value, policy_id)
                let token_names = dict.keys(token_dict)
                list.all(
                  token_names,
                  fn(asset_name) {
                    trace string.concat(
                      @"Token: ",
                      string.from_bytearray(asset_name),
                    )
                    // trace asset_name a
                    let total =
                      assets.quantity_of(input_value, policy_id, asset_name)
                    trace string.concat(@"total: ", string.from_int(total))
                    let half = total / 2
                    let even = total % 2 == 0
                    trace string.concat(@"half: ", string.from_int(half))
                    let out1 =
                      assets.quantity_of(output1.value, policy_id, asset_name)
                    trace string.concat(@"out1: ", string.from_int(out1))
                    let out2 =
                      assets.quantity_of(output2.value, policy_id, asset_name)
                    trace string.concat(@"out2: ", string.from_int(out2))
                    even && out1 == half && out1 == out2
                  },
                )
              },
            )
          let is_addresses_in_outputs =
            when redeemer is {
              Some(Redeemer202 { addr1, addr2 }) -> {
                trace @"output1.address: "
                trace output1.address
                trace @"redeemer.addr1: "
                trace addr1
                trace @"output2.address: "
                trace output2.address
                trace @"redeemer.addr2: "
                trace addr2
                let is_address1 =
                  output1.address == addr1 || output1.address == addr2
                let is_address2 =
                  output2.address == addr2 || output2.address == addr1
                is_address1 && is_address2
              }
              _ -> fail
            }
          is_equitable? && is_addresses_in_outputs?
        }
        _ -> False
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
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let token_name_202B: AssetName = "GimbaLabs_202"
  let input_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 20),
      from_asset(policy_id_202, token_name_202B, 30),
    )
  let input_one: Input =
    mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, Some(input_value_one))
  let input_two: Input =
    mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = [input_one, input_two]

  let output_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 15),
    )
  let output_one: Output =
    mytools.prepare_output("GimbaLabs", 5_000_000, Some(output_value_one))

  let output_value_two: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 15),
    )
  let output_two: Output =
    mytools.prepare_output("estADA", 5_000_000, Some(output_value_two))

  let output_list: List<Output> = [output_one, output_two]

  let inref: OutputReference = mytools.get_output_reference_generatror(1, 0)
  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      validity_range: interval.everything,
      extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
    }
  let redeemer_202 =
    Some(Redeemer202 { addr1: output_one.address, addr2: output_two.address })

  let result = task_202_exercise2.spend(None, redeemer_202, inref, tx)
  result?
}

test test_task_202_exercise_2_fail_wrong_redeemer_ddresses() {
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let token_name_202B: AssetName = "GimbaLabs_202"
  let input_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 20),
      from_asset(policy_id_202, token_name_202B, 30),
    )
  let input_one: Input =
    mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, Some(input_value_one))
  let input_two: Input =
    mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = [input_one, input_two]

  let output_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 15),
    )
  let output_one: Output =
    mytools.prepare_output("GimbaLabs", 5_000_000, Some(output_value_one))

  let output_value_two: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 15),
    )
  let output_two: Output =
    mytools.prepare_output("estADA", 5_000_000, Some(output_value_two))

  let output_list: List<Output> = [output_one, output_two]

  let inref: OutputReference = mytools.get_output_reference_generatror(1, 0)
  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      validity_range: interval.everything,
      extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
    }

  let redeemer_202 =
    Some(
      Redeemer202 {
        addr1: mytools.get_address("LimbaGabs", None),
        addr2: mytools.get_address("ADAest", None),
      },
    )

  let result = task_202_exercise2.spend(None, redeemer_202, inref, tx)
  !result?
}

test test_task_202_exercise_2_fail_non_equal_tokens() {
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let token_name_202B: AssetName = "GimbaLabs_202"
  let input_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 20),
      from_asset(policy_id_202, token_name_202B, 30),
    )
  let input_one: Input =
    mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, Some(input_value_one))
  let input_two: Input =
    mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = [input_one, input_two]

  let output_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 5),
      from_asset(policy_id_202, token_name_202B, 10),
    )
  let output_one: Output =
    mytools.prepare_output("GimbaLabs", 5_000_000, Some(output_value_one))

  let output_value_two: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 25),
    )
  let output_two: Output =
    mytools.prepare_output("estADA", 5_000_000, Some(output_value_two))

  let output_list: List<Output> = [output_one, output_two]

  let inref: OutputReference = mytools.get_output_reference_generatror(1, 0)
  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      validity_range: interval.everything,
      extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
    }
  let redeemer_202 =
    Some(Redeemer202 { addr1: output_one.address, addr2: output_two.address })

  let result = task_202_exercise2.spend(None, redeemer_202, inref, tx)
  !result?
}

test test_task_202_exercise_2_fail_odd_tokens() {
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let token_name_202B: AssetName = "GimbaLabs_202"
  let input_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 27),
      from_asset(policy_id_202, token_name_202B, 37),
    )
  let input_one: Input =
    mytools.prepare_input(1, 0, "GimbaLabs", 10_000_000, Some(input_value_one))
  let input_two: Input =
    mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let input_list: List<Input> = [input_one, input_two]

  let output_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 15),
    )
  let output_one: Output =
    mytools.prepare_output("GimbaLabs", 5_000_000, Some(output_value_one))

  let output_value_two: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 15),
    )
  let output_two: Output =
    mytools.prepare_output("estADA", 5_000_000, Some(output_value_two))

  let output_list: List<Output> = [output_one, output_two]

  let inref: OutputReference = mytools.get_output_reference_generatror(1, 0)
  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      validity_range: interval.everything,
      extra_signatories: [mytools.getHash("blake2b_224", "GimbaLabs")],
    }
  let redeemer_202 =
    Some(Redeemer202 { addr1: output_one.address, addr2: output_two.address })

  let result = task_202_exercise2.spend(None, redeemer_202, inref, tx)
  !result?
}

// ==============================================
//         Exercise 3 Validator
// ==============================================
// Extend the validator from Exercise 1 so that every UTxO is locked with a deadline. 
// If the deadline is not passed, then either one of two parties can unlock the tokens and share them equally.
// The the deadline is passed, then an administrator can unlock and claim the entire locked UTxO.

pub type Limit {
  deadline: Int,
}

validator task_202_exercise3 {
  spend(
    _datum: Option<Limit>,
    redeemer: Option<Redeemer202>,
    out_ref: OutputReference,
    tx: Transaction,
  ) {
    let Transaction { inputs, .. } = tx
    expect Some(input_ref) =
      list.find(inputs, fn(input) { input.output_reference == out_ref })

    expect InlineDatum(limit_datum) = input_ref.output.datum
    expect endline: Limit = limit_datum
    trace @"deadline: "
    trace endline.deadline
    trace @"tx.validity_range: "
    trace tx.validity_range.lower_bound
    trace tx.validity_range.upper_bound

    // let validity_range = tx.validity_range
    let is_before =
      interval.is_entirely_before(tx.validity_range, endline.deadline)

    let spend_signature =
      if is_before {
        trace @"Transaction is before the deadline"
        when redeemer is {
          Some(Redeemer202 { addr1, addr2 }) -> {
            let is_addr1_signed =
              list.any(inputs, fn(input) { input.output.address == addr1 })
            let is_addr2_signed =
              list.any(inputs, fn(input) { input.output.address == addr2 })
            is_addr1_signed? || is_addr2_signed?
          }
          _ -> fail
        }
      } else {
        trace @"Transaction is after the deadline"

        // Check if the transaction is signed by one of the two parties
        // Check if the transaction is signed by the administrator
        let administrator: VerificationKeyHash =
          mytools.getHash("blake2b_224", "administrator")
        trace @"administrator: "
        trace administrator
        let is_administrator_signed =
          list.any(
            tx.extra_signatories,
            fn(signature) {
              trace @"signer_vk: "
              trace signature
              signature == administrator
            },
          )
        is_administrator_signed?
      }
    spend_signature?
  }

  else(_) {
    fail
  }
}

// ==============================================
//         Exercise 3 Tests
// ==============================================

test test_task_202_exercise_3_success_spend_in_deadline() {
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let token_name_202B: AssetName = "GimbaLabs_202"
  let input_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 20),
      from_asset(policy_id_202, token_name_202B, 30),
    )

  let input_one: Input =
    mytools.prepare_input(10, 1, "GimbaLabs", 10_000_000, Some(input_value_one))

  let updated_output =
    Output { ..input_one.output, datum: InlineDatum(Limit { deadline: 1000 }) }
  let updated_input = Input { ..input_one, output: updated_output }

  let input_list: List<Input> = [updated_input]
  let output_value: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 15),
    )
  let output_one: Output =
    mytools.prepare_output("GimbaLabs", 5_000_000, Some(output_value))

  let output_two: Output =
    mytools.prepare_output("estADA", 5_000_000, Some(output_value))
  let output_list: List<Output> = [output_one, output_two]

  let inref: OutputReference = mytools.get_output_reference_generatror(10, 1)
  let vr: ValidityRange = interval.before(999)
  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      validity_range: vr,
    }

  let redeemer_202 =
    Redeemer202 { addr1: output_one.address, addr2: output_two.address }

  let result = task_202_exercise3.spend(None, Some(redeemer_202), inref, tx)
  result?
}

test test_task_202_exercise_3_success_spend_out_deadline_signed_by_admin() {
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let token_name_202B: AssetName = "GimbaLabs_202"
  let input_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 20),
      from_asset(policy_id_202, token_name_202B, 30),
    )

  let input_one: Input =
    mytools.prepare_input(10, 1, "GimbaLabs", 10_000_000, Some(input_value_one))

  let input_two: Input =
    mytools.prepare_input(2, 1, "administrator", 5_000_000, None)
  let updated_output =
    Output { ..input_one.output, datum: InlineDatum(Limit { deadline: 1000 }) }
  let updated_input = Input { ..input_one, output: updated_output }

  let input_list: List<Input> = [updated_input, input_two]
  let output_value: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 15),
    )
  let output_one: Output =
    mytools.prepare_output("GimbaLabs", 5_000_000, Some(output_value))

  let output_two: Output =
    mytools.prepare_output("estADA", 5_000_000, Some(output_value))
  let output_list: List<Output> = [output_one, output_two]

  let inref: OutputReference = mytools.get_output_reference_generatror(10, 1)
  let vr: ValidityRange = interval.before(1111)
  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      validity_range: vr,
      extra_signatories: [mytools.getHash("blake2b_224", "administrator")],
    }
  let redeemer_202 =
    Redeemer202 { addr1: output_one.address, addr2: output_two.address }

  let result = task_202_exercise3.spend(None, Some(redeemer_202), inref, tx)
  result?
}

test test_task_202_exercise_3_fail_out_deadline_not_signed_by_admin() {
  let policy_id_202: PolicyId =
    mytools.getHash("blake2b_256", mytools.getHash("blake2b_256", "GimbaLabs"))
  let token_name_202: AssetName = "estADA_202"
  let token_name_202B: AssetName = "GimbaLabs_202"
  let input_value_one: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 20),
      from_asset(policy_id_202, token_name_202B, 30),
    )

  let input_one: Input =
    mytools.prepare_input(10, 1, "GimbaLabs", 10_000_000, Some(input_value_one))

  let updated_output =
    Output { ..input_one.output, datum: InlineDatum(Limit { deadline: 1000 }) }
  let updated_input = Input { ..input_one, output: updated_output }

  let input_list: List<Input> = [updated_input]
  let output_value: Value =
    merge(
      from_asset(policy_id_202, token_name_202, 10),
      from_asset(policy_id_202, token_name_202B, 15),
    )
  let output_one: Output =
    mytools.prepare_output("GimbaLabs", 5_000_000, Some(output_value))

  let output_two: Output =
    mytools.prepare_output("estADA", 5_000_000, Some(output_value))
  let output_list: List<Output> = [output_one, output_two]

  let inref: OutputReference = mytools.get_output_reference_generatror(10, 1)
  let vr: ValidityRange = interval.before(1111)
  let tx =
    Transaction {
      ..placeholder,
      inputs: input_list,
      outputs: output_list,
      fee: 1_000_000,
      validity_range: vr,
    }
  let redeemer_202 =
    Redeemer202 { addr1: output_one.address, addr2: output_two.address }

  let result = task_202_exercise3.spend(None, Some(redeemer_202), inref, tx)
  !result?
}

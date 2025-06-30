use aiken/primitive/string
use aiken/crypto.{blake2b_224}
use aiken/collection/list
use cardano/transaction.{ Transaction, placeholder}
use cardano/assets.{PolicyId, AssetName, Value, from_lovelace, add}


//task 103 Create a mock transaction where two different NFTs are minted. Write a passing test and a failing test and show that both tests work as expected.

fn get_policiy_id_generic(random: ByteArray) -> PolicyId {
  blake2b_224(random)
}

fn add_value_to_value(value: Value, policy_id: PolicyId, asset_name: AssetName, amount: Int) -> Value {
  let assets: Value = add(value, policy_id, asset_name, amount)
  assets
}

fn prepare_tx_evidence_102(list_of_assets: Value) -> Transaction {
  Transaction {
    ..placeholder,
    mint: list_of_assets    
  }
}

validator evidence_task103 {
    mint(_rdmr: Data, _policy_id: PolicyId, transaction: Transaction) -> Bool {
    let Transaction { mint, .. } = transaction
    let assets: List<(PolicyId, AssetName, Int)> = assets.flatten(mint)
    trace @"assets: "
    trace(assets)
    let num_of_nfts = list.length(assets)
    trace(string.concat(@"Minted assets: ", string.from_int(num_of_nfts)))
    //check if the number of NFTs is only between 1 and 2
    let is_valid_num_of_nfts = num_of_nfts > 0 && num_of_nfts <= 2
    trace is_valid_num_of_nfts
  
    let policy_id_1 = get_policiy_id_generic("Gimba")
    let policy_id_2 = get_policiy_id_generic("Labs")
    let token_name_1: AssetName = "estADA_1"
    let token_name_2: AssetName = "estADA_2"
    let policies =
      mint
        |> assets.flatten
        |> list.map(fn(t) {t.1st })
    trace @"policies of minted assets: "
    trace(policies)
    //check if the both policyID are in the value of the mint
    let is_valid_policy_id = list.has(policies, policy_id_1) || list.has(policies, policy_id_2)
    trace is_valid_policy_id

    let names =
      mint
        |> assets.flatten
        |> list.map(fn(t) {t.2nd })
    trace @"names of minted assets: "
    trace(names)
    //check if the both names are in the value of the mint
    let is_valid_names = list.has(names, token_name_1) || list.has(names, token_name_2)
    trace is_valid_names

    let quantities =
      mint
        |> assets.flatten
        |> list.map(fn(t) {t.3rd })
    trace @"Quantities of minted assets: "
    trace(quantities)
    //check if the amount are only 1 no allow more than 1 policyID + name
    let is_valid_quantities = list.count(quantities, fn(n) { n > 1 }) == 0
    // False is OK -> 0 assets with amount > 1
    // True is not OK -> 1 or more assets with amount > 1
    trace is_valid_quantities

    is_valid_num_of_nfts && is_valid_policy_id && is_valid_names && is_valid_quantities
  }
  else(_) {
    fail
  }  
}

// ==============================================
//                   TESTS
// ==============================================

test task_m103_minting_different_NFT_succesful() {
  let policy_id_1 = get_policiy_id_generic("Gimba")
  let policy_id_2 = get_policiy_id_generic("Labs")
  let token_name_1: AssetName = "estADA_1"
  let token_name_2: AssetName = "estADA_2"
  let list_of_assets: Value = add_value_to_value(
    from_lovelace(0),
    policy_id_1,
    token_name_1,
    1
  )
  let list_of_assets: Value = add_value_to_value(
    list_of_assets,
    policy_id_2,
    token_name_2,
    1
  )
  let tx = prepare_tx_evidence_102(list_of_assets)
  let mint_NFTs_succes = evidence_task103.mint(Void, get_policiy_id_generic(""), tx)
  mint_NFTs_succes?
}

test task_m103_minting_different_NFT_fail_policyID() {
  let policy_id_1 = get_policiy_id_generic("GimbaLabs")
  let policy_id_2 = get_policiy_id_generic("GimbaLabs")
  let token_name_1: AssetName = "estADA_1"
  let token_name_2: AssetName = "estADA_2"
  let list_of_assets: Value = add_value_to_value(
    from_lovelace(0),
    policy_id_1,
    token_name_1,
    1
  )
  let list_of_assets: Value = add_value_to_value(
    list_of_assets,
    policy_id_2,
    token_name_2,
    1
  )
  let tx = prepare_tx_evidence_102(list_of_assets)
  let mint_NFTs_succes = evidence_task103.mint(Void, get_policiy_id_generic(""), tx)
  !mint_NFTs_succes?
}
test task_m103_minting_different_NFT_fail_name() {
  let policy_id_1 = get_policiy_id_generic("Gimba")
  let policy_id_2 = get_policiy_id_generic("Labs")
  let token_name_1: AssetName = "estADA0"
  let token_name_2: AssetName = "estADA00"
  let list_of_assets: Value = add_value_to_value(
    from_lovelace(0),
    policy_id_1,
    token_name_1,
    1
  )
  let list_of_assets: Value = add_value_to_value(
    list_of_assets,
    policy_id_2,
    token_name_2,
    1
  )
  let tx = prepare_tx_evidence_102(list_of_assets)
  let mint_NFTs_succes = evidence_task103.mint(Void, get_policiy_id_generic(""), tx)
  !mint_NFTs_succes?
}

test task_m103_minting_different_NFT_fail_quantity() {
  let policy_id_1 = get_policiy_id_generic("Gimba")
  let policy_id_2 = get_policiy_id_generic("Labs")
  let token_name_1: AssetName = "estADA_1"
  let token_name_2: AssetName = "estADA_2"
  let list_of_assets: Value = add_value_to_value(
    from_lovelace(0),
    policy_id_1,
    token_name_1,
    2
  )
  let list_of_assets: Value = add_value_to_value(
    list_of_assets,
    policy_id_2,
    token_name_2,
    1
  )
  let tx = prepare_tx_evidence_102(list_of_assets)
  let mint_NFTs_succes = evidence_task103.mint(Void, get_policiy_id_generic(""), tx)
  !mint_NFTs_succes?
}
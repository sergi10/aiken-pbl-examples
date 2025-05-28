// use cardano/script_context.{Minting, ScriptContext}
use cardano/transaction.{OutputReference, Transaction, placeholder}
use mocktail.{mock_utxo_ref}
use aiken/primitive/bytearray
use aiken/primitive/string


// HOMEWORKS 102
// 1 - Define a custom type for datum and another for redeemer.
pub type Redeemer102 {
  One
  Two
  Three
}

pub type Datum102 {
  msg: ByteArray 
}

validator task102 {
  spend(
    datum: Option<Datum102>,
    redeemer:  Redeemer102,
    _utxo: OutputReference,
    _self: Transaction,
  ){
    expect Some(d102) = datum
    let text102  = d102.msg
    when redeemer is {
      One -> 
        (text102 == "hello world")?
      _ -> trace @"Bad redeemer option"
           False
    }
  }
  else(_) {
    fail
  }
}

// 3 - Write tests to show that your validator works as expected.
test task_m102_test_custom_datum_succeed_spending_validator() {
  trace @"validate for task_m102 spending transaction Datum OK; Redeemer OK"
  let msg102 = Datum102 {msg:"hello world"}
  let r102 = One 

  trace(string.concat(@"Datum OK bytearray: ", bytearray.to_hex(msg102.msg)))
  trace(string.concat(@"Datum OK String: ", string.from_bytearray(msg102.msg)))
  trace @"Redeemer102 OK: "
  trace r102
 
  let test_result = task102.spend(Some(msg102), r102, mock_utxo_ref(0, 0), placeholder)
  test_result?
}

test task_m102_test_custom_datum_succeed_spending_validator2() {
  trace @"validate for task_m102 spending transaction Datum K0; Redeemer OK"
  let msg102 = Datum102 {msg:"Wello Horld"}
  let r102 = One 

  trace(string.concat(@"Datum OK bytearray: ", bytearray.to_hex(msg102.msg)))
  trace(string.concat(@"Datum OK String: ", string.from_bytearray(msg102.msg)))
  trace @"Redeemer102 OK: "
  trace r102

  let test_result = task102.spend(Some(msg102), r102, mock_utxo_ref(0, 0), placeholder)
  !test_result?
}

test task_m102_test_custom_datum_succeed_spending_validator3() {
  trace @"validate for task_m102 spending transaction Datum OK; Redeemer KO"
  let msg102 = Datum102 {msg:"hello world"}
  let r102 = Two //One 

  trace(string.concat(@"Datum OK bytearray: ", bytearray.to_hex(msg102.msg)))
  trace(string.concat(@"Datum OK String: ", string.from_bytearray(msg102.msg)))
  trace @"Redeemer102 KO: "
  trace r102
  
  let test_result = task102.spend(Some(msg102), r102, mock_utxo_ref(0, 0), placeholder)
  !test_result?
}

test task_m102_test_custom_datum_succeed_spending_validator4() {
  trace @"validate for task_m102 spending transaction Datum KO; Redeemer KO"
  let msg102 = Datum102 {msg:"wello horld"}
  let r102 = Two //One 

  trace(string.concat(@"Datum KO bytearray: ", bytearray.to_hex(msg102.msg)))
  trace(string.concat(@"Datum KO String: ", string.from_bytearray(msg102.msg)))
  trace @"Redeemer102 KO: "
  trace r102
  
  let test_result = task102.spend(Some(msg102), r102, mock_utxo_ref(0, 0), placeholder)
  !test_result?
}
test m101_p2_variable_tracing() {
  let check_a = False
  let check_b = True
  check_a? && check_b?
}

test m101_p2_trace_message() {
  trace @"is_even"
  10 % 2 == 0
}

test m101_p2_trace_integer_message() {
  let num1: Int = 1
  let num2: Int = 2
  // let msg: String = @"Value nu1gt2m1 is:" + String(Int(num2))
  // trace msg
  let greater_than = num2 < num1
  greater_than?
  // trace @"Value num2 is:"
  // let 2gt1 = num2 > num1

}

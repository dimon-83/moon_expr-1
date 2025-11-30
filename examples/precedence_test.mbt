test "operator precedence mixed" {
  // * has higher precedence (60) than + (30)
  let v1 = @api.eval_str("1 + 2 * 3", {})
  inspect(v1.to_string(), content="Int(7)")

  // and (15) has higher precedence than or (10)
  // false and false or true -> (false and false) or true -> false or true -> true
  let v2 = @api.eval_str("false and false or true", {})
  inspect(v2.to_string(), content="Bool(true)")

  // false and (false or true) -> false and true -> false
  let v3 = @api.eval_str("false and (false or true)", {})
  inspect(v3.to_string(), content="Bool(false)")
}

test "operator associativity" {
  // - is left associative
  // 1 - 2 - 3 -> (1 - 2) - 3 -> -1 - 3 -> -4
  let v1 = @api.eval_str("1 - 2 - 3", {})
  inspect(v1.to_string(), content="Int(-4)")

  // ^ (pow) is right associative
  // 2 ^ 3 ^ 2 -> 2 ^ (3 ^ 2) -> 2 ^ 9 -> 512
  // If left: (2 ^ 3) ^ 2 -> 8 ^ 2 -> 64
  let v2 = @api.eval_str("2 ^ 3 ^ 2", {})
  inspect(v2.to_string(), content="Int(512)")
}

test "basic eval" {
  let v = @api.eval_str("(a+b)-c", { "a": @runtime.Value::Int(2L), "b": @runtime.Value::Int(3L), "c": @runtime.Value::Int(1L) })
  inspect(v.to_string(), content="Int(4)")
}

test "eval arithmetic pow" {
  let v = @api.eval_str("2^3", {})
  inspect(v.to_string(), content="Int(8)")
}

test "eval logical and" {
  let v = @api.eval_str("true and false", {})
  inspect(v.to_string(), content="Bool(false)")
}

test "eval logical or" {
  let v = @api.eval_str("false or true", {})
  inspect(v.to_string(), content="Bool(true)")
}

test "eval logical short-circuit" {
  // If short-circuit works, the second part won't be evaluated (and won't error if it's invalid/null, but here we just check logic)
  let v = @api.eval_str("true or false", {})
  inspect(v.to_string(), content="Bool(true)")
}

test "eval comparison" {
  let v = @api.eval_str("1 < 2", {})
  inspect(v.to_string(), content="Bool(true)")
}

test "eval instance method" {
   let prog = @api.compile(expression="a * (b**3-1)/2")
   let res = prog.evaluate({ "a": @runtime.Value::Int(3L), "b": @runtime.Value::Int(2L) })
   // 3 * (8-1)/2 = 3 * 7 / 2 = 21 / 2 = 10.5 (Float division)
   inspect(res.to_string(), content="Float(10.5)")
}

test "eval complex boolean logic" {
  let expr = "foo < 0 or (bar > 10 and baz == 5) or (qux <= 1 and quux >= 10 and corge > 0.5)"
  let prog = @api.compile(expression=expr)

  // Case 1: foo < 0 (True) -> True (Short-circuit)
  let res1 = prog.evaluate({ "foo": @runtime.Value::Int(-1L) })
  inspect(res1.to_string(), content="Bool(true)")

  // Case 2: foo >= 0, bar > 10, baz == 5 (True) -> True
  let res2 = prog.evaluate({ 
    "foo": @runtime.Value::Int(1L),
    "bar": @runtime.Value::Int(11L),
    "baz": @runtime.Value::Int(5L)
  })
  inspect(res2.to_string(), content="Bool(true)")

  // Case 3: foo >= 0, bar <= 10, qux <= 1, quux >= 10, corge > 0.5 (True) -> True
  let res3 = prog.evaluate({
    "foo": @runtime.Value::Int(1L),
    "bar": @runtime.Value::Int(9L), // Fail 2nd clause
    "qux": @runtime.Value::Int(1L),
    "quux": @runtime.Value::Int(10L),
    "corge": @runtime.Value::Float(0.6)
  })
  inspect(res3.to_string(), content="Bool(true)")

  // Case 4: All False -> False
  let res4 = prog.evaluate({
    "foo": @runtime.Value::Int(10L),
    "bar": @runtime.Value::Int(5L),
    "qux": @runtime.Value::Int(2L)
  })
  inspect(res4.to_string(), content="Bool(false)")
}

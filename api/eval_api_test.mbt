test "api eval_str arithmetic" {
  let v = eval_str("(a+b)-c", { "a": @runtime.Value::Int(2L), "b": @runtime.Value::Int(3L), "c": @runtime.Value::Int(1L) })
  inspect(v.to_string(), content="Int(4)")
}

test "api eval_str ident lookup" {
  let v = eval_str("x", { "x": @runtime.Value::Int(7L) })
  inspect(v.to_string(), content="Int(7)")
}

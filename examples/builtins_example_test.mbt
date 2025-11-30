test "builtins" {
  let v = @api.eval_str("len(name)", { "name": @runtime.Value::Str("abc") })
  inspect(v.to_string(), content="Int(3)")
}
test "string contains" {
  let v = @api.eval_str("contains(name, \"bc\")", { "name": @runtime.Value::Str("abc") })
  inspect(v.to_string(), content="Bool(true)")
}

test "string contains infix" {
  let v = @api.eval_str("name contains \"bc\"", { "name": @runtime.Value::Str("abc") })
  inspect(v.to_string(), content="Bool(true)")
}

test "string startsWith endsWith" {
  let v1 = @api.eval_str("startsWith(name, \"ab\")", { "name": @runtime.Value::Str("abc") })
  inspect(v1.to_string(), content="Bool(true)")
  let v2 = @api.eval_str("endsWith(name, \"bc\")", { "name": @runtime.Value::Str("abc") })
  inspect(v2.to_string(), content="Bool(true)")
}

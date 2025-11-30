test "float_arithmetic" {
  inspect(@api.eval_str("1.5 + 2.5", {}).to_string(), content="Float(4)")
  inspect(@api.eval_str("10.0 / 4.0", {}).to_string(), content="Float(2.5)")
  inspect(@api.eval_str("1.5 * 3.0", {}).to_string(), content="Float(4.5)")
}

test "mixed_arithmetic" {
  inspect(@api.eval_str("1 + 2.5", {}).to_string(), content="Float(3.5)")
  inspect(@api.eval_str("2.5 * 2", {}).to_string(), content="Float(5)")
  inspect(@api.eval_str("5 - 2.5", {}).to_string(), content="Float(2.5)")
}

test "math_functions" {
  inspect(@api.eval_str("abs(-10)", {}).to_string(), content="Int(10)")
  inspect(@api.eval_str("abs(-10.5)", {}).to_string(), content="Float(10.5)")
  inspect(@api.eval_str("min(5, 10)", {}).to_string(), content="Int(5)")
  inspect(@api.eval_str("max(5, 10)", {}).to_string(), content="Int(10)")
  inspect(@api.eval_str("pow(2, 3)", {}).to_string(), content="Int(8)")
}

test "string_functions" {
  inspect(@api.eval_str("upper(\"hello\")", {}).to_string(), content="Str(\"HELLO\")")
  inspect(@api.eval_str("lower(\"WORLD\")", {}).to_string(), content="Str(\"world\")")
}

test "collection_functions" {
  let arr_int = @runtime.Value::Array([@runtime.Value::Int(1L), @runtime.Value::Int(2L), @runtime.Value::Int(3L)])
  let arr_float = @runtime.Value::Array([@runtime.Value::Float(1.5), @runtime.Value::Float(2.5)])
  
  let vars = {
    "nums": arr_int,
    "floats": arr_float
  }
  
  inspect(@api.eval_str("sum(nums)", vars).to_string(), content="Int(6)")
  inspect(@api.eval_str("sum(floats)", vars).to_string(), content="Float(4)")
  inspect(@api.eval_str("avg(nums)", vars).to_string(), content="Float(2)")
  inspect(@api.eval_str("avg(floats)", vars).to_string(), content="Float(2)")
}

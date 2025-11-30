test "custom function" {
  let reg = @api.default_registry()
  @api.register_function(reg, "add10", 1, fn(args) {
    match args[0] {
      @runtime.Value::Int(v) => @runtime.Value::Int(v + 10L)
      _ => @runtime.Value::Null
    }
  })
  
  let v = @api.eval_str("add10(5)", {}, registry=reg)
  inspect(v.to_string(), content="Int(15)")
}

test "custom function with infix operator syntax" {
  let reg = @api.default_registry()
  @api.register_function(reg, "myOp", 2, fn(args) {
    match args[0] {
      @runtime.Value::Int(a) => match args[1] {
        @runtime.Value::Int(b) => @runtime.Value::Int(a + b * 2L)
        _ => @runtime.Value::Null
      }
      _ => @runtime.Value::Null
    }
  })
  
  // Since "myOp" is not in operator table, it can only be used as function call
  let v = @api.eval_str("myOp(3, 4)", {}, registry=reg)
  inspect(v.to_string(), content="Int(11)")
}

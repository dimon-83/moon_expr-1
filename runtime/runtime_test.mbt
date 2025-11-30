test "env get existing" {
  let env = Env::from_map({ "a": Value::Int(5L) })
  let v = env.get("a")
  inspect(v.to_string(), content="Int(5)")
}

test "env get missing" {
  let env = Env::new()
  let v = env.get("no")
  inspect(v.to_string(), content="Null")
}

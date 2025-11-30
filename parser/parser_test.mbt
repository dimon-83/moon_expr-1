test "parse parentheses and arithmetic" {
  let e = parse("(1+2)-3")
  inspect(e.to_string(), content="((1 + 2) - 3)")
}

test "parse ident and unary" {
  let e = parse("-x")
  inspect(e.to_string(), content="-(x)")
}

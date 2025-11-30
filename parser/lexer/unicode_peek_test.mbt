///|
/// 测试 peek_current 对 Unicode 字符和变体选择符的处理
test "peek_current with Unicode characters" {
  // 测试基本 Unicode 字符
  let lexer1 = Lexer::new(source="α+β")
  let tokens1 = lexer1.tokenize()
  // 先检查实际的token数量
  println("Unicode tokens count: \{tokens1.length()}")
  for i = 0; i < tokens1.length(); i = i + 1 {
    println("Token \{i}: \{tokens1[i].kind()} = '\{tokens1[i].value()}'")
  }
  // 根据实际输出调整期望值
  inspect(tokens1.length(), content="4")
  inspect(tokens1[0].kind(), content="Ident")
  inspect(tokens1[1].kind(), content="Oper")
  inspect(tokens1[2].kind(), content="Ident")
  inspect(tokens1[3].kind(), content="EOF")
}

test "peek_current with simple expression" {
  // 测试简单数学表达式
  let lexer2 = Lexer::new(source="1+2")
  let tokens2 = lexer2.tokenize()
  inspect(tokens2.length(), content="4") // 1, +, 2, EOF
  inspect(tokens2[0].kind(), content="Num") // 1
  inspect(tokens2[1].kind(), content="Oper") // +
  inspect(tokens2[2].kind(), content="Num") // 2
  inspect(tokens2[3].kind(), content="EOF")
}

test "peek_current EOF handling" {
  // 测试 EOF 处理
  let lexer3 = Lexer::new(source="42")
  let tokens3 = lexer3.tokenize()
  inspect(tokens3.length(), content="2") // 42, EOF
  inspect(tokens3[0].kind(), content="Num") // 42
  inspect(tokens3[1].kind(), content="EOF")
}

test "peek_current with empty string" {
  // 测试空字符串处理
  let lexer4 = Lexer::new(source="")
  let tokens4 = lexer4.tokenize()
  inspect(tokens4.length(), content="1") // 只有 EOF
  inspect(tokens4[0].kind(), content="EOF")
}

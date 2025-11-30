// Pratt 解析器：基于操作符优先级/结合律的表达式解析
// 设计思路：
// - 先将源字符串经词法器切分为 Token 流
// - 前缀解析处理字面量/标识符/括号与一元运算
// - 后缀解析处理函数调用（支持多参数）
// - 主循环按照操作符表进行绑定强度驱动，生成 Binary、Unary 等 AST
// 使用示例：
// - let e = parse("(1+2)-len(name)")
// - e.to_string() -> "((1 + 2) - len)"

struct P { ts: Array[@lexer.Token]; mut i: Int }

// Token 流辅助：取当前/前进/获取种类与文本
pub fn P::new(ts~: Array[@lexer.Token]) -> P { P::{ ts, i: 0 } }
fn P::peek(self: P) -> @lexer.Token { if self.i < self.ts.length() { self.ts[self.i] } else { @lexer.Token::new_empty() } }
fn P::advance(self: P) -> @lexer.Token { let t = P::peek(self); self.i = self.i + 1; t }
fn P::kind(self: P) -> @lexer.Kind { P::peek(self).kind() }
fn P::value(self: P) -> String { P::peek(self).value() }

// 将数值字面量文本解析为 Int64（支持下划线分隔）
fn parse_int_literal(s: String) -> Int64 {
  let mut v : Int64 = 0L
  let mut idx = 0
  for {
    match s.get_char(idx) {
      Some(ch) => {
        if ch >= '0' && ch <= '9' {
          v = v * 10L + (ch.to_int() - '0'.to_int()).to_int64()
          idx = idx + 1
          continue
        } else if ch == '_' { idx = idx + 1; continue } else { break }
      }
      None => break
    }
  }
  v
}

// 前缀解析：处理一元运算、字面量、标识符与括号分组
fn parse_prefix(p: P) -> Expr {
  match P::kind(p) {
    @lexer.Kind::Oper => {
      let op = P::value(p)
      match @lexer.find_unary_operator(op) {
        Some(u) => { ignore(P::advance(p)); let rhs = parse_bp(p, @lexer.Operator::precedence(u)); Expr::Unary(op, rhs) }
        None => {
          ignore(P::advance(p))
          // 如果是类似标识符的操作符（如 contains），且不是一元操作符，则视为标识符处理（支持函数调用语法）
          if @lexer.is_valid_identifier(op) {
            Expr::Ident(op)
          } else {
            Expr::NullLit
          }
        }
      }
    }
    @lexer.Kind::Num => {
      let s = P::value(p)
      ignore(P::advance(p))
      if s.contains(".") || s.contains("e") || s.contains("E") {
        let buf = StringBuilder::new()
        for c in s {
          if c != '_' { buf.write_char(c) }
        }
        let val = try {
          @strconv.parse_double(buf.to_string())
        } catch {
          _ => 0.0
        }
        Expr::DoubleLit(val)
      } else {
        Expr::IntLit(parse_int_literal(s))
      }
    }
    @lexer.Kind::Str => { let s = P::value(p); ignore(P::advance(p)); Expr::StrLit(s) }
    @lexer.Kind::Ident => {
      let s = P::value(p)
      ignore(P::advance(p))
      if s == "true" {
        Expr::BoolLit(true)
      } else if s == "false" {
        Expr::BoolLit(false)
      } else if s == "null" {
        Expr::NullLit
      } else {
        Expr::Ident(s)
      }
    }
    @lexer.Kind::Bracket => {
      if P::value(p) == "(" { ignore(P::advance(p)); let inner = parse_bp(p, 0); if P::kind(p) == @lexer.Kind::Bracket && P::value(p) == ")" { ignore(P::advance(p)) } ; Expr::Grouping(inner) } else { ignore(P::advance(p)); Expr::NullLit }
    }
    _ => { ignore(P::advance(p)); Expr::NullLit }
  }
}

// 后缀解析：处理函数调用（多参数逗号分隔），将 Ident 转为 Call
fn parse_postfix(p: P, lhs: Expr) -> Expr {
  let mut cur = lhs
  for {
    if P::kind(p) == @lexer.Kind::Bracket && P::value(p) == "(" {
      ignore(P::advance(p))
      let args : Array[Expr] = []
      if !(P::kind(p) == @lexer.Kind::Bracket && P::value(p) == ")") {
        let e = parse_bp(p, 0)
        args.push(e)
        for {
          if P::kind(p) == @lexer.Kind::Oper && P::value(p) == "," {
            ignore(P::advance(p))
            let ee = parse_bp(p, 0)
            args.push(ee)
            continue
          }
          break
        }
      }
      if P::kind(p) == @lexer.Kind::Bracket && P::value(p) == ")" { ignore(P::advance(p)) }
      match cur {
        Expr::Ident(name) => { cur = Expr::Call(name, args) }
        _ => { () }
      }
      continue
    }
    break
  }
  cur
}

// Pratt 主循环：按 min binding power 递归解析二元表达式
fn parse_bp(p: P, min_bp: Int) -> Expr {
  let mut lhs = parse_prefix(p)
  lhs = parse_postfix(p, lhs)
  for {
    if P::kind(p) != @lexer.Kind::Oper { break }
    let op = P::value(p)
    match @lexer.find_binary_operator(op) {
      Some(info) => {
        let prec = @lexer.Operator::precedence(info)
        if prec < min_bp { break }
        ignore(P::advance(p))
        let next_min = if @lexer.Operator::is_right_associative(info) { prec } else { prec + 1 }
        let rhs = parse_bp(p, next_min)
        lhs = Expr::Binary(op, lhs, rhs)
        continue
      }
      None => break
    }
  }
  lhs
}

// 顶层入口：词法切分 + Pratt 解析
pub fn parse(src: String) -> Expr {
  let res = (try? @lexer.Lexer::tokenize(@lexer.Lexer::new(source=src)))
  let toks = match res { Ok(arr) => arr; Err(_) => [] }
  parse_bp(P::new(ts=toks), 0)
}

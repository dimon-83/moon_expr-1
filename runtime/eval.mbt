// 求值器：在 Env 上对 AST 进行解释执行
// 设计思路：
// - 标量字面量与标识符直接映射到 Value
// - 一元/二元按操作符表进行分派，包含布尔短路、空值合并、范围与集合判断
// - 函数调用通过 Env 的注册中心查找 Builtin 并执行具体实现
// 使用示例：
// - 算术：eval(parse("(a+b)-c"), Env::from_map({...}))
// - 字符串：eval(parse("contains(name, \"bc\")"), Env::from_map({...}))
pub fn eval(expr: @parser.Expr, env: Env) -> Value {
  match expr {
    @parser.Expr::IntLit(v) => Value::Int(v)
    @parser.Expr::DoubleLit(v) => Value::Float(v)
    @parser.Expr::BoolLit(v) => Value::Bool(v)
    @parser.Expr::StrLit(v) => Value::Str(v)
    @parser.Expr::NullLit => Value::Null
    @parser.Expr::Ident(name) => env.get(name)
    @parser.Expr::Unary(op, e) => {
      // 一元运算：目前支持数值的正负号
      let v = eval(e, env)
      match v {
        Value::Int(x) => if op == "-" { Value::Int(0L - x) } else { Value::Int(x) }
        Value::Float(x) => if op == "-" { Value::Float(0.0 - x) } else { Value::Float(x) }
        _ => Value::Null
      }
    }
    @parser.Expr::Binary(op, l, r) => {
      // 布尔短路：and/or 语义
      if op == "and" || op == "&&" {
        let lv = eval(l, env)
        match lv {
          Value::Bool(b) => if b { let rv = eval(r, env); match rv { Value::Bool(bb) => Value::Bool(bb); _ => Value::Null } } else { Value::Bool(false) }
          _ => Value::Null
        }
      } else if op == "or" || op == "||" {
        let lv = eval(l, env)
        match lv {
          Value::Bool(b) => if b { Value::Bool(true) } else { let rv = eval(r, env); match rv { Value::Bool(bb) => Value::Bool(bb); _ => Value::Null } }
          _ => Value::Null
        }
      } else if op == "??" {
        // 空值合并：左值为 Null 时返回右值，否则返回左值
        let lv = eval(l, env)
        match lv { Value::Null => eval(r, env); _ => lv }
      } else if op == ".." {
        // 范围：[a..b] 生成递增/递减整数数组
        let lv = eval(l, env)
        let rv = eval(r, env)
        match lv {
          Value::Int(a) => match rv { Value::Int(b) => {
            let arr : Array[Value] = []
            if a <= b { let mut i = a; for { if i > b { break } ; arr.push(Value::Int(i)); i = i + 1L } } else { let mut i = a; for { if i < b { break } ; arr.push(Value::Int(i)); i = i - 1L } }
            Value::Array(arr)
          }; _ => Value::Null }
          _ => Value::Null
        }
      } else if op == "in" {
        // 集合成员判断：目前支持数组
        let lv = eval(l, env)
        let rv = eval(r, env)
        match rv {
          Value::Array(a) => {
            let mut found = false
            for x in a { if x == lv { found = true; break } }
            Value::Bool(found)
          }
          _ => Value::Null
        }
      } else if op == "contains" || op == "startsWith" || op == "endsWith" {
        // 字符串关系：包含/前缀/后缀
        let lv = eval(l, env)
        let rv = eval(r, env)
        match lv {
          Value::Str(s) => match rv { Value::Str(t) => match op {
            "contains" => Value::Bool(str_contains(s, t))
            "startsWith" => Value::Bool(str_starts_with(s, t))
            "endsWith" => Value::Bool(str_ends_with(s, t))
            _ => Value::Null
          }; _ => Value::Null }
          _ => Value::Null
        }
      } else {
        // 常规算术与比较/等值分派
        let lv = eval(l, env)
        let rv = eval(r, env)
        match (lv, rv) {
          (Value::Int(a), Value::Int(b)) => match op {
            "+" => Value::Int(a + b)
            "-" => Value::Int(a - b)
            "*" => Value::Int(a * b)
            "/" => if b == 0L { Value::Null } else { Value::Float(a.to_double() / b.to_double()) }
            "%" => if b == 0L { Value::Null } else { Value::Int(a % b) }
            "**" | "^" => Value::Int(int_pow(a, b))
            "<" => Value::Bool(a < b)
            ">" => Value::Bool(a > b)
            "<=" => Value::Bool(a <= b)
            ">=" => Value::Bool(a >= b)
            "==" => Value::Bool(a == b)
            "!=" => Value::Bool(a != b)
            _ => Value::Null
          }
          (Value::Float(a), Value::Float(b)) => match op {
            "+" => Value::Float(a + b)
            "-" => Value::Float(a - b)
            "*" => Value::Float(a * b)
            "/" => Value::Float(a / b)
            "<" => Value::Bool(a < b)
            ">" => Value::Bool(a > b)
            "<=" => Value::Bool(a <= b)
            ">=" => Value::Bool(a >= b)
            "==" => Value::Bool(a == b)
            "!=" => Value::Bool(a != b)
            _ => Value::Null
          }
          (Value::Int(a), Value::Float(b)) => match op {
            "+" => Value::Float(a.to_double() + b)
            "-" => Value::Float(a.to_double() - b)
            "*" => Value::Float(a.to_double() * b)
            "/" => Value::Float(a.to_double() / b)
            "<" => Value::Bool(a.to_double() < b)
            ">" => Value::Bool(a.to_double() > b)
            "<=" => Value::Bool(a.to_double() <= b)
            ">=" => Value::Bool(a.to_double() >= b)
            "==" => Value::Bool(a.to_double() == b)
            "!=" => Value::Bool(a.to_double() != b)
            _ => Value::Null
          }
          (Value::Float(a), Value::Int(b)) => match op {
            "+" => Value::Float(a + b.to_double())
            "-" => Value::Float(a - b.to_double())
            "*" => Value::Float(a * b.to_double())
            "/" => Value::Float(a / b.to_double())
            "<" => Value::Bool(a < b.to_double())
            ">" => Value::Bool(a > b.to_double())
            "<=" => Value::Bool(a <= b.to_double())
            ">=" => Value::Bool(a >= b.to_double())
            "==" => Value::Bool(a == b.to_double())
            "!=" => Value::Bool(a != b.to_double())
            _ => Value::Null
          }
          (Value::Str(sa), Value::Str(sb)) => match op {
            "+" => Value::Str(sa + sb)
            "==" => Value::Bool(sa == sb)
            "!=" => Value::Bool(sa != sb)
            _ => Value::Null
          }
          (Value::Bool(ba), Value::Bool(bb)) => match op {
            "==" => Value::Bool(ba == bb)
            "!=" => Value::Bool(ba != bb)
            _ => Value::Null
          }
          _ => Value::Null
        }
      }
    }
    @parser.Expr::Grouping(e) => eval(e, env)
    @parser.Expr::Call(name, args) => {
      // 函数调用：先求值参数，再基于 Env 的注册中心进行查找
      let arg_values : Array[Value] = []
      let arg_types : Array[Type] = []
      for arg in args {
        let val = eval(arg, env)
        arg_values.push(val)
        arg_types.push(val.get_type())
      }
      match Env::find_builtin(env, name, arg_types) {
        Some(spec) => (spec.body)(arg_values)
        None => Value::Null
      }
    }
  }
}



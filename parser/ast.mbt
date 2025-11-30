// 抽象语法树（AST）节点定义
// 设计思路：
// - 使用代数数据类型表达表达式的结构，覆盖字面量、标识符、
//   一元/二元运算、分组与函数调用
// 使用示例：
// - 由解析器生成：let e = @parser.parse("(1+2)-3")
// - 文本化输出：e.to_string() -> "((1 + 2) - 3)"
pub(all) enum Expr {
  IntLit(Int64)
  DoubleLit(Double)
  BoolLit(Bool)
  StrLit(String)
  NullLit
  Ident(String)
  Unary(String, Expr)
  Binary(String, Expr, Expr)
  Grouping(Expr)
  Call(String, Array[Expr])
} derive(Show,Eq)

// 访问者模式接口
// 注意：由于 Trait 泛型支持限制，采用副作用模式（返回 Unit），结果需存储在 Visitor 内部
pub(open) trait Visitor {
  visit_int_lit(Self, Int64) -> Unit
  visit_double_lit(Self, Double) -> Unit
  visit_bool_lit(Self, Bool) -> Unit
  visit_str_lit(Self, String) -> Unit
  visit_null_lit(Self) -> Unit
  visit_ident(Self, String) -> Unit
  visit_unary(Self, String, Expr) -> Unit
  visit_binary(Self, String, Expr, Expr) -> Unit
  visit_grouping(Self, Expr) -> Unit
  visit_call(Self, String, Array[Expr]) -> Unit
}

// 接收访问者
pub fn [V: Visitor] Expr::accept(self: Expr, visitor: V) -> Unit {
  match self {
    IntLit(i) => visitor.visit_int_lit(i)
    DoubleLit(d) => visitor.visit_double_lit(d)
    BoolLit(b) => visitor.visit_bool_lit(b)
    StrLit(s) => visitor.visit_str_lit(s)
    NullLit => visitor.visit_null_lit()
    Ident(name) => visitor.visit_ident(name)
    Unary(op, expr) => visitor.visit_unary(op, expr)
    Binary(op, left, right) => visitor.visit_binary(op, left, right)
    Grouping(expr) => visitor.visit_grouping(expr)
    Call(name, args) => visitor.visit_call(name, args)
  }
}

// AST 文本化：用于调试与测试断言
pub fn Expr::to_string(self: Expr) -> String {
  match self {
    IntLit(v) => v.to_string()
    DoubleLit(v) => v.to_string()
    BoolLit(v) => v.to_string()
    StrLit(v) => v
    NullLit => "null"
    Ident(s) => s
    Unary(op, e) => op + "(" + e.to_string() + ")"
    Binary(op, l, r) => "(" + l.to_string() + " " + op + " " + r.to_string() + ")"
    Grouping(e) => e.to_string()
    Call(name, _args) => name
  }
}

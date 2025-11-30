// 核心模块：表达式 API
// 设计思路：
// - 将输入字符串通过解析器转为 AST（Program.expr）
// - 在运行时环境 Env 中进行求值，可选传入函数注册中心（FnRegistry）
// - 提供便捷接口 eval_str 以一行完成编译与求值
// 使用示例：
// - 算术：@api.eval_str("(a+b)-c", { "a": @runtime.Value::Int(2L), "b": @runtime.Value::Int(3L), "c": @runtime.Value::Int(1L) })
// - 字符串：@api.eval_str("len(name)", { "name": @runtime.Value::Str("abc") })
// - 传入自定义注册中心：@api.eval_str("len(name)", { "name": @runtime.Value::Str("abc") }, registry=myRegistry)
pub struct Program {
  expr: @parser.Expr
}

// 编译：将表达式字符串解析为 AST
pub fn compile(expression~: String) -> Program {
  let e = @parser.parse(expression)
  Program::{ expr: e }
}

// 求值：在指定变量表与可选函数注册中心下，对 Program.expr 进行求值
pub fn Program::evaluate(self: Program, variables: Map[String, @runtime.Value], registry?: @runtime.FnRegistry) -> @runtime.Value {
  let env = match registry { Some(r) => @runtime.Env::from_map_with(variables, r); None => @runtime.Env::from_map(variables) }
  @runtime.eval(self.expr, env)
}

// 便捷：直接对表达式字符串进行编译与求值，等价于 compile + evaluate
pub fn eval_str(expression: String, variables: Map[String, @runtime.Value], registry?: @runtime.FnRegistry) -> @runtime.Value {
  let p = compile(expression=expression)
  match registry { Some(r) => p.evaluate(variables, registry=r); None => p.evaluate(variables) }
}

// 获取包含内置函数的默认注册中心
pub fn default_registry() -> @runtime.FnRegistry {
  @runtime.builtin_registry()
}

// 注册自定义函数到指定注册中心
// - implementation: 接收 Value 数组，返回 Value 的闭包
pub fn register_function(registry: @runtime.FnRegistry, name: String, arity: Int, implementation: (Array[@runtime.Value]) -> @runtime.Value) -> Unit {
  let param_types = Array::make(arity, @runtime.Type::Any)
  registry.register(@runtime.FnSpec::new(
    name,
    param_types,
    @runtime.Type::Any,
    false, // 默认为非纯函数
    false, // 默认为不可并行
    implementation
  ))
}

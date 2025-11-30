// 运行时值系统与环境
// 设计思路：
// - 使用代数数据类型 Value 表示可求值的值域（整数、布尔、字符串、空、数组、Map）
// - Env 封装变量表与函数注册中心（FnRegistry），负责标识符查找与内置函数查询
// 使用示例：
// - 构造环境：let env = Env::from_map({ "x": Value::Int(7L) })
// - 查找变量：env.get("x") -> Value::Int(7)
// - 查询内置：Env::find_builtin(env, "len", 1)
pub(all) enum Value {
  Int(Int64)
  Float(Double)
  Bool(Bool)
  Str(String)
  Null
  Array(Array[Value])
  Map(Map[String, Value])
} derive(Show,Eq)

pub(all) enum Type {
  Int
  Float
  Bool
  Str
  Null
  Array
  Map
  Any // 用于通配符
} derive(Show, Eq)

pub fn Value::get_type(self: Value) -> Type {
  match self {
    Value::Int(_) => Type::Int
    Value::Float(_) => Type::Float
    Value::Bool(_) => Type::Bool
    Value::Str(_) => Type::Str
    Value::Null => Type::Null
    Value::Array(_) => Type::Array
    Value::Map(_) => Type::Map
  }
}

// 求值环境：变量表 + 函数注册中心快照
pub struct Env {
  vars: Map[String, Value]
  funcs: FnRegistry
}

// 默认环境：无变量，内置函数注册中心
pub fn Env::new() -> Env { Env::{ vars: {}, funcs: builtin_registry() } }
// 从变量表构造环境：附带默认内置函数注册中心
pub fn Env::from_map(vars: Map[String, Value]) -> Env { Env::{ vars, funcs: builtin_registry() } }
// 使用自定义注册中心构造环境：用于扩展内置或注册用户函数
pub fn Env::from_map_with(vars: Map[String, Value], funcs: FnRegistry) -> Env { Env::{ vars, funcs } }
// 标识符查找：不存在返回 Null
pub fn Env::get(self: Env, name: String) -> Value { match self.vars.get(name) { Some(v) => v; None => Value::Null } }
// 内置函数查询：按名称与参数类型匹配
pub fn Env::find_builtin(self: Env, name: String, arg_types: Array[Type]) -> FnSpec? { FnRegistry::find(self.funcs, name, arg_types) }

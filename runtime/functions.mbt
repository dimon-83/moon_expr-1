// 函数注册中心与函数规范
// 设计思路：
// - FnSpec 描述函数签名与实现，支持纯度标记与自定义实现
// - FnRegistry 存储 name -> [FnSpec] 重载列表
// - 统一管理内置函数与用户自定义函数

pub struct FnSpec {
  name: String
  arity: Int
  param_types: Array[Type]
  returns: Type
  is_pure: Bool
  can_parallelize: Bool
  body: (Array[Value]) -> Value
}

pub fn FnSpec::new(
  name: String, 
  param_types: Array[Type], 
  returns: Type, 
  is_pure: Bool, 
  can_parallelize: Bool,
  body: (Array[Value]) -> Value
) -> FnSpec {
  FnSpec::{ 
    name, 
    arity: param_types.length(), 
    param_types, 
    returns, 
    is_pure, 
    can_parallelize, 
    body 
  }
}

pub struct FnRegistry { table: Map[String, Array[FnSpec]] }

pub fn FnRegistry::new() -> FnRegistry { FnRegistry::{ table: {} } }

// 注册函数：支持重载
pub fn FnRegistry::register(self: FnRegistry, spec: FnSpec) -> Unit {
  match self.table.get(spec.name) {
    Some(arr) => arr.push(spec)
    None => self.table.set(spec.name, [spec])
  }
}

// 查找函数重载：按名称与参数类型匹配
pub fn FnRegistry::find(self: FnRegistry, name: String, args: Array[Type]) -> FnSpec? {
  match self.table.get(name) {
    Some(candidates) => {
      let mut best_spec : FnSpec? = None
      let mut best_score = -1
      
      for spec in candidates {
        if spec.arity != args.length() { continue }
        
        let mut score = 0
        let mut match_failed = false
        
        for i = 0; i < spec.arity; i = i + 1 {
          let expected = spec.param_types[i]
          let actual = args[i]
          
          if expected == Type::Any {
            score = score + 1
          } else if expected == actual {
            score = score + 2
          } else {
            match_failed = true
            break
          }
        }
        
        if not(match_failed) && score > best_score {
          best_score = score
          best_spec = Some(spec)
        }
      }
      best_spec
    }
    None => None
  }
}

// 内置函数实现
fn impl_len(args: Array[Value]) -> Value {
  match args[0] {
    Value::Str(s) => Value::Int(s.length().to_int64())
    Value::Array(a) => Value::Int(a.length().to_int64())
    Value::Map(m) => Value::Int(m.length().to_int64())
    _ => Value::Null
  }
}

fn impl_contains(args: Array[Value]) -> Value {
  match args[0] {
    Value::Str(s) => match args[1] {
      Value::Str(sub) => Value::Bool(str_contains(s, sub))
      _ => Value::Null
    }
    _ => Value::Null
  }
}

fn impl_startsWith(args: Array[Value]) -> Value {
  match args[0] {
    Value::Str(s) => match args[1] {
      Value::Str(pre) => Value::Bool(str_starts_with(s, pre))
      _ => Value::Null
    }
    _ => Value::Null
  }
}

fn impl_endsWith(args: Array[Value]) -> Value {
  match args[0] {
    Value::Str(s) => match args[1] {
      Value::Str(suf) => Value::Bool(str_ends_with(s, suf))
      _ => Value::Null
    }
    _ => Value::Null
  }
}

fn impl_abs(args: Array[Value]) -> Value {
  match args[0] {
    Value::Int(i) => Value::Int(if i < 0L { -i } else { i })
    Value::Float(f) => Value::Float(if f < 0.0 { -f } else { f })
    _ => Value::Null
  }
}

fn impl_pow(args: Array[Value]) -> Value {
  match args[0] {
    Value::Int(a) => match args[1] {
      Value::Int(b) => Value::Int(int_pow(a, b))
      _ => Value::Null
    }
    _ => Value::Null
  }
}

fn impl_min(args: Array[Value]) -> Value {
  match args[0] {
    Value::Int(a) => match args[1] {
      Value::Int(b) => Value::Int(if a < b { a } else { b })
      _ => Value::Null
    }
    Value::Float(a) => match args[1] {
      Value::Float(b) => Value::Float(if a < b { a } else { b })
      _ => Value::Null
    }
    _ => Value::Null
  }
}

fn impl_max(args: Array[Value]) -> Value {
  match args[0] {
    Value::Int(a) => match args[1] {
      Value::Int(b) => Value::Int(if a > b { a } else { b })
      _ => Value::Null
    }
    Value::Float(a) => match args[1] {
      Value::Float(b) => Value::Float(if a > b { a } else { b })
      _ => Value::Null
    }
    _ => Value::Null
  }
}

fn impl_upper(args: Array[Value]) -> Value {
  match args[0] {
    Value::Str(s) => Value::Str(s.to_upper())
    _ => Value::Null
  }
}

fn impl_lower(args: Array[Value]) -> Value {
  match args[0] {
    Value::Str(s) => Value::Str(s.to_lower())
    _ => Value::Null
  }
}

fn impl_sum(args: Array[Value]) -> Value {
  match args[0] {
    Value::Array(arr) => {
      let mut sum_i = 0L
      let mut sum_f = 0.0
      let mut is_float = false
      
      for v in arr {
        match v {
          Value::Int(i) => {
            if is_float { sum_f = sum_f + i.to_double() }
            else { sum_i = sum_i + i }
          }
          Value::Float(f) => {
            if not(is_float) {
              sum_f = sum_i.to_double() + f
              is_float = true
            } else {
              sum_f = sum_f + f
            }
          }
          _ => () // Ignore non-numbers? Or error?
        }
      }
      
      if is_float { Value::Float(sum_f) } else { Value::Int(sum_i) }
    }
    _ => Value::Null
  }
}

fn impl_avg(args: Array[Value]) -> Value {
  match args[0] {
    Value::Array(arr) => {
      if arr.length() == 0 { return Value::Float(0.0) }
      let mut sum = 0.0
      for v in arr {
        match v {
          Value::Int(i) => sum = sum + i.to_double()
          Value::Float(f) => sum = sum + f
          _ => ()
        }
      }
      Value::Float(sum / arr.length().to_double())
    }
    _ => Value::Null
  }
}

// 默认内置注册中心
pub fn builtin_registry() -> FnRegistry {
  let reg = FnRegistry::new()
  
  reg.register(FnSpec::new("len", [Type::Any], Type::Int, true, true, impl_len))
  reg.register(FnSpec::new("contains", [Type::Str, Type::Str], Type::Bool, true, true, impl_contains))
  reg.register(FnSpec::new("startsWith", [Type::Str, Type::Str], Type::Bool, true, true, impl_startsWith))
  reg.register(FnSpec::new("endsWith", [Type::Str, Type::Str], Type::Bool, true, true, impl_endsWith))
  
  // Math
  reg.register(FnSpec::new("abs", [Type::Int], Type::Int, true, true, impl_abs))
  reg.register(FnSpec::new("abs", [Type::Float], Type::Float, true, true, impl_abs))
  
  reg.register(FnSpec::new("pow", [Type::Int, Type::Int], Type::Int, true, true, impl_pow))
  // reg.register(FnSpec::new("pow", [Type::Float, Type::Float], Type::Float, true, true, impl_pow)) // TODO: float pow

  reg.register(FnSpec::new("min", [Type::Int, Type::Int], Type::Int, true, true, impl_min))
  reg.register(FnSpec::new("min", [Type::Float, Type::Float], Type::Float, true, true, impl_min))
  
  reg.register(FnSpec::new("max", [Type::Int, Type::Int], Type::Int, true, true, impl_max))
  reg.register(FnSpec::new("max", [Type::Float, Type::Float], Type::Float, true, true, impl_max))

  // String
  reg.register(FnSpec::new("upper", [Type::Str], Type::Str, true, true, impl_upper))
  reg.register(FnSpec::new("lower", [Type::Str], Type::Str, true, true, impl_lower))

  // Collection
  reg.register(FnSpec::new("sum", [Type::Array], Type::Any, true, true, impl_sum))
  reg.register(FnSpec::new("avg", [Type::Array], Type::Float, true, true, impl_avg))

  reg
}

// 桥接代码：暴露给 JS 调用的接口

// Wasm 兼容接口：字符逐个传递 (Char-by-Char FFI)
// 避免直接处理内存指针和字符串布局

let input_buffer_ref : Ref[StringBuilder] = Ref::new(StringBuilder::new())
let output_str_ref : Ref[String] = Ref::new("") // 最终输出字符串

pub fn clear_input() -> Unit {
  input_buffer_ref.val = StringBuilder::new()
}

pub fn append_char(c : Int) -> Unit {
  input_buffer_ref.val.write_char(c.unsafe_to_char())
}

pub fn get_output_len() -> Int {
  output_str_ref.val.length()
}

pub fn get_output_char(index : Int) -> Int {
  let s = output_str_ref.val
  if index >= 0 && index < s.length() {
    let c = s[index]
    // s[index] 返回 Int (code point)，直接返回即可
    c
  } else {
    0
  }
}

// 1. 解析变量 (Wasm Wrapper)
pub fn parse_vars_wasm() -> Int {
  let expr = input_buffer_ref.val.to_string()
  let res = parse_vars(expr)
  output_str_ref.val = res
  output_str_ref.val.length()
}

// 2. 计算表达式 (Wasm Wrapper)
// 由于 JSON 输入较长，我们复用 input_buffer
// 约定格式：expr + "\0" + names_json + "\0" + values_json
// 或者更简单：分三次设置？
// 为了简单，我们定义三个 buffer? 或者复用一个，用分隔符。
// 简单起见，我们假定 input_buffer 包含所有内容，用特殊字符分隔?
// 不，JSON 中可能包含任何字符。
// 更好的方式：增加 API `set_mode(0/1/2)` 来分别填充 expr, names, values?
// 或者：`append_char_to_expr`, `append_char_to_names`, ...

let expr_buffer : Ref[StringBuilder] = Ref::new(StringBuilder::new())
let names_buffer : Ref[StringBuilder] = Ref::new(StringBuilder::new())
let values_buffer : Ref[StringBuilder] = Ref::new(StringBuilder::new())

pub fn clear_buffers() -> Unit {
  expr_buffer.val = StringBuilder::new()
  names_buffer.val = StringBuilder::new()
  values_buffer.val = StringBuilder::new()
}

pub fn append_expr_char(c : Int) -> Unit {
  expr_buffer.val.write_char(c.unsafe_to_char())
}

pub fn append_names_char(c : Int) -> Unit {
  names_buffer.val.write_char(c.unsafe_to_char())
}

pub fn append_values_char(c : Int) -> Unit {
  values_buffer.val.write_char(c.unsafe_to_char())
}

pub fn evaluate_wasm() -> Int {
  let expr = expr_buffer.val.to_string()
  let names = names_buffer.val.to_string()
  let values = values_buffer.val.to_string()
  
  let res = evaluate_expr_json(expr, names, values)
  output_str_ref.val = res
  output_str_ref.val.length()
}

// 原始逻辑保持不变
// 1. 解析变量
fn parse_vars(expr: String) -> String {
  let prog = @api.compile(expression=expr)
  let vars = prog.get_variables()
  
  let buf = StringBuilder::new()
  buf.write_string("[")
  for i = 0; i < vars.length(); i = i + 1 {
    if i > 0 { buf.write_string(",") }
    buf.write_string("\"")
    buf.write_string(vars[i])
    buf.write_string("\"")
  }
  buf.write_string("]")
  buf.to_string()
}

// 内部使用的计算逻辑
fn evaluate_expr_internal(expr: String, names: Array[String], values: Array[String]) -> String {
  let prog = @api.compile(expression=expr)
  
  let context : Map[String, @runtime.Value] = {}
  for i = 0; i < names.length(); i = i + 1 {
    let name = names[i]
    let val_str = values[i]
    
    if val_str == "true" {
      context[name] = @runtime.Value::Bool(true)
    } else if val_str == "false" {
      context[name] = @runtime.Value::Bool(false)
    } else if val_str.contains("\"") {
      context[name] = @runtime.Value::Str(val_str.replace_all(old="\"", new=""))
    } else {
       try {
         if val_str.contains(".") {
           let f = @strconv.parse_double(val_str)
           context[name] = @runtime.Value::Float(f)
         } else {
           let l = @strconv.parse_int64(val_str)
           context[name] = @runtime.Value::Int(l)
         }
       } catch {
         _ => context[name] = @runtime.Value::Null
       }
    }
  }
  
  let res = prog.evaluate(context)
  match res {
    Int(i) => "Type: Integer, Value: " + i.to_string()
    Float(f) => "Type: Float, Value: " + f.to_string()
    Bool(b) => "Type: Boolean, Value: " + b.to_string()
    Str(s) => "Type: String, Value: " + s
    Null => "Type: Null, Value: null"
    _ => res.to_string()
  }
}

fn parse_simple_json_array(s: String) -> Array[String] {
  let res = []
  let content = s.trim(chars=" []\t\n\r") // Remove brackets and whitespace
  if content == "" { return res }
  
  let iter = content.split(",")
  for part in iter {
    let p_view = part.trim(chars=" \t\n\r")
    let p = p_view.to_string()
    
    if p.has_prefix("\"") && p.has_suffix("\"") {
      if p.length() >= 2 {
         try {
           res.push(p[1:p.length()-1].to_string())
         } catch {
            _ => res.push("")
         }
      } else {
         res.push("")
      }
    } else {
       res.push(p)
    }
  }
  res
}

// 2. 计算表达式 (JSON Wrapper)
fn evaluate_expr_json(expr: String, names_json: String, values_json: String) -> String {
  let names = parse_simple_json_array(names_json)
  let values = parse_simple_json_array(values_json)
  evaluate_expr_internal(expr, names, values)
}

fn main {
  println("MoonExpr Playground Wasm Loaded")
}

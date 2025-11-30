# MoonExpr

MoonExpr 是一个使用 MoonBit 语言编写的高性能、可扩展的数学与逻辑表达式求值引擎。

## 特性

- **丰富的运算符支持**：算术 (`+`, `-`, `*`, `/`, `%`, `**`)、逻辑 (`and`, `or`, `!`)、比较 (`>`, `<`, `==`, `!=` 等)。
- **混合类型运算**：支持整数与浮点数的自动类型提升与混合运算。
- **函数系统**：
  - 内置丰富的数学 (`sin`, `cos`, `abs`...) 和字符串 (`len`, `trim`...) 函数。
  - 支持**函数重载**，根据参数类型自动匹配实现。
  - 支持**自定义函数**注册。
- **架构设计**：
  - 采用 Pratt Parser 处理复杂的运算符优先级。
  - 实现 Visitor 模式，便于扩展 AST 处理逻辑。
  - 模块化设计：Parser, Runtime, API 分层清晰。

## 快速开始

### 安装

在 `moon.mod.json` 中添加依赖：

```json
{
  "deps": {
    "sombozone/moon_expr": "0.1.0"
  }
}
```

### 使用示例

```moonbit
import sombozone/moon_expr/api
import sombozone/moon_expr/runtime

fn main {
  // 1. 简单求值
  let result = api.eval_str("1 + 2 * 3")
  println(result) // Output: Int(7)

  // 2. 带变量求值
  let prog = api.compile(expression="a * b + 5")
  let context = { 
    "a": runtime.Value::Int(10L), 
    "b": runtime.Value::Int(2L) 
  }
  let res = prog.evaluate(context)
  println(res) // Output: Int(25)
  
  // 3. 复杂逻辑与函数
  let logic = api.eval_str("max(10, 20) > 15 and (true or false)")
  println(logic) // Output: Bool(true)
}
```

## 文档

- [架构设计文档 (ARCHITECTURE.md)](./ARCHITECTURE.md): 详细解析实现思路、组件关系及设计决策。

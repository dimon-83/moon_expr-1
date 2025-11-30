# MoonExpr 架构设计文档

本文档详细解析 MoonExpr 表达式引擎的实现思路、组件关系及设计决策。

## 1. 架构总览

MoonExpr 采用经典的解释器架构，主要分为 **前端 (Frontend)** 和 **后端 (Backend)** 两大部分。

- **前端**：负责将源代码文本转换为计算机可理解的结构化数据（AST）。
- **后端**：负责对 AST 进行遍历求值，管理运行时状态和函数调用。

### 数据流图

```mermaid
graph TD
    Source[源代码字符串] --> Lexer[词法分析器 (Lexer)]
    Lexer -->|Token 流| Parser[语法分析器 (Parser)]
    Parser -->|抽象语法树 (AST)| Evaluator[求值器 (Evaluator)]
    
    subgraph Runtime [运行时环境]
        Evaluator <--> Env[变量环境 (Environment)]
        Evaluator <--> FnRegistry[函数注册中心 (FnRegistry)]
    end
    
    Evaluator --> Result[计算结果 (Value)]
```

## 2. 组件详解

### 2.1 词法分析 (Parser/Lexer)

**目录**: `parser/lexer`

词法分析器的主要职责是将原始字符串转换为 Token 序列。

- **实现思路**：
  - 采用手写状态机，逐字符扫描。
  - 支持跳过空白字符。
  - 识别标识符（`[a-zA-Z_][a-zA-Z0-9_]*`）、数字（整数和浮点数）、字符串字面量（支持转义）、操作符和标点符号。
- **关键特性**：
  - **Lookahead**：通过预读字符处理多字符操作符（如 `==`, `!=`, `<=`, `>=`）。
  - **Unicode 支持**：底层处理 Unicode 字符，确保多语言兼容性。

### 2.2 语法分析 (Parser)

**目录**: `parser`

语法分析器将 Token 流转换为抽象语法树 (AST)。

- **AST 结构 (`ast.mbt`)**：
  - 使用枚举 (`enum Expr`) 定义节点类型，涵盖字面量、一元/二元运算、函数调用、变量引用等。
  - **Visitor 模式**：实现了 `Visitor` trait 和 `Expr::accept` 方法。
    - **目的**：解耦 AST 结构与操作逻辑（如打印、校验、编译），符合开闭原则。
    - **实现**：由于 MoonBit 泛型限制，Visitor 采用副作用模式（返回 Unit），状态通过 Visitor 结构体内部维护。

- **解析算法 (`parser.mbt`)**：
  - **Pratt Parser (Top-Down Operator Precedence Parsing)**：
    - **选择理由**：Pratt Parser 非常适合处理表达式语言，能够优雅地处理复杂的运算符优先级和结合性，代码结构比递归下降更扁平。
    - **机制**：为每个 Token 定义 `prefix` (前缀) 和 `infix` (中缀) 解析函数，以及 `binding_power` (绑定权值) 来控制结合顺序。

### 2.3 运行时值系统 (Runtime/Value)

**目录**: `runtime`

- **Value 类型 (`value.mbt`)**：
  - 使用枚举 `Value` 统一表示所有运行时数据。
  - 支持 `Int`, `Float`, `Bool`, `String`, `Null` 等基础类型。
  - 提供了 `to_string`, `to_int`, `to_double` 等辅助转换方法。

- **环境 (`runtime/eval.mbt`)**：
  - `Map[String, Value]` 用于存储变量名到值的映射。
  - 求值时传入环境，支持变量查找。

### 2.4 函数系统 (Runtime/Functions)

**目录**: `runtime/functions.mbt`

MoonExpr 拥有强大的函数扩展能力。

- **函数注册中心 (`FnRegistry`)**：
  - 集中管理所有可用函数。
  - **重载支持**：`FnSpec` 包含参数类型签名 (`args_type`)。调用时根据参数数量和类型匹配最合适的函数实现。
  - **内置函数**：预置了数学 (`sin`, `cos`, `max` 等)、字符串 (`len`, `trim` 等) 和集合操作函数。
- **扩展性**：用户可以通过 API 注册自定义函数，无缝扩展引擎能力。

### 2.5 求值器 (Evaluator)

**目录**: `runtime/eval.mbt`

求值器遍历 AST 并计算最终结果。

- **实现细节**：
  - 递归遍历 AST 节点。
  - **类型自动提升**：在数值运算中，如果遇到 Float，会将 Int 自动提升为 Float 进行计算（如 `1 + 2.5` 结果为 `3.5`）。
  - **除法修正**：整数除法自动转换为浮点除法（如 `21/2` 结果为 `10.5`），符合通常的计算器直觉。
  - **短路求值**：逻辑运算 `and` 和 `or` 实现了短路逻辑，避免不必要的计算和潜在的副作用。

## 3. 目录结构说明

```text
sombozone/moon_expr
├── api/            # 公共 API 接口，对外暴露 compile/evaluate 等方法
├── examples/       # 示例代码和集成测试
├── parser/         # 语法解析模块
│   ├── lexer/      # 词法分析
│   ├── ast.mbt     # AST 定义与 Visitor 接口
│   └── parser.mbt  # Pratt Parser 实现
├── runtime/        # 运行时模块
│   ├── eval.mbt    # 求值逻辑
│   ├── value.mbt   # 值类型定义
│   └── functions.mbt # 函数注册与内置函数库
└── moon.mod.json   # 项目配置文件
```

## 4. 设计决策总结

1.  **Pratt Parser vs 递归下降**：
    - 选择了 Pratt Parser，因为它在处理二元运算符优先级时极其简洁，避免了层层嵌套的函数调用（如 `expr -> term -> factor`），易于维护和扩展新运算符。

2.  **Visitor 模式的引入**：
    - 虽然 MoonBit 支持模式匹配，但在 AST 节点变多且操作复杂（打印、序列化、静态分析）时，Visitor 模式能将操作逻辑分散到独立文件，保持 AST 定义文件的纯净。

3.  **类型处理策略**：
    - 采用 **动态强类型 + 隐式转换**。
    - 算术运算时，尽量兼容 Int 和 Float 混合运算（提升为 Float）。
    - 比较运算严格检查类型（除数字比较外）。

4.  **函数重载**：
    - 为了支持类似 `max(1, 2)` 和 `max(1.5, 2.5)` 的多态行为，引入了基于参数类型的重载机制，这比单一函数名映射更灵活。

## 5. 未来扩展方向

- **性能优化**：引入字节码编译和虚拟机 (VM)，替代当前的树遍历求值 (Tree-walking Interpreter)。
- **类型检查**：在求值前增加静态类型检查阶段。
- **宏系统**：支持用户定义宏。

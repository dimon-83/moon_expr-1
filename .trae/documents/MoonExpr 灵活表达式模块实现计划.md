## 目标与范围
- 在表达式模块中引入统一的函数定义与调用体系：内置函数与用户自定义函数并存，支持重载、类型检查、并发安全。
- 维持既定性能目标（<100ms 典型表达式）与高并发能力。

## 架构总览
- 词法分析（已存在）与语法分析（Pratt Parser）产出 AST。
- 运行时包含：值系统、环境（变量/函数）、求值器、并发控制与缓存。
- 统一函数注册中心（FnRegistry）管理内置/自定义函数及重载解析。

## 词法/语法改动
- 词法：补齐 `Identifier`/`String`/多字符 `Operator`（参考 `parser/lexer/transition.mbt:11`、`lexer.mbt:130-140`）。
- 语法：新增函数调用语法节点
  - 识别 `Ident '(' args ')'` 为 `Call(name, args)`。
  - 支持命名空间（可选）：`ns.func(a, b)` 保持 `Ident` 组合或分词策略。
  - 仍使用操作符优先级处理混合表达式（参考 `parser/lexer/operator.mbt:39-133`）。

## AST 结构
- `Literal(Int|Float|Bool|String|Null)`、`Ident`、`Unary(op, expr)`、`Binary(op, left, right)`、`Grouping(expr)`、`Call(name, args)`。
- 用模式匹配处理求值与类型分派。

## 值系统与环境
- `Value`：`Int64`、`Float64`、`Bool`、`String`、`Null`、`Array[Value]`、`Map[String, Value]`。
- `Env`：
  - 变量表 `vars : Map[String, Value]`。
  - 函数注册中心 `funcs : FnRegistry`。
  - 线程安全（并发读），提供不可变快照用于并行求值。

## 统一函数体系
- `FnRegistry`（函数注册中心）
  - 结构：`name -> [FnSpec]`（重载列表）。
  - `FnSpec`：`name`、`param_types : Array[TypeSig]`、`returns : TypeSig`、`is_pure : Bool`、`can_parallelize : Bool`、`impl : (Array[Value]) -> Value raise FunctionError`。
  - 重载解析：按名称+实参数量+类型最优匹配（支持有限的显式/安全转换，如 `Int64 -> Float64`）。
- 内置函数（首批）
  - 数学：`abs(x)`、`pow(x,y)`、`min(a,b)`、`max(a,b)`。
  - 字符串：`len(s)`、`upper(s)`、`lower(s)`、`contains(s, sub)`、`startsWith(s, pre)`、`endsWith(s, suf)`、`matches(s, pattern)`（适配层实现）。
  - 集合：`sum(arr)`、`avg(arr)`、`map(arr, funcName)`（后续扩展）
- 自定义函数
  - API：`register_function(spec: FnSpec) -> Unit`；`register_functions(specs: Array[FnSpec])`。
  - 允许按同名添加多个重载；禁止覆盖已有完全相同签名（可显式 `replace=true`）。
  - 纯度/并行性声明：用户标注 `is_pure` 与 `can_parallelize`，由运行时守护并在并发调度中使用。
- 错误类型
  - `FunctionError`：未知函数、参数数量不匹配、无可用重载、运行时异常。

## 求值器
- 二元/一元节点：遵循优先级与结合律；布尔短路。
- 函数调用：
  - 解析并取 `FnSpec`；进行类型检查与必要转换；调用 `impl`。
  - 对 `is_pure && can_parallelize` 的无副作用调用，允许在并行路径中参与；否则串行。
- 字符串与集合规则：`in`、`..`、空值合并 `??` 等与之前描述一致。

## 并发与性能
- 并行求值策略
  - 仅在纯二元表达式左右子树与纯函数调用上启用；布尔短路与含副作用调用不并行。
  - 工作池大小可配置，默认根据 CPU 核数；提供超时控制与降级序列化。
- 缓存/记忆化
  - 子表达式哈希缓存（基于 AST + 变量快照）；函数调用如标注为纯且参数可序列化，也可缓存。
- 低拷贝与快速路径
  - Lexer 用 `StringView`（`lexer.mbt:176-179`）；Parser 尽量避免重复构造字符串。

## API 设计
- `compile(expression: String) -> Program`（AST + 元信息）。
- `evaluate(program, variables: Map[String, Value], registry?: FnRegistry) -> Value`。
- `eval_str(expression, variables, registry?) -> Value`（便捷）。
- `register_function(spec: FnSpec)` / `register_functions(specs)`（可在模块级或运行时环境上暴露）。

## 测试（TDD）
- Lexer/Parser：标识符、字符串、函数调用与混合表达式。
- Evaluator：
  - 内置函数：正确性与边界（空串/Null/类型不匹配）。
  - 重载与解析：最优匹配与错误路径（未知函数/参数数目错误/重载无解）。
  - 自定义函数：注册/并行/纯度约束（并发一致性）。
- 集成：复杂表达式串接函数与运算；并发压测下正确性。

## 持续集成与版本路线
- CI：`moon build`/`moon test`；未来加入性能基线报警。
- v0.1：Lexer/Parser+基本 AST；
- v0.2：Evaluator+内置函数+API；
- v0.3：重载解析/自定义函数注册/并发与缓存；
- v0.4：高级字符串匹配器（Regex 适配层）与更多集合函数。

## 示例
- 内置：`eval_str("pow(a,2) + abs(b)", { a: 3, b: -4 }) -> 13`
- 自定义注册：
  - `register_function(FnSpec{name:"score", params:[Int64], returns:Int64, is_pure:true, can_parallelize:true, impl: ...})`
  - `eval_str("score(x) >= 90 and startsWith(name, \"x\")", { x: 95, name: "xa" }) -> true`

如确认此更新计划，将按该函数体系落地实现并与解析/求值器集成。
test "benchmark_complex_bool_expr" (b : @bench.T) {
  let expr = "1 < 0 or (99 > 10 and 50 == 5) or (25 <= 1 and 10 >= 10 and 5 > 0.5)"
  
  // 准备上下文（虽然此表达式无变量，但模拟真实场景）
  let context : Map[String, @runtime.Value] = {
      "x": Int(10), 
      "y": Int(20)
  }

  // 1. 基准测试：完整流程（编译 + 求值）
  b.bench(
    fn () {
      let prog = compile(expression=expr)
      let res = prog.evaluate(context)
      b.keep(res)
    },
    name="full_process"
  )

  // 2. 基准测试：仅求值（预编译）
  let pre_compiled = compile(expression=expr)
  b.bench(
    fn () {
      let res = pre_compiled.evaluate(context)
      b.keep(res)
    },
    name="eval_only"
  )

  // 3. 基准测试：仅解析
  b.bench(
    fn () {
      let _ = compile(expression=expr)
      b.keep(1)
    },
    name="parse_only"
  )
}

test "benchmark_vars_expr" (b : @bench.T) {
  let expr = "foo < 0 or (bar > 10 and baz == 5) or (qux <= 1 and quux >= 10 and corge > 0.5)"
  
  let context : Map[String, @runtime.Value] = {
      "foo": Int(10), 
      "bar": Int(20),
      "baz": Int(5),
      "qux": Int(0),
      "quux": Int(20),
      "corge": Float(1.0)
  }

  // 1. 基准测试：完整流程（编译 + 求值）
  b.bench(
    fn () {
      let prog = compile(expression=expr)
      let res = prog.evaluate(context)
      b.keep(res)
    },
    name="vars_full"
  )

  // 2. 基准测试：仅求值（预编译）
  let pre_compiled = compile(expression=expr)
  b.bench(
    fn () {
      let res = pre_compiled.evaluate(context)
      b.keep(res)
    },
    name="vars_eval"
  )

  // 3. 基准测试：仅解析
  b.bench(
    fn () {
      let _ = compile(expression=expr)
      b.keep(1)
    },
    name="vars_parse"
  )
}

# MoonExpr Playground

这是一个基于 WebAssembly (Wasm) 的 MoonExpr 在线演示环境。它展示了如何将 MoonBit 编写的表达式求值引擎编译为 Wasm，并在浏览器中通过 JavaScript 进行交互。

## ✨ 功能特性

*   **实时变量解析**：输入表达式后，自动分析语法树（AST）并提取其中的变量列表。
*   **动态求值**：为提取出的变量提供输入框，支持输入整数、浮点数、布尔值（true/false）或字符串。
*   **类型推断与展示**：计算结果会自动解包并显示具体的类型（Integer, Float, Boolean, String, Null）。
*   **纯前端运行**：所有计算逻辑均在浏览器端的 Wasm 中完成，无需后端服务。

## 🛠️ 构建与运行

### 1. 编译 Wasm

在 `playground` 目录下执行以下命令，将 MoonBit 代码编译为 Wasm 模块：

```bash
moon build --target wasm
```

编译产物位于 `../target/wasm/release/build/playground/playground.wasm`。

### 2. 启动本地服务器

由于浏览器对 Wasm 的安全策略（CORS），不能直接双击打开 `index.html`。需要启动一个简单的 HTTP 服务器。

例如使用 Python：

```bash
# 在 playground 目录的上级目录 (moon_expr 根目录) 运行，
# 这样 index.html 里的相对路径 '../target/...' 才能正确访问
cd ..
python -m http.server 8000
```

### 3. 访问 Playground

打开浏览器访问：[http://localhost:8000/playground/index.html](http://localhost:8000/playground/index.html)

## 📂 文件结构

*   **`bridge.mbt`**: MoonBit 侧的桥接代码。
    *   实现了与 JavaScript 交互的 FFI 接口。
    *   采用 "Char-by-Char" (逐字符) 的通信方式，避免了复杂的内存布局问题，确保 Wasm 与 JS 之间字符串传递的稳定性。
    *   封装了 `parse_vars` 和 `evaluate_expr_json` 等核心逻辑。
*   **`index.html`**: 前端页面。
    *   包含简洁的 UI (Bootstrap 样式)。
    *   内置 Wasm 加载器 (`loadWasm`) 和 JS 侧的 Wrapper 函数。
    *   处理用户输入、调用 Wasm 导出函数、并在 DOM 中更新结果。
*   **`moon.pkg.json`**: 包配置文件。
    *   配置了 `link` 字段，显式导出 Wasm 函数（如 `parse_vars_wasm`, `evaluate_wasm` 等），防止被死代码消除 (DCE) 优化掉。

## 🔧 技术细节：Wasm 交互机制

为了实现高效且稳定的字符串传递，本项目采用了一种**共享缓冲区**的策略：

1.  **Input Buffer**: MoonBit 侧维护一个 `StringBuilder` 作为输入缓冲区。JS 通过 `append_char` 逐个字符写入数据。
2.  **Execution**: JS 调用 `parse_vars_wasm` 或 `evaluate_wasm` 触发计算。
3.  **Output Buffer**: MoonBit 将结果写入输出字符串引用。
4.  **Read Output**: JS 通过 `get_output_char` 逐个读取结果字符。

这种方式虽然比直接内存拷贝略慢，但极大地简化了跨语言调用的复杂性，且完全规避了内存指针偏移带来的潜在 Bug。

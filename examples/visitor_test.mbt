struct AstPrinter {
  buf: StringBuilder
}

fn AstPrinter::new() -> AstPrinter {
  { buf: StringBuilder::new() }
}

impl @parser.Visitor for AstPrinter with visit_int_lit(self, i : Int64) {
  self.buf.write_string(i.to_string())
}

impl @parser.Visitor for AstPrinter with visit_double_lit(self, d : Double) {
  self.buf.write_string(d.to_string())
}

impl @parser.Visitor for AstPrinter with visit_bool_lit(self, b : Bool) {
  self.buf.write_string(b.to_string())
}

impl @parser.Visitor for AstPrinter with visit_str_lit(self, s : String) {
  self.buf.write_string("\"" + s + "\"")
}

impl @parser.Visitor for AstPrinter with visit_null_lit(self) {
  self.buf.write_string("null")
}

impl @parser.Visitor for AstPrinter with visit_ident(self, name : String) {
  self.buf.write_string(name)
}

impl @parser.Visitor for AstPrinter with visit_unary(self, op : String, expr : @parser.Expr) {
  self.buf.write_string(op)
  self.buf.write_string("(")
  expr.accept(self)
  self.buf.write_string(")")
}

impl @parser.Visitor for AstPrinter with visit_binary(self, op : String, left : @parser.Expr, right : @parser.Expr) {
  self.buf.write_string("(")
  left.accept(self)
  self.buf.write_string(" " + op + " ")
  right.accept(self)
  self.buf.write_string(")")
}

impl @parser.Visitor for AstPrinter with visit_grouping(self, expr : @parser.Expr) {
  // self.buf.write_string("(") // Grouping usually implied by structure or printed explicitly
  expr.accept(self)
  // self.buf.write_string(")")
}

impl @parser.Visitor for AstPrinter with visit_call(self, name : String, args : Array[@parser.Expr]) {
  self.buf.write_string(name)
  self.buf.write_string("(")
  for i = 0; i < args.length(); i = i + 1 {
    if i > 0 { self.buf.write_string(", ") }
    args[i].accept(self)
  }
  self.buf.write_string(")")
}

test "visitor_pattern" {
  let p = AstPrinter::new()
  // 1 + 2 * 3
  let expr = @parser.Expr::Binary(
    "+", 
    @parser.Expr::IntLit(1L), 
    @parser.Expr::Binary("*", @parser.Expr::IntLit(2L), @parser.Expr::IntLit(3L))
  )
  
  expr.accept(p)
  inspect(p.buf.to_string(), content="(1 + (2 * 3))")
}

test "visitor_call" {
  let p = AstPrinter::new()
  // min(1, 2)
  let expr = @parser.Expr::Call(
    "min",
    [@parser.Expr::IntLit(1L), @parser.Expr::IntLit(2L)]
  )
  
  expr.accept(p)
  inspect(p.buf.to_string(), content="min(1, 2)")
}

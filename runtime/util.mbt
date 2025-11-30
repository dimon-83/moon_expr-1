
// 幂运算（整数）：简单重复乘法实现
pub fn int_pow(a: Int64, b: Int64) -> Int64 {
  let mut res : Int64 = 1L
  let mut i = 0L
  for {
    if i >= b { break }
    res = res * a
    i = i + 1L
  }
  res
}

// 字符串前缀判断：逐字符比对
pub fn str_starts_with(s: String, pre: String) -> Bool {
  let ls = s.length(); let lp = pre.length()
  if lp > ls { return false }
  let mut i = 0
  for {
    if i >= lp { break }
    let a = s.get_char(i)
    let b = pre.get_char(i)
    match a {
      Some(cs) => {
        match b {
          Some(cp) => { if cs != cp { return false } }
          None => { return false }
        }
      }
      None => { return false }
    }
    i = i + 1
  }
  true
}

// 字符串后缀判断：逐字符比对（从尾部对齐）
pub fn str_ends_with(s: String, suf: String) -> Bool {
  let ls = s.length(); let lp = suf.length()
  if lp > ls { return false }
  let mut j = 0
  for {
    if j >= lp { break }
    let k = ls - lp + j
    let a = s.get_char(k)
    let b = suf.get_char(j)
    match a {
      Some(cs) => {
        match b {
          Some(cp) => { if cs != cp { return false } }
          None => { return false }
        }
      }
      None => { return false }
    }
    j = j + 1
  }
  true
}

// 字符串包含判断：滑动窗口逐字符比对
pub fn str_contains(s: String, sub: String) -> Bool {
  let ls = s.length(); let lp = sub.length()
  if lp == 0 { return true }
  if lp > ls { return false }
  let mut i = 0
  for {
    if i + lp > ls { break }
    let mut ok = true
    let mut j = 0
    for {
      if j >= lp { break }
      let a = s.get_char(i + j)
      let b = sub.get_char(j)
      match a {
        Some(cs) => {
          match b {
            Some(cp) => { if cs != cp { ok = false; break } }
            None => { ok = false; break }
          }
        }
        None => { ok = false; break }
      }
      j = j + 1
    }
    if ok { return true }
    i = i + 1
  }
  false
}

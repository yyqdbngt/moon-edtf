///|
fn main {
  let samples = [
    "1984", "1984-06-15", "1984?", "1984~", "1984%", "19XX", "2004-01-01/2005", "../1984",
    "2004/..", "1984/", "Y10000", "[1667,1668,1670..1672]", "1984-13",
  ]
  println("== parse and normalize ==")
  for i = 0; i < samples.length(); i = i + 1 {
    let s = samples[i]
    try {
      let value = @edtf.parse(s)
      println("\{s} => \{value.to_string()}")
    } catch {
      @edtf.Syntax(code, offset) => println("\{s} !! \{code} @ \{offset}")
      @edtf.Unsupported(code, offset) => println("\{s} !! \{code} @ \{offset}")
    }
  }
  println("== batch diagnostics ==")
  let rows = @edtf.diagnose_batch(["1984?", "1984-02-30", "19XX"])
  for i = 0; i < rows.length(); i = i + 1 {
    let row = rows[i]
    if row.valid {
      println("\{row.input} valid => \{row.normalized}")
    } else {
      println("\{row.input} invalid => \{row.error_code} @ \{row.error_offset}")
    }
  }
}

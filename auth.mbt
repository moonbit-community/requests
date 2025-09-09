///|
/// Authentication support for MoonBit Requests

///|
/// Authentication types
pub enum Auth {
  Basic(String, String) // username, password
} derive(Show, Eq)

///|
/// Create Basic Authentication
pub fn basic_auth(username : String, password : String) -> Auth {
  Auth::Basic(username, password)
}

///|
/// Convert Auth to Authorization header
pub fn Auth::to_header(self : Auth) -> (String, String) {
  match self {
    Basic(username, password) => {
      let credentials = username + ":" + password
      let encoded = base64_encode(credentials)
      ("Authorization", "Basic " + encoded)
    }
  }
}

///|
/// Simple Base64 encoding for Basic Auth
fn base64_encode(input : String) -> String {
  let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  let input_bytes = @encoding.encode(input, encoding=UTF8)
  let buf = StringBuilder::new()
  let mut i = 0
  while i < input_bytes.length() {
    let b1 = input_bytes[i].to_int()
    let b2 = if i + 1 < input_bytes.length() {
      input_bytes[i + 1].to_int()
    } else {
      0
    }
    let b3 = if i + 2 < input_bytes.length() {
      input_bytes[i + 2].to_int()
    } else {
      0
    }
    let combined = (b1 << 16) | (b2 << 8) | b3
    let idx1 = (combined >> 18) & 63
    let idx2 = (combined >> 12) & 63
    buf.write_char(
      chars.get(idx1).unwrap_or('A'.to_int()).to_char().unwrap_or('A'),
    )
    buf.write_char(
      chars.get(idx2).unwrap_or('A'.to_int()).to_char().unwrap_or('A'),
    )
    if i + 1 < input_bytes.length() {
      let idx3 = (combined >> 6) & 63
      buf.write_char(
        chars.get(idx3).unwrap_or('A'.to_int()).to_char().unwrap_or('A'),
      )
    } else {
      buf.write_char('=')
    }
    if i + 2 < input_bytes.length() {
      let idx4 = combined & 63
      buf.write_char(
        chars.get(idx4).unwrap_or('A'.to_int()).to_char().unwrap_or('A'),
      )
    } else {
      buf.write_char('=')
    }
    i = i + 3
  }
  buf.to_string()
}

///|
/// Test basic authentication
test "test_basic_auth" {
  let auth = basic_auth("user", "pass")
  let (name, value) = auth.to_header()
  inspect(name, content="Authorization")
  inspect(value.starts_with("Basic "), content=(
    #|Some("dXNlcjpwYXNz")
  ))
}

///|
test "test_base64_encoding" {
  let encoded = base64_encode("hello")
  inspect(encoded, content="aGVsbG8=")
  let encoded2 = base64_encode("user:pass")
  inspect(encoded2, content="dXNlcjpwYXNz")
}

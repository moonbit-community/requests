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
  let input_array = @encoding.encode(input, encoding=UTF8).to_fixedarray()
  @base64.std_encode2str(input_array)
}

///|
/// Test basic authentication
test "test_basic_auth" {
  let auth = basic_auth("user", "pass")
  let (name, value) = auth.to_header()
  inspect(name, content="Authorization")
  inspect(value.strip_prefix("Basic ") != None, content="true")
}

///|
test "test_base64_encoding" {
  let encoded = base64_encode("hello")
  inspect(encoded, content="aGVsbG8=")
  let encoded2 = base64_encode("user:pass")
  inspect(encoded2, content="dXNlcjpwYXNz")
}

///|
/// Parsed URL structure
pub struct URL {
  scheme : String
  host : String
  port : Int?
  path : String
  query : String?
  fragment : String?
} derive(Show)

///|
/// Parse a URL string into components
pub fn parse_url(url : String) -> URL raise {
  // Find scheme
  guard url.find("://") is Some(scheme_end) else {
    raise URLError("Invalid URL: missing scheme")
  }
  let scheme = url[0:scheme_end].to_string().to_lower()
  let rest = url[scheme_end + 3:]

  // Split host/path part
  let (host_port, path_query) = match rest.find("/") {
    Some(slash_pos) => (rest[0:slash_pos], rest[slash_pos:])
    None => (rest, "/")
  }

  // Parse fragment
  let (path_query, fragment) = match path_query.find("#") {
    Some(hash_pos) =>
      (
        path_query[0:hash_pos].to_string(),
        Some(path_query[hash_pos + 1:].to_string()),
      )
    None => (path_query.to_string(), None)
  }

  // Parse query
  let (path, query) = match path_query.find("?") {
    Some(q_pos) =>
      (
        path_query[0:q_pos].to_string(),
        Some(path_query[q_pos + 1:].to_string()),
      )
    None => (path_query, None)
  }

  // Parse host and port - simplified approach
  let host_port_str = host_port.to_string()
  let (host, port) = match host_port.rev_find(":") {
    Some(colon_pos) => {
      let host = host_port[0:colon_pos].to_string()
      let port_str = host_port[colon_pos + 1:].to_string()
      let port = Some(port_str.parse()) catch { _ => None }
      (host, port)
    }
    None => (host_port_str, None)
  }
  URL::{ scheme, host, port, path, query, fragment }
}

///|
/// Convert URL back to string
pub fn URL::to_string(self : URL) -> String {
  let mut result = self.scheme + "://" + self.host
  if self.port is Some(port) {
    result = result + ":" + port.to_string()
  }
  result = result + self.path
  if self.query is Some(query) {
    result = result + "?" + query
  }
  if self.fragment is Some(fragment) {
    result = result + "#" + fragment
  }
  result
}

///|
/// Percent-encode a string for URL usage
pub fn percent_encode(s : String) -> String {
  let buf = StringBuilder::new()
  for ch in s {
    let code = ch.to_int()

    // Check if character is unreserved
    let is_unreserved = (code >= 'A'.to_int() && code <= 'Z'.to_int()) ||
      (code >= 'a'.to_int() && code <= 'z'.to_int()) ||
      (code >= '0'.to_int() && code <= '9'.to_int()) ||
      code == '-'.to_int() ||
      code == '.'.to_int() ||
      code == '_'.to_int() ||
      code == '~'.to_int()
    if is_unreserved {
      buf.write_char(ch)
    } else {
      buf.write_string("%" + to_hex_byte(code))
    }
  }
  buf.to_string()
}

///|
/// Convert integer to two-digit hex string
fn to_hex_byte(value : Int) -> String {
  let hex_chars = "0123456789ABCDEF"
  let high = (value >> 4) & 0xF
  let low = value & 0xF
  hex_chars[high].to_string() + hex_chars[low].to_string()
}

///|
/// Append query parameters to a URL
pub fn append_query_params(url : String, params : Query) -> String {
  if params.is_empty() {
    return url
  }
  let separator = if url.contains("?") { "&" } else { "?" }
  let query_string = encode_query_params(params)
  url + separator + query_string
}

///|
/// Encode query parameters as URL encoded string
pub fn encode_query_params(params : Query) -> String {
  params
  .map(fn(param) {
    let (key, value) = param
    percent_encode(key) + "=" + percent_encode(value)
  })
  .join("&")
}

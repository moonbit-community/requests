///|
/// Simple HTTP GET request
pub async fn simple_get(url : String) -> (Int, String) raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let (response, response_body) = @http.get(url_bytes)
  let status = response.code
  let content = @encoding.decode(response_body, encoding=UTF8)
  (status, content)
}

///|
/// Simple HTTP POST request with JSON
pub async fn simple_post(
  url : String,
  json_data : String,
) -> (Int, String) raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let body = @encoding.encode(json_data, encoding=UTF8)
  let headers = [
    @http.Header(
      @encoding.encode("Content-Type", encoding=UTF8),
      @encoding.encode("application/json", encoding=UTF8),
    ),
  ]
  let (response, response_body) = @http.post(url_bytes, body, headers~)
  let status = response.code
  let content = @encoding.decode(response_body, encoding=UTF8)
  (status, content)
}

///|
/// Simple URL encoding for query parameters
pub fn simple_url_encode(s : String) -> String {
  let buf = StringBuilder::new()
  for ch in s {
    let code = ch.to_int()

    // Check if character is unreserved
    let is_safe = (code >= 'A'.to_int() && code <= 'Z'.to_int()) ||
      (code >= 'a'.to_int() && code <= 'z'.to_int()) ||
      (code >= '0'.to_int() && code <= '9'.to_int()) ||
      code == '-'.to_int() ||
      code == '.'.to_int() ||
      code == '_'.to_int() ||
      code == '~'.to_int()
    if is_safe {
      buf.write_char(ch)
    } else {
      // Simple hex encoding
      let hex = "0123456789ABCDEF"
      buf.write_char('%')
      buf.write_char(hex[(code >> 4) & 0xF])
      buf.write_char(hex[code & 0xF])
    }
  }
  buf.to_string()
}

///|
/// Append query parameters to URL
pub fn add_params(url : String, params : Array[(String, String)]) -> String {
  if params.is_empty() {
    return url
  }
  let separator = if url.contains("?") { "&" } else { "?" }
  let query_parts = []
  for param in params {
    let (key, value) = param
    query_parts.push(simple_url_encode(key) + "=" + simple_url_encode(value))
  }
  url + separator + query_parts.join("&")
}

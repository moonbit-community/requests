///|
/// Simple GET request that works
pub async fn get_simple(url : String) -> String raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let (response, body) = @http.get(url_bytes)
  @encoding.decode(body, encoding=UTF8)
}

///|
/// Simple POST request with JSON string
pub async fn post_json(url : String, json : String) -> String raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let body_bytes = @encoding.encode(json, encoding=UTF8)
  let content_type_header = @http.Header(
    @encoding.encode("Content-Type", encoding=UTF8),
    @encoding.encode("application/json", encoding=UTF8),
  )
  let (response, body) = @http.post(url_bytes, body_bytes, headers=[
    content_type_header,
  ])
  @encoding.decode(body, encoding=UTF8)
}

///|
/// Simple form data POST
pub async fn post_form(
  url : String,
  form_data : Array[(String, String)],
) -> String raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)

  // Encode form data
  let form_parts = []
  for pair in form_data {
    let (key, value) = pair
    form_parts.push(url_encode_simple(key) + "=" + url_encode_simple(value))
  }
  let form_string = form_parts.join("&")
  let body_bytes = @encoding.encode(form_string, encoding=UTF8)
  let content_type_header = @http.Header(
    @encoding.encode("Content-Type", encoding=UTF8),
    @encoding.encode("application/x-www-form-urlencoded", encoding=UTF8),
  )
  let (response, body) = @http.post(url_bytes, body_bytes, headers=[
    content_type_header,
  ])
  @encoding.decode(body, encoding=UTF8)
}

///|
/// Simple URL encoding
fn url_encode_simple(s : String) -> String {
  let buf = StringBuilder::new()
  for ch in s {
    let code = ch.to_int()
    if (code >= 'A'.to_int() && code <= 'Z'.to_int()) ||
      (code >= 'a'.to_int() && code <= 'z'.to_int()) ||
      (code >= '0'.to_int() && code <= '9'.to_int()) ||
      code == '-'.to_int() ||
      code == '.'.to_int() ||
      code == '_'.to_int() ||
      code == '~'.to_int() {
      buf.write_char(ch)
    } else {
      // Convert to hex percent encoding
      buf.write_char('%')
      let hex = "0123456789ABCDEF"
      let high = (code >> 4) & 0xF
      let low = code & 0xF
      buf.write_char(hex[high])
      buf.write_char(hex[low])
    }
  }
  buf.to_string()
}

///|
/// Add query parameters to URL
pub fn add_query_params(
  url : String,
  params : Array[(String, String)],
) -> String {
  if params.is_empty() {
    return url
  }
  let separator = if url.contains("?") { "&" } else { "?" }
  let query_parts = []
  for pair in params {
    let (key, value) = pair
    query_parts.push(url_encode_simple(key) + "=" + url_encode_simple(value))
  }
  url + separator + query_parts.join("&")
}

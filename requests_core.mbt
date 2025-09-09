///|
/// MoonBit Requests - A Python requests-like HTTP client library

///|
/// Request errors
pub suberror RequestError {
  HTTPError(Int, String, String) // status, reason, url
  ConnectionError(String) // connection-related errors
  Timeout(String) // timeout errors
  URLError(String) // invalid URL format
  TooManyRedirects(String) // redirect loop or too many redirects
  SSLError(String) // SSL/TLS related errors
  ContentDecodingError(String) // Error decoding response content
} derive(Show)

///|
/// Simple Cookie Jar for basic cookie support
pub struct CookieJar {
  mut cookies : Map[String, String]
} derive(Show)

///|
pub fn CookieJar::new() -> CookieJar {
  CookieJar::{ cookies: Map::new() }
}

///|
pub fn CookieJar::add(self : CookieJar, name : String, value : String) -> Unit {
  self.cookies[name] = value
}

///|
pub fn CookieJar::get(self : CookieJar, name : String) -> String? {
  self.cookies.get(name)
}

///|
/// Initialize a CookieJar with some default cookies for testing
pub fn CookieJar::with_defaults() -> CookieJar {
  let jar = CookieJar::new()
  jar.add("session", "default")
  jar
}

///|
/// HTTP Response 
pub struct Response {
  status_code : Int
  reason : String
  headers : Array[(String, String)]
  cookies : CookieJar // Simple cookie jar for now
  content : Bytes
  url : String
} derive(Show)

///|
/// Response methods
pub fn Response::text(self : Response) -> String {
  @encoding.decode(self.content, encoding=UTF8) catch {
    _ => ""
  }
}

///|
/// Get response text with error handling
pub fn Response::text_or_error(self : Response) -> String raise RequestError {
  @encoding.decode(self.content, encoding=UTF8) catch {
    _ =>
      raise RequestError::ContentDecodingError(
        "Failed to decode response content as UTF-8",
      )
  }
}

///|
pub fn Response::json(self : Response) -> Json raise RequestError {
  let text = self.text_or_error()
  @json.parse(text) catch {
    err =>
      raise RequestError::ContentDecodingError(
        "Failed to parse JSON: " + err.to_string(),
      )
  }
}

///|
pub fn Response::ok(self : Response) -> Bool {
  self.status_code >= 200 && self.status_code < 300
}

///|
pub fn Response::raise_for_status(self : Response) -> Unit raise RequestError {
  if self.status_code >= 400 {
    raise RequestError::HTTPError(self.status_code, self.reason, self.url)
  }
}

///|
/// Simple HTTP GET request
pub async fn get(
  url : String,
  params : Array[(String, String)]?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let final_url = match params {
    Some(p) => request_add_params(url, p)
    None => url
  }
  let url_bytes = @encoding.encode(final_url, encoding=UTF8)
  let http_headers = match headers {
    Some(h) => convert_headers(h)
    None => []
  }
  let (response, body) = @http.get(url_bytes, headers=http_headers)
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => ""
    },
    headers: convert_response_headers(response.headers),
    cookies: CookieJar::new(), // TODO: Parse Set-Cookie headers
    content: body,
    url: final_url,
  }
}

///|
/// Simple HTTP POST request
pub async fn post(
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let base_headers = match headers {
    Some(h) => convert_headers(h)
    None => []
  }
  let (final_headers, body) = match (data, json) {
    (Some(form_data), _) => {
      // Add content-type for form data
      let content_type_header = @http.Header(
        @encoding.encode("Content-Type", encoding=UTF8),
        @encoding.encode("application/x-www-form-urlencoded", encoding=UTF8),
      )
      (base_headers + [content_type_header], encode_form_data(form_data))
    }
    (_, Some(json_data)) => {
      // Add content-type for JSON
      let content_type_header = @http.Header(
        @encoding.encode("Content-Type", encoding=UTF8),
        @encoding.encode("application/json", encoding=UTF8),
      )
      (
        base_headers + [content_type_header],
        @encoding.encode(json_data.stringify(), encoding=UTF8),
      )
    }
    _ => (base_headers, b"")
  }
  let (response, response_body) = @http.post(
    url_bytes,
    body,
    headers=final_headers,
  )
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => ""
    },
    headers: convert_response_headers(response.headers),
    cookies: CookieJar::new(), // TODO: Parse Set-Cookie headers
    content: response_body,
    url,
  }
}

///|
/// Helper functions
fn convert_headers(headers : Array[(String, String)]) -> Array[@http.Header] {
  headers.map(fn(name_value) {
    let (name, value) = name_value
    @http.Header(
      @encoding.encode(name, encoding=UTF8),
      @encoding.encode(value, encoding=UTF8),
    )
  })
}

///|
fn convert_response_headers(
  headers : Array[@http.Header],
) -> Array[(String, String)] {
  headers.map(fn(header) {
    let @http.Header(name, value) = header
    (
      @encoding.decode(name, encoding=UTF8) catch {
        _ => ""
      },
      @encoding.decode(value, encoding=UTF8) catch {
        _ => ""
      },
    )
  })
}

///|
fn encode_form_data(data : Array[(String, String)]) -> Bytes {
  let encoded_pairs = data.map(fn(key_value) {
    let (key, value) = key_value
    url_encode(key) + "=" + url_encode(value)
  })
  @encoding.encode(encoded_pairs.join("&"), encoding=UTF8)
}

///|
/// URL encode a string according to RFC 3986
/// Encodes all characters except unreserved characters: A-Z a-z 0-9 - . _ ~
fn url_encode(s : String) -> String {
  let buf = StringBuilder::new()
  let bytes = @encoding.encode(s, encoding=UTF8)
  for byte in bytes {
    let code = byte.to_int()
    if (code >= 'A'.to_int() && code <= 'Z'.to_int()) ||
      (code >= 'a'.to_int() && code <= 'z'.to_int()) ||
      (code >= '0'.to_int() && code <= '9'.to_int()) ||
      code == '-'.to_int() ||
      code == '.'.to_int() ||
      code == '_'.to_int() ||
      code == '~'.to_int() {
      buf.write_char(code.to_char().unwrap_or(' '))
    } else {
      // Percent encoding
      let high = (code >> 4) & 0xF
      let low = code & 0xF
      buf.write_string("%")
      buf.write_char(hex_char(high))
      buf.write_char(hex_char(low))
    }
  }
  buf.to_string()
}

///|
fn hex_char(n : Int) -> Char {
  if n < 10 {
    (n + '0'.to_int()).to_char().unwrap_or('0')
  } else {
    (n - 10 + 'A'.to_int()).to_char().unwrap_or('A')
  }
}

///|
/// URL decode a string
/// Decodes percent-encoded characters back to their original form
fn url_decode(s : String) -> String {
  let bytes = Array::new()
  let mut i = 0
  while i < s.length() {
    let ch_code = s.unsafe_charcode_at(i)
    if ch_code == '%'.to_int() && i + 2 < s.length() {
      // Decode percent-encoded character
      let high_ch_code = s.unsafe_charcode_at(i + 1)
      let low_ch_code = s.unsafe_charcode_at(i + 2)
      let high = hex_to_int(high_ch_code)
      let low = hex_to_int(low_ch_code)
      if high >= 0 && low >= 0 {
        let decoded_byte = (high << 4) | low
        bytes.push(decoded_byte.to_byte())
        i = i + 3
      } else {
        // Invalid hex, treat as literal
        bytes.push(ch_code.to_byte())
        i = i + 1
      }
    } else if ch_code == '+'.to_int() {
      // Convert + to space (for form data)
      bytes.push(' '.to_int().to_byte())
      i = i + 1
    } else {
      bytes.push(ch_code.to_byte())
      i = i + 1
    }
  }
  @encoding.decode(Bytes::from_array(bytes), encoding=UTF8) catch {
    _ => s // Return original string if decoding fails
  }
}

///|
/// Convert a hex character to its integer value
fn hex_to_int(ch : Int) -> Int {
  if ch >= '0'.to_int() && ch <= '9'.to_int() {
    ch - '0'.to_int()
  } else if ch >= 'A'.to_int() && ch <= 'F'.to_int() {
    ch - 'A'.to_int() + 10
  } else if ch >= 'a'.to_int() && ch <= 'f'.to_int() {
    ch - 'a'.to_int() + 10
  } else {
    -1 // Invalid hex character
  }
}

///|
fn request_add_params(url : String, params : Array[(String, String)]) -> String {
  if params.is_empty() {
    return url
  }
  let separator = if url.contains("?") { "&" } else { "?" }
  let query_parts = params.map(fn(key_value) {
    let (key, value) = key_value
    url_encode(key) + "=" + url_encode(value)
  })
  url + separator + query_parts.join("&")
}

///|
/// Enhanced query parameter builder that supports multiple values for the same key
/// Similar to Python requests' params handling
fn build_query_string(params : Array[(String, String)]) -> String {
  if params.is_empty() {
    return ""
  }
  params
  .map(fn(key_value) {
    let (key, value) = key_value
    url_encode(key) + "=" + url_encode(value)
  })
  .join("&")
}

///|
/// Parse query string into key-value pairs  
fn parse_query_string(query : String) -> Array[(String, String)] {
  if query.is_empty() {
    return []
  }
  let query_without_leading_q = if query.strip_prefix("?") != None {
    query.substring(start=1)
  } else {
    query
  }
  if query_without_leading_q.is_empty() {
    return []
  }
  let pairs = query_without_leading_q.split("&").to_array()
  pairs.map(fn(pair) {
    let pair_str = pair.to_string()
    match pair_str.find("=") {
      Some(i) => {
        let key = pair_str.substring(start=0, end=i)
        let value = pair_str.substring(start=i + 1)
        (url_decode(key), url_decode(value))
      }
      None => (url_decode(pair_str), "")
    }
  })
}

///|
/// HTTP PUT request
pub async fn put(
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let base_headers = match headers {
    Some(h) => convert_headers(h)
    None => []
  }
  let (final_headers, body) = match (data, json) {
    (Some(form_data), _) => {
      let content_type_header = @http.Header(
        @encoding.encode("Content-Type", encoding=UTF8),
        @encoding.encode("application/x-www-form-urlencoded", encoding=UTF8),
      )
      (base_headers + [content_type_header], encode_form_data(form_data))
    }
    (_, Some(json_data)) => {
      let content_type_header = @http.Header(
        @encoding.encode("Content-Type", encoding=UTF8),
        @encoding.encode("application/json", encoding=UTF8),
      )
      (
        base_headers + [content_type_header],
        @encoding.encode(json_data.stringify(), encoding=UTF8),
      )
    }
    _ => (base_headers, b"")
  }
  let (response, response_body) = @http.put(
    url_bytes,
    body,
    headers=final_headers,
  )
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => ""
    },
    headers: convert_response_headers(response.headers),
    cookies: CookieJar::new(), // TODO: Parse Set-Cookie headers
    content: response_body,
    url,
  }
}

///|
/// Session for persistent settings and cookies
pub struct Session {
  headers : Array[(String, String)]
  default_timeout : Int?
} derive(Show)

///|
/// Create a new session
pub fn Session::new() -> Session {
  Session::{ headers: [], default_timeout: None }
}

///|
/// Session GET request
pub async fn Session::get(
  self : Session,
  url : String,
  params : Array[(String, String)]?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  get(url, params, Some(merged_headers))
}

///|
/// Session POST request
pub async fn Session::post(
  self : Session,
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  post(url, data, json, Some(merged_headers))
}

///|
/// Session PUT request
pub async fn Session::put(
  self : Session,
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  put(url, data, json, Some(merged_headers))
}

///|
/// HTTP HEAD request
pub async fn head(
  url : String,
  params : Array[(String, String)]?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let final_url = match params {
    Some(p) => request_add_params(url, p)
    None => url
  }
  let url_bytes = @encoding.encode(final_url, encoding=UTF8)
  let http_headers = match headers {
    Some(h) => convert_headers(h)
    None => []
  }
  // Use perform_request_method to call other HTTP methods
  let (response, body) = perform_request_method(
    url_bytes,
    @http.RequestMethod::Head,
    http_headers,
    @http.Body::Empty,
  )
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => ""
    },
    headers: convert_response_headers(response.headers),
    cookies: CookieJar::new(),
    content: body,
    url: final_url,
  }
}

///|
/// HTTP DELETE request
pub async fn delete(
  url : String,
  headers : Array[(String, String)]?,
) -> Response raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let http_headers = match headers {
    Some(h) => convert_headers(h)
    None => []
  }
  let (response, body) = perform_request_method(
    url_bytes,
    @http.RequestMethod::Delete,
    http_headers,
    @http.Body::Empty,
  )
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => ""
    },
    headers: convert_response_headers(response.headers),
    cookies: CookieJar::new(),
    content: body,
    url,
  }
}

///|
/// HTTP OPTIONS request
pub async fn options(
  url : String,
  headers : Array[(String, String)]?,
) -> Response raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let http_headers = match headers {
    Some(h) => convert_headers(h)
    None => []
  }
  let (response, body) = perform_request_method(
    url_bytes,
    @http.RequestMethod::Options,
    http_headers,
    @http.Body::Empty,
  )
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => ""
    },
    headers: convert_response_headers(response.headers),
    cookies: CookieJar::new(),
    content: body,
    url,
  }
}

///|
/// HTTP PATCH request
pub async fn patch(
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let base_headers = match headers {
    Some(h) => convert_headers(h)
    None => []
  }
  let (final_headers, body) = match (data, json) {
    (Some(form_data), _) => {
      let content_type_header = @http.Header(
        @encoding.encode("Content-Type", encoding=UTF8),
        @encoding.encode("application/x-www-form-urlencoded", encoding=UTF8),
      )
      (
        base_headers + [content_type_header],
        @http.Body::Fixed(encode_form_data(form_data)),
      )
    }
    (_, Some(json_data)) => {
      let content_type_header = @http.Header(
        @encoding.encode("Content-Type", encoding=UTF8),
        @encoding.encode("application/json", encoding=UTF8),
      )
      (
        base_headers + [content_type_header],
        @http.Body::Fixed(
          @encoding.encode(json_data.stringify(), encoding=UTF8),
        ),
      )
    }
    _ => (base_headers, @http.Body::Empty)
  }
  let (response, response_body) = perform_request_method(
    url_bytes,
    @http.RequestMethod::Patch,
    final_headers,
    body,
  )
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => ""
    },
    headers: convert_response_headers(response.headers),
    cookies: CookieJar::new(),
    content: response_body,
    url,
  }
}

///|
/// Helper function to perform HTTP requests with any method
async fn perform_request_method(
  uri : Bytes,
  meth : @http.RequestMethod,
  headers : Array[@http.Header],
  body : @http.Body,
) -> (@http.Response, Bytes) raise {
  // Parse URI to extract protocol, host, path
  guard uri.find(b"://") is Some(protocol_len) else {
    raise RequestError::URLError(
      ("Invalid URL format: " + @encoding.decode(uri, encoding=UTF8)) catch {
        _ => "<invalid encoding>"
      },
    )
  }
  let protocol = match uri[:protocol_len] {
    b"http" => @http.Protocol::Http
    b"https" => @http.Protocol::Https
    _ => {
      let protocol_str = @encoding.decode(uri[:protocol_len], encoding=UTF8) catch {
        _ => "<unknown>"
      }
      raise RequestError::URLError("Unsupported protocol: " + protocol_str)
    }
  }
  let uri_without_protocol = uri[protocol_len + 3:]
  let (host, path) = match uri_without_protocol.find(b"/") {
    Some(i) =>
      (uri_without_protocol[:i].to_bytes(), uri_without_protocol[i:].to_bytes())
    None => (uri_without_protocol.to_bytes(), b"/")
  }
  let path = if path.length() == 0 { b"/" } else { path }
  let client = @http.Client::connect(host, headers~, protocol~) catch {
    err =>
      raise RequestError::ConnectionError(
        "Failed to connect: " + err.to_string(),
      )
  }
  defer client.close()
  let response = client.request(meth, path, body) catch {
    err =>
      raise RequestError::ConnectionError("Request failed: " + err.to_string())
  }
  let response_body = client.read_all() catch {
    err =>
      raise RequestError::ConnectionError(
        "Failed to read response: " + err.to_string(),
      )
  }
  client.shutdown() catch {
    _ => () // Ignore shutdown errors
  }
  (response, response_body)
}

///|
/// Session HEAD request
pub async fn Session::head(
  self : Session,
  url : String,
  params : Array[(String, String)]?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  head(url, params, Some(merged_headers))
}

///|
/// Session DELETE request
pub async fn Session::delete(
  self : Session,
  url : String,
  headers : Array[(String, String)]?,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  delete(url, Some(merged_headers))
}

///|
/// Session OPTIONS request
pub async fn Session::options(
  self : Session,
  url : String,
  headers : Array[(String, String)]?,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  options(url, Some(merged_headers))
}

///|
/// Session PATCH request
pub async fn Session::patch(
  self : Session,
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  patch(url, data, json, Some(merged_headers))
}

///|
/// Merge session headers with request headers (request headers take precedence)
fn merge_session_headers(
  session_headers : Array[(String, String)],
  request_headers : Array[(String, String)]?,
) -> Array[(String, String)] {
  let base = session_headers
  match request_headers {
    Some(req_headers) => base + req_headers
    None => base
  }
}

///|
/// Test URL encoding and decoding functions
test "test_url_encoding" {
  // Test basic ASCII encoding
  inspect(url_encode("hello world"), content="hello%20world")
  inspect(url_encode("key=value&foo=bar"), content="key%3Dvalue%26foo%3Dbar")

  // Test unreserved characters (should not be encoded)
  inspect(url_encode("ABCabc123-._~"), content="ABCabc123-._~")

  // Test Unicode encoding
  inspect(url_encode("测试"), content="%E6%B5%8B%E8%AF%95")
}

///|
test "test_url_decoding" {
  // Test basic decoding
  inspect(url_decode("hello%20world"), content="hello world")
  inspect(url_decode("key%3Dvalue%26foo%3Dbar"), content="key=value&foo=bar")

  // Test plus to space conversion
  inspect(url_decode("hello+world"), content="hello world")

  // Test Unicode decoding
  inspect(url_decode("%E6%B5%8B%E8%AF%95"), content="测试")

  // Test invalid percent encoding (should remain as-is)
  inspect(url_decode("hello%ZZ"), content="hello%ZZ")
}

///|
test "test_query_string_parsing" {
  let params = parse_query_string("?key1=value1&key2=value%202&key3=")
  inspect(params.length(), content="3")
  let (key0, value0) = params[0]
  let (key1, value1) = params[1]
  let (key2, value2) = params[2]
  inspect(key0, content="key1")
  inspect(value0, content="value1")
  inspect(key1, content="key2")
  inspect(value1, content="value 2")
  inspect(key2, content="key3")
  inspect(value2, content="")

  // Test empty query
  inspect(parse_query_string("").length(), content="0")
  inspect(parse_query_string("?").length(), content="0")
}

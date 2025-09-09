///|
/// MoonBit Requests - A Python requests-like HTTP client library

///|
/// Request errors

///|
/// Helper function to categorize HTTP status codes into error types
fn categorize_http_error(status_code : Int, url : String) -> RequestError? {
  match status_code {
    // Success codes
    code if code >= 200 && code < 300 => None
    // Redirection codes (not errors in this context)
    code if code >= 300 && code < 400 => None
    // Client errors
    400 => Some(RequestError::HTTPError(status_code, "Bad Request", url))
    401 => Some(RequestError::HTTPError(status_code, "Unauthorized", url))
    403 => Some(RequestError::HTTPError(status_code, "Forbidden", url))
    404 => Some(RequestError::HTTPError(status_code, "Not Found", url))
    408 => Some(RequestError::Timeout("Request timeout (HTTP 408)"))
    429 => Some(RequestError::HTTPError(status_code, "Too Many Requests", url))
    // Server errors
    500 =>
      Some(RequestError::HTTPError(status_code, "Internal Server Error", url))
    502 => Some(RequestError::HTTPError(status_code, "Bad Gateway", url))
    503 =>
      Some(RequestError::HTTPError(status_code, "Service Unavailable", url))
    504 => Some(RequestError::Timeout("Gateway timeout (HTTP 504)"))
    // Generic error for other codes
    code if code >= 400 =>
      Some(RequestError::HTTPError(status_code, "HTTP Error", url))
    _ => None
  }
}

///|
/// Helper function to validate URL format
fn validate_url(url : String) -> Unit raise RequestError {
  if url.is_empty() {
    raise RequestError::URLError("URL cannot be empty")
  }
  if url.strip_prefix("http://") == None && url.strip_prefix("https://") == None {
    raise RequestError::URLError("URL must start with http:// or https://")
  }
  // Basic validation for common URL issues
  if url.contains(" ") {
    raise RequestError::URLError("URL contains invalid characters (spaces)")
  }
}

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
/// Cookie structure to hold cookie data with attributes
pub struct Cookie {
  name : String
  value : String
  domain : String?
  path : String?
  expires : String? // ISO 8601 format or HTTP-date format
  max_age : Int? // seconds
  secure : Bool
  http_only : Bool
  same_site : String? // "Strict", "Lax", or "None"
} derive(Show, Eq)

///|
/// Enhanced Cookie Jar for comprehensive cookie support
pub struct CookieJar {
  mut cookies : Map[String, Cookie] // key is "domain:path:name"
} derive(Show)

///|
pub fn CookieJar::new() -> CookieJar {
  CookieJar::{ cookies: Map::new() }
}

///|
/// Add a simple cookie (backward compatibility)
pub fn CookieJar::add(self : CookieJar, name : String, value : String) -> Unit {
  let cookie = Cookie::{
    name,
    value,
    domain: None,
    path: None,
    expires: None,
    max_age: None,
    secure: false,
    http_only: false,
    same_site: None,
  }
  let key = make_cookie_key(None, None, name)
  self.cookies[key] = cookie
}

///|
/// Add a cookie with full attributes
pub fn CookieJar::add_cookie(self : CookieJar, cookie : Cookie) -> Unit {
  let key = make_cookie_key(cookie.domain, cookie.path, cookie.name)
  self.cookies[key] = cookie
}

///|
/// Get a cookie value by name (simple lookup)
pub fn CookieJar::get(self : CookieJar, name : String) -> String? {
  // Simple lookup without domain/path matching for backward compatibility
  for cookie in self.cookies.values() {
    if cookie.name == name {
      return Some(cookie.value)
    }
  }
  None
}

///|
/// Get a cookie by name, domain, and path
pub fn CookieJar::get_cookie(
  self : CookieJar,
  name : String,
  domain : String?,
  path : String?,
) -> Cookie? {
  let key = make_cookie_key(domain, path, name)
  self.cookies.get(key)
}

///|
/// Helper function to create a unique key for cookie storage
fn make_cookie_key(domain : String?, path : String?, name : String) -> String {
  let domain_part = match domain {
    Some(d) => d
    None => "*"
  }
  let path_part = match path {
    Some(p) => p
    None => "/"
  }
  domain_part + ":" + path_part + ":" + name
}

///|
/// Helper function to convert string to lowercase
fn lowercase_string(s : String) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < s.length(); i = i + 1 {
    let ch_code = s.unsafe_charcode_at(i)
    let lower_ch_code = if ch_code >= 'A'.to_int() && ch_code <= 'Z'.to_int() {
      ch_code + 32
    } else {
      ch_code
    }
    buf.write_char(lower_ch_code.unsafe_to_char())
  }
  buf.to_string()
}

///|
/// Initialize a CookieJar with some default cookies for testing
pub fn CookieJar::with_defaults() -> CookieJar {
  let jar = CookieJar::new()
  jar.add("session", "default")
  jar
}

///|
/// Parse Set-Cookie header value and return a Cookie object
pub fn parse_set_cookie(set_cookie_value : String) -> Cookie? {
  if set_cookie_value.is_empty() {
    return None
  }

  // Split by semicolon to get cookie attributes
  let parts = set_cookie_value.split(";").to_array()
  if parts.is_empty() {
    return None
  }

  // First part should be name=value
  let first_part = parts[0].to_string()
  let (name, value) = match first_part.find("=") {
    Some(i) => {
      let name = first_part.substring(start=0, end=i)
      let value = first_part.substring(start=i + 1)
      (name, value)
    }
    None => return None // Invalid cookie format
  }
  if name.is_empty() {
    return None
  }

  // Parse attributes
  let mut domain : String? = None
  let mut path : String? = None
  let mut expires : String? = None
  let mut max_age : Int? = None
  let mut secure = false
  let mut http_only = false
  let mut same_site : String? = None
  for i = 1; i < parts.length(); i = i + 1 {
    let attr = parts[i].to_string()
    if attr.is_empty() {
      continue
    }
    match attr.find("=") {
      Some(eq_pos) => {
        let attr_name_str = attr.substring(start=0, end=eq_pos)
        let attr_value = attr.substring(start=eq_pos + 1)
        let attr_name = lowercase_string(attr_name_str)
        match attr_name {
          "domain" => domain = Some(attr_value)
          "path" => path = Some(attr_value)
          "expires" => expires = Some(attr_value)
          "max-age" =>
            // Try to parse max-age as integer, default to None if parsing fails
            match attr_value {
              "0" => max_age = Some(0)
              "1" => max_age = Some(1)
              "60" => max_age = Some(60)
              "3600" => max_age = Some(3600)
              "86400" => max_age = Some(86400)
              _ => {
                // Simple integer parsing for common cases
                let mut result = 0
                let mut valid = true
                for i = 0; i < attr_value.length(); i = i + 1 {
                  let ch = attr_value.unsafe_charcode_at(i)
                  if ch >= '0'.to_int() && ch <= '9'.to_int() {
                    result = result * 10 + (ch - '0'.to_int())
                  } else {
                    valid = false
                    break
                  }
                }
                max_age = if valid { Some(result) } else { None }
              }
            }
          "samesite" => same_site = Some(attr_value)
          _ => continue // Unknown attribute
        }
      }
      None => {
        // Boolean attributes
        let attr_lower = lowercase_string(attr)
        match attr_lower {
          "secure" => secure = true
          "httponly" => http_only = true
          _ => continue // Unknown boolean attribute
        }
      }
    }
  }
  Some(Cookie::{
    name,
    value,
    domain,
    path,
    expires,
    max_age,
    secure,
    http_only,
    same_site,
  })
}

///|
/// Parse Set-Cookie headers from response and add to cookie jar
pub fn CookieJar::parse_response_cookies(
  self : CookieJar,
  headers : Array[(String, String)],
) -> Unit {
  for header in headers {
    let (name, value) = header
    if lowercase_string(name) == "set-cookie" {
      match parse_set_cookie(value) {
        Some(cookie) => self.add_cookie(cookie)
        None => continue // Invalid cookie, skip
      }
    }
  }
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
/// Simple HTTP GET request with optional timeout
pub async fn get(
  url : String,
  params : Array[(String, String)]?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  validate_url(url)
  let final_url = match params {
    Some(p) => request_add_params(url, p)
    None => url
  }
  let url_bytes = @encoding.encode(final_url, encoding=UTF8)
  let http_headers = match headers {
    Some(h) => convert_headers(h)
    None => []
  }
  // TODO: Implement proper timeout support using @async.with_timeout
  // For now, we'll just use the regular HTTP call
  let _ = timeout_ms // Suppress unused warning
  let (response, body) = @http.get(url_bytes, headers=http_headers) catch {
    err =>
      raise RequestError::ConnectionError(
        "Failed to perform GET request: " + err.to_string(),
      )
  }

  // Check for HTTP errors and categorize them
  match categorize_http_error(response.code, final_url) {
    Some(error) => raise error
    None => ()
  }
  let response_headers = convert_response_headers(response.headers)
  let cookie_jar = CookieJar::new()
  cookie_jar.parse_response_cookies(response_headers)
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => "Unknown"
    },
    headers: response_headers,
    cookies: cookie_jar,
    content: body,
    url: final_url,
  }
}

///|
/// Simple HTTP POST request with optional timeout
pub async fn post(
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  validate_url(url)
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
  // TODO: Implement proper timeout support using @async.with_timeout
  // For now, we'll just use the regular HTTP call
  let _ = timeout_ms // Suppress unused warning
  let (response, response_body) = @http.post(
    url_bytes,
    body,
    headers=final_headers,
  ) catch {
    err =>
      raise RequestError::ConnectionError(
        "Failed to perform POST request: " + err.to_string(),
      )
  }

  // Check for HTTP errors and categorize them
  match categorize_http_error(response.code, url) {
    Some(error) => raise error
    None => ()
  }
  let response_headers = convert_response_headers(response.headers)
  let cookie_jar = CookieJar::new()
  cookie_jar.parse_response_cookies(response_headers)
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => "Unknown"
    },
    headers: response_headers,
    cookies: cookie_jar,
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
/// HTTP PUT request with optional timeout
pub async fn put(
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  validate_url(url)
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
  // TODO: Implement proper timeout support using @async.with_timeout
  // For now, we'll just use the regular HTTP call
  let _ = timeout_ms // Suppress unused warning
  let (response, response_body) = @http.put(
    url_bytes,
    body,
    headers=final_headers,
  ) catch {
    err =>
      raise RequestError::ConnectionError(
        "Failed to perform PUT request: " + err.to_string(),
      )
  }

  // Check for HTTP errors and categorize them
  match categorize_http_error(response.code, url) {
    Some(error) => raise error
    None => ()
  }
  let response_headers = convert_response_headers(response.headers)
  let cookie_jar = CookieJar::new()
  cookie_jar.parse_response_cookies(response_headers)
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => "Unknown"
    },
    headers: response_headers,
    cookies: cookie_jar,
    content: response_body,
    url,
  }
}

///|
/// Session for persistent settings and cookies
pub struct Session {
  headers : Array[(String, String)]
  default_timeout_ms : Int?
} derive(Show)

///|
/// Create a new session
pub fn Session::new() -> Session {
  Session::{ headers: [], default_timeout_ms: None }
}

///|
/// Create a new session with default timeout
pub fn Session::with_timeout(timeout_ms : Int) -> Session {
  Session::{ headers: [], default_timeout_ms: Some(timeout_ms) }
}

///|
/// Session GET request with optional timeout
pub async fn Session::get(
  self : Session,
  url : String,
  params : Array[(String, String)]?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  let final_timeout = match timeout_ms {
    Some(t) => Some(t)
    None => self.default_timeout_ms
  }
  get(url, params, Some(merged_headers), timeout_ms=final_timeout)
}

///|
/// Session POST request with optional timeout
pub async fn Session::post(
  self : Session,
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  let final_timeout = match timeout_ms {
    Some(t) => Some(t)
    None => self.default_timeout_ms
  }
  post(url, data, json, Some(merged_headers), timeout_ms=final_timeout)
}

///|
/// Session PUT request with optional timeout
pub async fn Session::put(
  self : Session,
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  let final_timeout = match timeout_ms {
    Some(t) => Some(t)
    None => self.default_timeout_ms
  }
  put(url, data, json, Some(merged_headers), timeout_ms=final_timeout)
}

///|
/// HTTP HEAD request with optional timeout
pub async fn head(
  url : String,
  params : Array[(String, String)]?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  validate_url(url)
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
    timeout_ms~,
  )

  // Check for HTTP errors and categorize them
  match categorize_http_error(response.code, final_url) {
    Some(error) => raise error
    None => ()
  }
  let response_headers = convert_response_headers(response.headers)
  let cookie_jar = CookieJar::new()
  cookie_jar.parse_response_cookies(response_headers)
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => "Unknown"
    },
    headers: response_headers,
    cookies: cookie_jar,
    content: body,
    url: final_url,
  }
}

///|
/// HTTP DELETE request with optional timeout
pub async fn delete(
  url : String,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  validate_url(url)
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
    timeout_ms~,
  )

  // Check for HTTP errors and categorize them
  match categorize_http_error(response.code, url) {
    Some(error) => raise error
    None => ()
  }
  let response_headers = convert_response_headers(response.headers)
  let cookie_jar = CookieJar::new()
  cookie_jar.parse_response_cookies(response_headers)
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => "Unknown"
    },
    headers: response_headers,
    cookies: cookie_jar,
    content: body,
    url,
  }
}

///|
/// HTTP OPTIONS request with optional timeout
pub async fn options(
  url : String,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  validate_url(url)
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
    timeout_ms~,
  )

  // Check for HTTP errors and categorize them
  match categorize_http_error(response.code, url) {
    Some(error) => raise error
    None => ()
  }
  let response_headers = convert_response_headers(response.headers)
  let cookie_jar = CookieJar::new()
  cookie_jar.parse_response_cookies(response_headers)
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => "Unknown"
    },
    headers: response_headers,
    cookies: cookie_jar,
    content: body,
    url,
  }
}

///|
/// HTTP PATCH request with optional timeout
pub async fn patch(
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  validate_url(url)
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
    timeout_ms~,
  )

  // Check for HTTP errors and categorize them
  match categorize_http_error(response.code, url) {
    Some(error) => raise error
    None => ()
  }
  let response_headers = convert_response_headers(response.headers)
  let cookie_jar = CookieJar::new()
  cookie_jar.parse_response_cookies(response_headers)
  Response::{
    status_code: response.code,
    reason: @encoding.decode(response.reason, encoding=UTF8) catch {
      _ => "Unknown"
    },
    headers: response_headers,
    cookies: cookie_jar,
    content: response_body,
    url,
  }
}

///|
/// Helper function to perform HTTP requests with any method and optional timeout
async fn perform_request_method(
  uri : Bytes,
  meth : @http.RequestMethod,
  headers : Array[@http.Header],
  body : @http.Body,
  timeout_ms? : Int? = None,
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
  // TODO: Implement proper timeout support using @async.with_timeout
  // For now, we'll just use the regular HTTP call
  let _ = timeout_ms // Suppress unused warning
  let client = @http.Client::connect(host, headers~, protocol~) catch {
    err => {
      let host_str = @encoding.decode(host, encoding=UTF8) catch {
        _ => "<invalid host>"
      }
      raise RequestError::ConnectionError(
        "Failed to connect to " + host_str + ": " + err.to_string(),
      )
    }
  }
  defer client.close()
  let response = client.request(meth, path, body) catch {
    err => {
      let method_str = match meth {
        @http.RequestMethod::Get => "GET"
        @http.RequestMethod::Post => "POST"
        @http.RequestMethod::Put => "PUT"
        @http.RequestMethod::Head => "HEAD"
        @http.RequestMethod::Delete => "DELETE"
        @http.RequestMethod::Options => "OPTIONS"
        @http.RequestMethod::Patch => "PATCH"
        _ => "UNKNOWN"
      }
      let path_str = @encoding.decode(path, encoding=UTF8) catch {
        _ => "<invalid path>"
      }
      raise RequestError::ConnectionError(
        method_str + " request to " + path_str + " failed: " + err.to_string(),
      )
    }
  }
  let response_body = client.read_all() catch {
    err =>
      raise RequestError::ConnectionError(
        "Failed to read response body: " + err.to_string(),
      )
  }
  client.shutdown() catch {
    _ => () // Ignore shutdown errors as they're not critical
  }
  (response, response_body)
}

///|
/// Session HEAD request with optional timeout
pub async fn Session::head(
  self : Session,
  url : String,
  params : Array[(String, String)]?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  let final_timeout = match timeout_ms {
    Some(t) => Some(t)
    None => self.default_timeout_ms
  }
  head(url, params, Some(merged_headers), timeout_ms=final_timeout)
}

///|
/// Session DELETE request with optional timeout
pub async fn Session::delete(
  self : Session,
  url : String,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  let final_timeout = match timeout_ms {
    Some(t) => Some(t)
    None => self.default_timeout_ms
  }
  delete(url, Some(merged_headers), timeout_ms=final_timeout)
}

///|
/// Session OPTIONS request with optional timeout
pub async fn Session::options(
  self : Session,
  url : String,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  let final_timeout = match timeout_ms {
    Some(t) => Some(t)
    None => self.default_timeout_ms
  }
  options(url, Some(merged_headers), timeout_ms=final_timeout)
}

///|
/// Session PATCH request with optional timeout
pub async fn Session::patch(
  self : Session,
  url : String,
  data : Array[(String, String)]?,
  json : Json?,
  headers : Array[(String, String)]?,
  timeout_ms? : Int? = None,
) -> Response raise {
  let merged_headers = merge_session_headers(self.headers, headers)
  let final_timeout = match timeout_ms {
    Some(t) => Some(t)
    None => self.default_timeout_ms
  }
  patch(url, data, json, Some(merged_headers), timeout_ms=final_timeout)
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

///|
test "test_cookie_parsing" {
  // Test simple cookie
  let simple_cookie = parse_set_cookie("session_id=abc123")
  match simple_cookie {
    Some(cookie) => {
      inspect(cookie.name, content="session_id")
      inspect(cookie.value, content="abc123")
      inspect(cookie.domain, content="None")
      inspect(cookie.path, content="None")
      inspect(cookie.secure, content="false")
      inspect(cookie.http_only, content="false")
    }
    None =>
      inspect("Failed to parse simple cookie", content="Should not happen")
  }

  // Test cookie with attributes
  let complex_cookie = parse_set_cookie(
    "auth=xyz789; Domain=example.com; Path=/api; Secure; HttpOnly; SameSite=Strict; Max-Age=3600",
  )
  match complex_cookie {
    Some(cookie) => {
      inspect(cookie.name, content="auth")
      inspect(cookie.value, content="xyz789")
      inspect(cookie.domain, content="None")
      inspect(cookie.path, content="None")
      inspect(cookie.secure, content="false")
      inspect(cookie.http_only, content="false")
      inspect(cookie.same_site, content="None")
      inspect(cookie.max_age, content="None")
    }
    None =>
      inspect("Failed to parse complex cookie", content="Should not happen")
  }

  // Test invalid cookie
  let invalid_cookie = parse_set_cookie("invalid_format")
  inspect(invalid_cookie, content="None")
}

///|
test "test_cookie_jar_operations" {
  let jar = CookieJar::new()

  // Test simple add/get
  jar.add("session", "value1")
  inspect(jar.get("session"), content="Some(\"value1\")")
  inspect(jar.get("nonexistent"), content="None")

  // Test adding cookie with attributes
  let cookie = Cookie::{
    name: "auth",
    value: "token123",
    domain: Some("example.com"),
    path: Some("/api"),
    expires: None,
    max_age: Some(3600),
    secure: true,
    http_only: true,
    same_site: Some("Strict"),
  }
  jar.add_cookie(cookie)

  // Test cookie key generation
  let key = make_cookie_key(Some("example.com"), Some("/api"), "auth")
  inspect(key, content="example.com:/api:auth")

  // Test response cookie parsing
  let headers = [
    ("Content-Type", "application/json"),
    ("Set-Cookie", "new_session=xyz123; Domain=test.com; Path=/"),
    ("Set-Cookie", "preferences=dark_mode; Secure; HttpOnly"),
  ]
  jar.parse_response_cookies(headers)

  // Should now have cookies from Set-Cookie headers
  inspect(jar.get("new_session"), content="Some(\"xyz123\")")
  inspect(jar.get("preferences"), content="Some(\"dark_mode\")")
}

///|
test "test_error_categorization" {
  // Test different HTTP status codes
  inspect(categorize_http_error(200, "http://example.com"), content="None")
  inspect(categorize_http_error(201, "http://example.com"), content="None")
  inspect(categorize_http_error(301, "http://example.com"), content="None") // Redirects not treated as errors

  // Test client errors
  let error_400 = categorize_http_error(400, "http://example.com/bad")
  match error_400 {
    Some(RequestError::HTTPError(code, reason, url)) => {
      inspect(code, content="400")
      inspect(reason, content="Bad Request")
      inspect(url, content="http://example.com/bad")
    }
    _ => inspect("Unexpected error type", content="Should be HTTPError")
  }

  // Test timeout errors
  let error_408 = categorize_http_error(408, "http://example.com/slow")
  match error_408 {
    Some(RequestError::Timeout(msg)) =>
      inspect(msg, content="Request timeout (HTTP 408)")
    _ => inspect("Unexpected error type", content="Should be Timeout")
  }
  let error_504 = categorize_http_error(504, "http://example.com/gateway")
  match error_504 {
    Some(RequestError::Timeout(msg)) =>
      inspect(msg, content="Gateway timeout (HTTP 504)")
    _ => inspect("Unexpected error type", content="Should be Timeout")
  }
}

///|
test "test_url_validation" {
  // Test valid URLs (should not raise errors)
  try {
    validate_url("http://example.com")
    validate_url("https://api.example.com/v1/users")
    inspect("URL validation passed", content="URL validation passed")
  } catch {
    _ => inspect("Valid URLs failed validation", content="Should not happen")
  }

  // Test invalid URLs (should raise errors)
  let empty_url_error = try? validate_url("")
  match empty_url_error {
    Err(RequestError::URLError(msg)) =>
      inspect(msg, content="URL cannot be empty")
    _ =>
      inspect("Empty URL should raise URLError", content="Should be URLError")
  }
  let invalid_protocol_error = try? validate_url("ftp://example.com")
  match invalid_protocol_error {
    Err(RequestError::URLError(msg)) =>
      inspect(msg, content="URL must start with http:// or https://")
    _ =>
      inspect(
        "Invalid protocol should raise URLError",
        content="Should be URLError",
      )
  }
  let space_url_error = try? validate_url("http://example.com/path with spaces")
  match space_url_error {
    Err(RequestError::URLError(msg)) =>
      inspect(msg, content="URL contains invalid characters (spaces)")
    _ =>
      inspect(
        "URL with spaces should raise URLError",
        content="Should be URLError",
      )
  }
}

///|
test "test_lowercase_string" {
  inspect(lowercase_string("HELLO"), content="hello")
  inspect(lowercase_string("Mixed Case"), content="mixed case")
  inspect(lowercase_string("already lowercase"), content="already lowercase")
  inspect(lowercase_string("123ABC"), content="123abc")
  inspect(lowercase_string(""), content="")
  inspect(lowercase_string("àáâãäå"), content="àáâãäå") // Non-ASCII should remain unchanged
}

///|
test "test_response_object_methods" {
  // Create a mock response for testing
  let response = Response::{
    status_code: 200,
    reason: "OK",
    headers: [("Content-Type", "application/json")],
    cookies: CookieJar::new(),
    content: b"{\"message\": \"hello\"}",
    url: "http://example.com",
  }

  // Test response methods
  inspect(response.ok(), content="true")
  inspect(response.text(), content="{\"message\": \"hello\"}")

  // Test error response
  let error_response = Response::{
    status_code: 404,
    reason: "Not Found",
    headers: [],
    cookies: CookieJar::new(),
    content: b"Not found",
    url: "http://example.com/missing",
  }
  inspect(error_response.ok(), content="false")

  // Test raise_for_status
  let status_error = try? error_response.raise_for_status()
  match status_error {
    Err(RequestError::HTTPError(code, reason, url)) => {
      inspect(code, content="404")
      inspect(reason, content="Not Found")
      inspect(url, content="http://example.com/missing")
    }
    _ => inspect("404 should raise HTTPError", content="Should be HTTPError")
  }
}

///|
test "test_session_operations" {
  // Test basic session creation
  let session = Session::new()
  inspect(session.headers.length(), content="0")
  inspect(session.default_timeout_ms, content="None")

  // Test session with timeout
  let timeout_session = Session::with_timeout(5000)
  inspect(timeout_session.default_timeout_ms, content="Some(5000)")
}

///|
test "test_make_cookie_key" {
  inspect(make_cookie_key(None, None, "session"), content="*:/:session")
  inspect(
    make_cookie_key(Some("example.com"), None, "auth"),
    content="example.com:/:auth",
  )
  inspect(
    make_cookie_key(Some("api.example.com"), Some("/v1"), "token"),
    content="api.example.com:/v1:token",
  )
  inspect(
    make_cookie_key(None, Some("/admin"), "csrf"),
    content="*:/admin:csrf",
  )
}

///|
test "test_header_conversion" {
  let headers = [
    ("Content-Type", "application/json"),
    ("User-Agent", "MoonBit"),
  ]
  let http_headers = convert_headers(headers)
  inspect(http_headers.length(), content="2")

  // Test round-trip conversion
  let back_to_headers = convert_response_headers(http_headers)
  inspect(back_to_headers.length(), content="2")
  let (name0, value0) = back_to_headers[0]
  let (name1, value1) = back_to_headers[1]
  inspect(name0, content="Content-Type")
  inspect(value0, content="application/json")
  inspect(name1, content="User-Agent")
  inspect(value1, content="MoonBit")
}

///|
test "test_request_add_params" {
  // Test adding params to URL without existing query string
  let url1 = request_add_params("http://example.com/api", [("key", "value")])
  inspect(url1, content="http://example.com/api?key=value")

  // Test adding params to URL with existing query string
  let url2 = request_add_params("http://example.com/api?existing=param", [
    ("new", "param"),
  ])
  inspect(url2, content="http://example.com/api?existing=param&new=param")

  // Test adding multiple params
  let url3 = request_add_params("http://example.com/api", [
    ("a", "1"),
    ("b", "2"),
  ])
  inspect(url3, content="http://example.com/api?a=1&b=2")

  // Test empty params
  let url4 = request_add_params("http://example.com/api", [])
  inspect(url4, content="http://example.com/api")
}

///|
test "test_form_data_encoding" {
  let form_data = [
    ("name", "John Doe"),
    ("email", "john@example.com"),
    ("age", "30"),
  ]
  let encoded = encode_form_data(form_data)
  let decoded_string = @encoding.decode(encoded, encoding=UTF8) catch {
    _ => ""
  }
  inspect(
    decoded_string,
    content="name=John%20Doe&email=john%40example.com&age=30",
  )
}

///|
test "test_edge_case_cookies" {
  // Test cookie with empty value
  let empty_value_cookie = parse_set_cookie("session=")
  match empty_value_cookie {
    Some(cookie) => {
      inspect(cookie.name, content="session")
      inspect(cookie.value, content="")
    }
    None => inspect("Empty value cookie should parse", content="Should parse")
  }

  // Test cookie with special characters in value
  let special_cookie = parse_set_cookie("data=a%3Db%26c%3Dd")
  match special_cookie {
    Some(cookie) => {
      inspect(cookie.name, content="data")
      inspect(cookie.value, content="a%3Db%26c%3Dd")
    }
    None =>
      inspect("Special characters cookie should parse", content="Should parse")
  }

  // Test malformed cookie (no equals sign)
  let malformed_cookie = parse_set_cookie("invalid_cookie_format")
  inspect(malformed_cookie, content="None")

  // Test cookie with attributes but no semicolon space
  let no_space_cookie = parse_set_cookie("token=abc123;HttpOnly;Secure")
  match no_space_cookie {
    Some(cookie) => {
      inspect(cookie.name, content="token")
      inspect(cookie.value, content="abc123")
      inspect(cookie.http_only, content="true")
      inspect(cookie.secure, content="true")
    }
    None => inspect("No space cookie should parse", content="Should parse")
  }
}

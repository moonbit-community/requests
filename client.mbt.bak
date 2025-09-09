///|
/// Request configuration options
pub struct RequestOptions {
  params : Query?
  headers : Headers?
  cookies : CookieJar?
  data : Form?
  json : Json?
  files : Files?
  auth : Auth?
  timeout : Timeout?
  allow_redirects : Bool?
  stream : Bool?
} derive(Show)

///|
/// Create default request options
pub fn RequestOptions::default() -> RequestOptions {
  RequestOptions::{
    params: None,
    headers: None,
    cookies: None,
    data: None,
    json: None,
    files: None,
    auth: None,
    timeout: None,
    allow_redirects: Some(true),
    stream: Some(false),
  }
}

///|
/// Internal response data from HTTP client
struct RawResponse {
  status_code : Int
  reason : String
  headers : Headers
  content : Bytes
}

///|
/// Perform an HTTP request
pub async fn request(
  method : Method,
  url : String,
  options : RequestOptions?,
) -> Response raise {
  let opts = match options {
    Some(opts) => opts
    None => RequestOptions::default()
  }

  // Parse the URL
  let parsed_url = parse_url(url) catch {
    _ => raise URLError("Invalid URL: " + url)
  }

  // Build the full URL with query parameters
  let full_url = build_request_url(url, opts.params)

  // Prepare headers
  let mut request_headers = prepare_headers(opts)

  // Prepare body and content type
  let (body, content_type) = prepare_body(opts)
  if content_type is Some(ct) {
    request_headers = add_header(request_headers, "Content-Type", ct)
  }

  // Add authentication
  if opts.auth is Some(auth) {
    request_headers = add_auth_header(request_headers, auth)
  }

  // Add cookies
  if opts.cookies is Some(jar) {
    match jar.to_header(parsed_url) {
      Some(cookie_header) =>
        request_headers = add_header(request_headers, "Cookie", cookie_header)
      None => ()
    }
  }

  // Handle redirects
  let max_redirects = match opts.allow_redirects {
    Some(true) => 30
    _ => 0
  }
  let mut redirect_count = 0
  let mut current_url = full_url
  let mut current_method = method
  let mut current_body = body
  let history = []
  for {
    // Make the HTTP request
    let raw_response = make_http_request(
      current_method,
      current_url,
      request_headers,
      current_body,
      opts.timeout,
    ) catch {
      _ => raise ConnectionError("Failed to connect to " + current_url)
    }

    // Create response object
    let response = Response::new(
      raw_response.status_code,
      raw_response.reason,
      raw_response.headers,
      raw_response.content,
      current_url,
    )

    // Handle cookies from response
    let response_cookies = CookieJar::new()
    let set_cookie_headers = get_all_headers(response.headers, "Set-Cookie")
    for set_cookie in set_cookie_headers {
      response_cookies.add_from_response(parsed_url, set_cookie)
    }
    response.cookies = response_cookies
    response.history = history

    // Check if this is a redirect
    if response.is_redirect() && redirect_count < max_redirects {
      match response.next_url() {
        Some(location) => {
          // Add current response to history (without body to save memory)
          history.push(response.without_content())

          // Resolve the redirect URL
          current_url = resolve_redirect_url(current_url, location) catch {
            _ => raise URLError("Failed to resolve redirect URL")
          }
          redirect_count = redirect_count + 1

          // For certain status codes, change method to GET and remove body
          if response.status_code == 301 ||
            response.status_code == 302 ||
            response.status_code == 303 {
            current_method = Method::Get
            current_body = b""
            request_headers = remove_content_headers(request_headers)
          }
          continue
        }
        None => return response
      }
    } else {
      return response
    }
  }
  raise RequestException("Too many redirects")
}

///|
/// Build request URL with query parameters
fn build_request_url(base_url : String, params : Query?) -> String {
  match params {
    Some(query_params) => append_query_params(base_url, query_params)
    None => base_url
  }
}

///|
/// Prepare request headers
fn prepare_headers(opts : RequestOptions) -> Headers {
  let mut headers = match opts.headers {
    Some(h) => h
    None => []
  }

  // Add default User-Agent if not provided
  if !has_header(headers, "User-Agent") {
    headers = add_header(headers, "User-Agent", "moonbit-requests/0.1.0")
  }
  headers
}

///|
/// Prepare request body and determine content type
fn prepare_body(opts : RequestOptions) -> (Bytes, String?) raise {
  // Priority: files > json > data
  if opts.files is Some(files) {
    let form_data = match opts.data {
      Some(data) => data
      None => []
    }
    let (content, content_type) = encode_multipart(form_data, files)
    (content, Some(content_type))
  } else if opts.json is Some(json_data) {
    let json_string = json_data.stringify()
    let content = @encoding.encode(json_string, encoding=UTF8)
    (content, Some("application/json"))
  } else if opts.data is Some(form_data) {
    let content = encode_form_data(form_data)
    (content, Some("application/x-www-form-urlencoded"))
  } else {
    (b"", None)
  }
}

///|
/// Encode form data as URL-encoded string
fn encode_form_data(data : Form) -> Bytes {
  let encoded_pairs = []
  for pair in data {
    let (key, value) = pair
    encoded_pairs.push(percent_encode(key) + "=" + percent_encode(value))
  }
  let form_string = encoded_pairs.join("&")
  @encoding.encode(form_string, encoding=UTF8)
}

///|
/// Add authentication header
fn add_auth_header(headers : Headers, auth : Auth) -> Headers {
  match auth {
    Basic(username, password) => {
      let credentials = username + ":" + password
      let encoded = base64_encode(credentials)
      add_header(headers, "Authorization", "Basic " + encoded)
    }
  }
}

///|
/// Simple base64 encoding
fn base64_encode(s : String) -> String {
  // This is a simplified implementation
  // In a real implementation, you would use a proper base64 library
  let bytes = @encoding.encode(s, encoding=UTF8)
  encode_base64_bytes(bytes)
}

///|
/// Encode bytes to base64 string  
fn encode_base64_bytes(bytes : Bytes) -> String {
  // Simplified base64 encoding
  let base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  let mut result = ""
  let mut i = 0
  while i < bytes.length() {
    let b1 = bytes[i].to_int()
    let b2 = if i + 1 < bytes.length() { bytes[i + 1].to_int() } else { 0 }
    let b3 = if i + 2 < bytes.length() { bytes[i + 2].to_int() } else { 0 }
    let combined = (b1 << 16) | (b2 << 8) | b3

    // Extract 6-bit values and convert to base64 characters
    let c1 = base64_chars[(combined >> 18) & 63]
    let c2 = base64_chars[(combined >> 12) & 63]
    let c3 = if i + 1 < bytes.length() {
      base64_chars[(combined >> 6) & 63]
    } else {
      '='
    }
    let c4 = if i + 2 < bytes.length() {
      base64_chars[combined & 63]
    } else {
      '='
    }

    // Build string from characters
    let mut chunk = ""
    chunk = chunk + c1.to_string()
    chunk = chunk + c2.to_string()
    chunk = chunk + c3.to_string()
    chunk = chunk + c4.to_string()
    result = result + chunk
    i = i + 3
  }
  result
}

///|
/// Make the actual HTTP request using the async HTTP client
async fn make_http_request(
  method : Method,
  url : String,
  headers : Headers,
  body : Bytes,
  timeout : Timeout?,
) -> RawResponse raise {
  // Convert headers to the format expected by @http
  let http_headers = []
  for header_pair in headers {
    let (name, value) = header_pair
    http_headers.push(
      @http.Header(
        @encoding.encode(name, encoding=UTF8),
        @encoding.encode(value, encoding=UTF8),
      ),
    )
  }

  // Make the request based on method
  let url_bytes = @encoding.encode(url, encoding=UTF8)
  let (response, response_body) = match method {
    Get => @http.get(url_bytes, headers=http_headers)
    Post => @http.post(url_bytes, body, headers=http_headers)
    Put => @http.put(url_bytes, body, headers=http_headers)
    Delete => {
      // DELETE not directly supported, use POST with override
      let delete_headers = http_headers
      delete_headers.push(
        @http.Header(
          @encoding.encode("X-HTTP-Method-Override", encoding=UTF8),
          @encoding.encode("DELETE", encoding=UTF8),
        ),
      )
      @http.post(url_bytes, body, headers=delete_headers)
    }
    Head =>
      // HEAD not directly supported, use GET and ignore body
      @http.get(url_bytes, headers=http_headers)
    Options => {
      // OPTIONS not directly supported, use POST with override
      let options_headers = http_headers
      options_headers.push(
        @http.Header(
          @encoding.encode("X-HTTP-Method-Override", encoding=UTF8),
          @encoding.encode("OPTIONS", encoding=UTF8),
        ),
      )
      @http.post(url_bytes, body, headers=options_headers)
    }
    Patch => {
      // PATCH not directly supported, use POST with override
      let patch_headers = http_headers
      patch_headers.push(
        @http.Header(
          @encoding.encode("X-HTTP-Method-Override", encoding=UTF8),
          @encoding.encode("PATCH", encoding=UTF8),
        ),
      )
      @http.post(url_bytes, body, headers=patch_headers)
    }
  }

  // Convert response headers back to our format
  let response_headers = []
  for header in response.headers {
    // Header is a tuple struct with (Bytes, Bytes)
    let @http.Header(name_bytes, value_bytes) = header
    let name = @encoding.decode(name_bytes, encoding=UTF8)
    let value = @encoding.decode(value_bytes, encoding=UTF8)
    response_headers.push((name, value))
  }
  RawResponse::{
    status_code: response.code,
    reason: match response.reason {
      Some(r) => @encoding.decode(r, encoding=UTF8)
      None => ""
    },
    headers: response_headers,
    content: response_body,
  }
}

///|
/// Resolve redirect URL (handle relative URLs)
fn resolve_redirect_url(base_url : String, location : String) -> String raise {
  if location.starts_with("http://") || location.starts_with("https://") {
    // Absolute URL
    location
  } else if location.starts_with("/") {
    // Absolute path
    let base_parsed = parse_url(base_url)
    base_parsed.scheme +
    "://" +
    base_parsed.host +
    (match base_parsed.port {
      Some(port) => ":" + port.to_string()
      None => ""
    }) +
    location
  } else {
    // Relative path
    match base_url.rev_find("/") {
      Some(pos) => base_url[0:pos + 1].to_string() + location
      None => base_url + "/" + location
    }
  }
}

///|
/// Utility functions for header manipulation
fn has_header(headers : Headers, name : String) -> Bool {
  let name_lower = name.to_lower()
  for header_pair in headers {
    let (key, _) = header_pair
    if key.to_lower() == name_lower {
      return true
    }
  }
  false
}

///|
fn add_header(headers : Headers, name : String, value : String) -> Headers {
  headers + [(name, value)]
}

///|
fn get_all_headers(headers : Headers, name : String) -> Array[String] {
  let name_lower = name.to_lower()
  let result = []
  for header_pair in headers {
    let (key, value) = header_pair
    if key.to_lower() == name_lower {
      result.push(value)
    }
  }
  result
}

///|
fn remove_content_headers(headers : Headers) -> Headers {
  let result = []
  for header_pair in headers {
    let (name, value) = header_pair
    let name_lower = name.to_lower()
    if name_lower != "content-type" && name_lower != "content-length" {
      result.push((name, value))
    }
  }
  result
}

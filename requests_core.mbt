///|
/// MoonBit Requests - A Python requests-like HTTP client library

///|
/// Request errors
pub suberror RequestError {
  HTTPError(Int, String, String) // status, reason, url
  ConnectionError(String)
  Timeout(String)
} derive(Show)

///|
/// HTTP Methods
pub enum Method {
  Get
  Post
  Put
  Delete
  Head
  Options
  Patch
} derive(Show, Eq)

///|
/// HTTP Response 
pub struct Response {
  status_code : Int
  reason : String
  headers : Array[(String, String)]
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
pub fn Response::json(self : Response) -> Json raise {
  let text = self.text()
  @json.parse(text)
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
    content: response_body,
    url,
  }
}

///|
/// Helper functions
fn convert_headers(headers : Array[(String, String)]) -> Array[@http.Header] {
  headers.map(fn {
    (name, value) =>
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
  headers.map(fn {
    @http.Header(name, value) =>
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
  let encoded_pairs = data.map(fn {
    (key, value) => url_encode(key) + "=" + url_encode(value)
  })
  @encoding.encode(encoded_pairs.join("&"), encoding=UTF8)
}

///|
fn url_encode(s : String) -> String {
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
    (n + '0'.to_int()).to_char().or('0')
  } else {
    (n - 10 + 'A'.to_int()).to_char().or('A')
  }
}

///|
fn request_add_params(url : String, params : Array[(String, String)]) -> String {
  if params.is_empty() {
    return url
  }
  let separator = if url.contains("?") { "&" } else { "?" }
  let query_parts = params.map(fn {
    (key, value) => url_encode(key) + "=" + url_encode(value)
  })
  url + separator + query_parts.join("&")
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

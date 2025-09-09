///|
/// HTTP Response structure - mirrors Python requests.Response
pub struct Response {
  /// HTTP status code (e.g., 200, 404, 500)
  pub status_code : Int
  /// HTTP status reason phrase (e.g., "OK", "Not Found")
  pub reason : String
  /// Response headers
  pub headers : Headers
  /// Cookies from the response
  pub mut cookies : CookieJar
  /// Final URL (after redirects)
  pub url : String
  /// Redirect history
  pub mut history : Array[Response]
  /// Response body content as bytes
  pub content : Bytes
  /// Encoding used for text() method
  pub encoding : String
  /// Whether this response was streamed
  pub stream : Bool
} derive(Show)

///|
/// Create a new Response
pub fn Response::new(
  status_code : Int,
  reason : String,
  headers : Headers,
  content : Bytes,
  url : String,
) -> Response {
  Response::{
    status_code,
    reason,
    headers,
    cookies: CookieJar::new(),
    url,
    history: [],
    content,
    encoding: "utf-8",
    stream: false,
  }
}

///|
/// Get response content as text (UTF-8 decoded)
pub fn Response::text(self : Response) -> String {
  match self.encoding.to_lower() {
    "utf-8" | "utf8" => @encoding.decode(self.content, encoding=UTF8)
    _ => @encoding.decode(self.content, encoding=UTF8) // Default to UTF-8
  }
}

///|
/// Parse response content as JSON
pub fn Response::json(self : Response) -> Json raise {
  let text = self.text()
  @json.parse(text) catch {
    _ => raise JSONError("Failed to parse response as JSON")
  }
}

///|
/// Iterate over response content in chunks
pub fn Response::iter_content(
  self : Response,
  chunk_size : Int,
) -> Iterator[Bytes] {
  let total_length = self.content.length()
  let mut offset = 0
  Iterator::from_fn(fn() -> Bytes? {
    if offset >= total_length {
      return None
    }
    let end = if offset + chunk_size > total_length {
      total_length
    } else {
      offset + chunk_size
    }
    let chunk = self.content[offset:end]
    offset = end
    Some(chunk)
  })
}

///|
/// Iterate over response content by lines
pub fn Response::iter_lines(
  self : Response,
  delimiter? : String = "\n",
) -> Iterator[String] {
  let text = self.text()
  let lines = text.split(delimiter)
  lines.iter()
}

///|
/// Raise an exception if the response status indicates an error (4xx or 5xx)
pub fn Response::raise_for_status(self : Response) -> Unit raise {
  if self.status_code >= 400 {
    raise HTTPError(self.status_code, self.reason, self.url)
  }
}

///|
/// Check if the response is OK (status code 2xx)
pub fn Response::ok(self : Response) -> Bool {
  self.status_code >= 200 && self.status_code < 300
}

///|
/// Get a header value (case-insensitive)
pub fn Response::get_header(self : Response, name : String) -> String? {
  let name_lower = name.to_lower()
  for header_pair in self.headers {
    let (key, value) = header_pair
    if key.to_lower() == name_lower {
      return Some(value)
    }
  }
  None
}

///|
/// Get all header values for a name (case-insensitive)
pub fn Response::get_headers(self : Response, name : String) -> Array[String] {
  let name_lower = name.to_lower()
  let result = []
  for header_pair in self.headers {
    let (key, value) = header_pair
    if key.to_lower() == name_lower {
      result.push(value)
    }
  }
  result
}

///|
/// Get the apparent encoding from Content-Type header
pub fn Response::apparent_encoding(self : Response) -> String {
  match self.get_header("Content-Type") {
    Some(content_type) =>
      // Look for charset parameter
      if content_type.find("charset=") is Some(pos) {
        let charset_start = pos + 8 // length of "charset="
        let charset_part = content_type[charset_start:]
        match charset_part.find(";") {
          Some(end) => charset_part[0:end].trim()
          None => charset_part.trim()
        }
      } else {
        "utf-8" // Default
      }
    None => "utf-8" // Default
  }
}

///|
/// Check if response appears to be an error based on status code
pub fn Response::is_error(self : Response) -> Bool {
  self.status_code >= 400
}

///|
/// Check if response is a redirect
pub fn Response::is_redirect(self : Response) -> Bool {
  self.status_code >= 300 && self.status_code < 400
}

///|
/// Get the next redirect URL from Location header
pub fn Response::next_url(self : Response) -> String? {
  if self.is_redirect() {
    self.get_header("Location")
  } else {
    None
  }
}

///|
/// Create a copy of the response without the body content (for history)
pub fn Response::without_content(self : Response) -> Response {
  Response::{
    status_code: self.status_code,
    reason: self.reason,
    headers: self.headers,
    cookies: self.cookies,
    url: self.url,
    history: self.history,
    content: b"",
    encoding: self.encoding,
    stream: self.stream,
  }
}

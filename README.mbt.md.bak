# MoonBit Requests Library

A Python requests-inspired HTTP client library for MoonBit, providing an elegant and simple HTTP interface for the MoonBit programming language.

## Features

- **Simple API**: Intuitive interface similar to Python's requests library
- **Async Support**: Built on MoonBit's async/await functionality
- **Session Management**: Persistent connections and cookie handling
- **Multiple Data Formats**: Support for JSON, form data, and multipart file uploads
- **Authentication**: Built-in support for Basic authentication
- **Error Handling**: Comprehensive error types and handling
- **Redirects**: Automatic redirect following with history tracking
- **Streaming**: Support for streaming large responses
- **Cookie Management**: Automatic cookie handling with domain/path support
- **Custom Headers**: Easy header management and manipulation

## Installation

Add the library to your MoonBit project:

```bash
moon add moonbitlang/requests
```

Make sure your `moon.mod.json` includes:

```json
{
  "preferred-target": "native",
  "deps": {
    "moonbitlang/requests": "0.1.0"
  }
}
```

## Quick Start

### Basic GET Request

```moonbit
import requests

fn main {
  @async.with_event_loop(fn(_) {
    try {
      let response = requests.get("https://httpbin.org/get", None, None, None, None, None, None)
      response.raise_for_status()
      println("Status: \{response.status_code}")
      println("Content: \{response.text()}")
    } catch {
      error => println("Error: \{error}")
    }
  })
}
```

### POST with JSON Data

```moonbit
let json_data = Json::object({
  "name": Json::string("MoonBit"),
  "version": Json::string("0.1.0")
})

let response = requests.post(
  "https://httpbin.org/post",
  None,           // data
  Some(json_data), // json
  None,           // files
  None,           // headers
  None,           // auth
  None,           // timeout
  None,           // allow_redirects
  None            // stream
)
```

## API Reference

### Making Requests

The library provides convenience functions for common HTTP methods:

- `get(url, params?, headers?, auth?, timeout?, allow_redirects?, stream?)`
- `post(url, data?, json?, files?, headers?, auth?, timeout?, allow_redirects?, stream?)`
- `put(url, data?, json?, files?, headers?, auth?, timeout?, allow_redirects?, stream?)`
- `delete(url, headers?, auth?, timeout?, allow_redirects?, stream?)`
- `head(url, params?, headers?, auth?, timeout?, allow_redirects?, stream?)`
- `options(url, headers?, auth?, timeout?, allow_redirects?, stream?)`
- `patch(url, data?, json?, files?, headers?, auth?, timeout?, allow_redirects?, stream?)`

### The Response Object

Response objects have the following properties and methods:

#### Properties
- `status_code: Int` - HTTP status code
- `reason: String` - HTTP status reason phrase
- `headers: Headers` - Response headers
- `cookies: CookieJar` - Response cookies
- `url: String` - Final URL (after redirects)
- `history: Array[Response]` - Redirect history
- `content: Bytes` - Raw response content

#### Methods
- `text() -> String` - Get response content as text
- `json() -> Json` - Parse response content as JSON
- `iter_content(chunk_size: Int) -> Iterator[Bytes]` - Iterate over content in chunks
- `iter_lines(delimiter?: String) -> Iterator[String]` - Iterate over content by lines
- `raise_for_status() -> Unit` - Raise exception for HTTP error status codes
- `ok() -> Bool` - Check if status code indicates success (2xx)
- `get_header(name: String) -> String?` - Get header value (case-insensitive)
- `get_headers(name: String) -> Array[String]` - Get all header values for name

### Sessions

Sessions allow you to persist certain parameters across requests and maintain cookies:

```moonbit
let session = Session::new()

// Set default headers
session.headers = [("User-Agent", "MyApp/1.0")]

// Set authentication
session.auth = Some(Auth::Basic("username", "password"))

// Make requests with the session
let response1 = session.get("https://example.com/login", None, None, None, None, None, None)
let response2 = session.get("https://example.com/profile", None, None, None, None, None, None)

session.close()
```

### Authentication

Currently supports Basic authentication:

```moonbit
let auth = Auth::Basic("username", "password")
let response = requests.get("https://httpbin.org/basic-auth/username/password", None, None, Some(auth), None, None, None)
```

### File Uploads

Upload files using multipart form data:

```moonbit
// Upload from bytes
let file_content = @encoding.encode("Hello, World!", encoding=UTF8)
let file_data = file_from_bytes("hello.txt", file_content, Some("text/plain"))
let files = [("file", file_data)]

let response = requests.post(
  "https://httpbin.org/post",
  None,        // data
  None,        // json
  Some(files), // files
  None,        // headers
  None,        // auth
  None,        // timeout
  None,        // allow_redirects
  None         // stream
)

// Upload from file path
let file_data = file_from_path("/path/to/file.pdf", None, None)
let files = [("document", file_data)]
```

### Error Handling

The library defines several error types:

```moonbit
try {
  let response = requests.get("https://httpbin.org/status/404", None, None, None, None, None, None)
  response.raise_for_status()
} catch {
  RequestError::HTTPError(code, reason, url) => {
    println("HTTP Error \{code}: \{reason}")
  }
  RequestError::Timeout(message) => {
    println("Request timed out: \{message}")
  }
  RequestError::ConnectionError(message) => {
    println("Connection failed: \{message}")
  }
  RequestError::JSONError(message) => {
    println("JSON parsing failed: \{message}")
  }
  error => println("Other error: \{error}")
}
```

### Timeouts

Configure request timeouts:

```moonbit
// Total timeout
let timeout = Timeout::Total(5000) // 5 seconds

// Separate connect and read timeouts
let timeout = Timeout::Detailed(2000, 10000) // 2s connect, 10s read

let response = requests.get("https://example.com", None, None, None, Some(timeout), None, None)
```

### Streaming

Process large responses in chunks:

```moonbit
let response = requests.get("https://example.com/large-file", None, None, None, None, None, Some(true))

for chunk in response.iter_content(8192) {
  // Process chunk
  process_chunk(chunk)
}
```

### Custom Headers

Add custom headers to requests:

```moonbit
let headers = [
  ("User-Agent", "MyApp/1.0"),
  ("Accept", "application/json"),
  ("Authorization", "Bearer token123")
]

let response = requests.get("https://api.example.com/data", None, Some(headers), None, None, None, None)
```

### Query Parameters

Add query parameters to URLs:

```moonbit
let params = [
  ("q", "moonbit"),
  ("sort", "date"),
  ("limit", "10")
]

let response = requests.get("https://api.example.com/search", Some(params), None, None, None, None, None)
// Results in: https://api.example.com/search?q=moonbit&sort=date&limit=10
```

## Advanced Usage

### Cookie Management

Manual cookie management:

```moonbit
let cookie_jar = CookieJar::new()
let cookie = Cookie::new("session_id", "abc123")
cookie_jar.set(cookie)

let options = RequestOptions::{
  params: None,
  headers: None,
  cookies: Some(cookie_jar),
  data: None,
  json: None,
  files: None,
  auth: None,
  timeout: None,
  allow_redirects: None,
  stream: None,
}

let response = requests.request(Method::Get, "https://example.com", Some(options))
```

### Redirect Control

Control redirect behavior:

```moonbit
// Follow redirects (default)
let response = requests.get("https://httpbin.org/redirect/3", None, None, None, None, Some(true), None)

// Don't follow redirects
let response = requests.get("https://httpbin.org/redirect/1", None, None, None, None, Some(false), None)
if response.is_redirect() {
  match response.next_url() {
    Some(location) => println("Redirects to: \{location}")
    None => println("No redirect location")
  }
}
```

## Error Types

The library defines the following error types:

- `HTTPError(code, reason, url)` - HTTP error responses (4xx, 5xx)
- `Timeout(message)` - Request timeout
- `ConnectionError(message)` - Network connection issues
- `JSONError(message)` - JSON parsing failures
- `URLError(message)` - Invalid URL format
- `RequestException(message)` - General request errors

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is licensed under the Apache 2.0 License.

## Compatibility

This library requires:
- MoonBit with async support
- Native target compilation
- `moonbitlang/async` dependency
- `tonyfettes/encoding` dependency

## Examples

See the `examples.mbt` file for more comprehensive usage examples including:
- Basic requests
- Authentication
- File uploads
- Session usage
- Error handling
- Streaming
- Cookie management

## Differences from Python Requests

While this library is inspired by Python requests, there are some differences due to MoonBit's type system and async model:

1. **Async by default**: All requests are async and must be called within an event loop
2. **Explicit error handling**: Uses MoonBit's error handling instead of exceptions
3. **Type safety**: Strong typing for all parameters and return values
4. **Optional parameters**: Uses MoonBit's `Option` type for optional parameters
5. **Memory safety**: Automatic memory management without manual cleanup

## Performance Notes

- The library is built on MoonBit's async foundation for good performance
- Sessions reuse connections and maintain cookies automatically
- Streaming support helps with memory usage for large responses
- Connection pooling and keep-alive are handled by the underlying HTTP client

## Future Enhancements

Planned features for future versions:
- Support for more authentication methods (OAuth, etc.)
- HTTP/2 support
- Compression support (gzip, deflate)
- Proxy support
- Certificate verification options
- Connection pooling configuration
- Request/response middleware
- Progress callbacks for uploads/downloads
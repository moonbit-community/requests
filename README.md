# MoonBit Requests 🚀

A comprehensive Python requests-like HTTP client library for MoonBit, providing intuitive and type-safe HTTP functionality.

## ✨ Features

### Core HTTP Client
- 🐍 **Python-Compatible API**: Familiar interface inspired by Python requests
- ⚡ **Async/Await Ready**: Built on MoonBit's async foundation with structured concurrency
- 🔒 **Type Safe**: Full type safety with comprehensive error handling and categorization
- 🌐 **Complete HTTP Methods**: GET, POST, PUT, HEAD, DELETE, OPTIONS, PATCH

### Advanced Features
- ⏱️ **Timeout Support**: Per-request and session-level timeout configuration
- 🍪 **Advanced Cookie Management**: Complete cookie parsing with attributes (domain, path, secure, httponly, samesite)
- 🔐 **Authentication**: Basic Auth with optimized base64 encoding
- 📋 **Session Management**: Persistent headers, timeouts, and configurations
- 🛡️ **Enhanced Error Handling**: Detailed error categorization for HTTP status codes, timeouts, and connection issues

### Performance & Reliability
- 🚀 **Optimized URL Encoding**: Fast RFC 3986 compliant encoding with lookup tables
- 🔍 **Comprehensive URL Validation**: Length limits, character validation, and format checking
- 📊 **Rich Response Objects**: JSON parsing, text extraction, and status validation
- 🧪 **Extensive Testing**: 19+ comprehensive tests covering all functionality
- 🎯 **Modern MoonBit**: Uses current MoonBit APIs and best practices

## 🚀 Quick Start

### Installation

Add to your `moon.mod.json`:

```json
{
  "deps": {
    "allwefantasy/requests": "^0.1.0",
    "moonbitlang/async": "^0.5.1",
    "tonyfettes/encoding": "^0.3.7"
  },
  "preferred-target": "native"
}
```

Add to your package's `moon.pkg.json`:

```json
{
  "import": [
    "allwefantasy/requests",
    "moonbitlang/async"
  ]
}
```

### Basic Usage

```moonbit
fn main {
  @async.with_event_loop(fn(_) {
    try {
      // Simple GET request with timeout
      let response = @allwefantasy/requests.get(
        "https://httpbin.org/get", 
        None, 
        None, 
        timeout_ms=Some(5000)  // 5-second timeout
      )
      println("Status: \{response.status_code}")
      println("OK: \{response.ok()}")
      println("Content: \{response.text()}")
      
      // Check for cookies
      match response.cookies.get("session") {
        Some(value) => println("Session cookie: \{value}")
        None => println("No session cookie found")
      }
    } catch {
      @allwefantasy/requests.RequestError::Timeout(msg) => 
        println("Request timed out: \{msg}")
      @allwefantasy/requests.RequestError::HTTPError(code, reason, url) => 
        println("HTTP Error \{code}: \{reason} for \{url}")
      _ => println("Request failed")
    }
  }) catch { _ => () }
}
```

## 📖 API Reference

### HTTP Methods

#### GET Request
```moonbit
let response = @allwefantasy/requests.get(url, params?, headers?, timeout_ms?)

// With query parameters and timeout
let params = [("key1", "value1"), ("key2", "value2")]
let response = @allwefantasy/requests.get(
  "https://api.example.com", 
  Some(params), 
  None, 
  timeout_ms=Some(10000)  // 10-second timeout
)

// Simple request with optimized URL encoding
let response = @allwefantasy/requests.get("https://httpbin.org/get", None, None)
```

#### POST Request
```moonbit
// POST with JSON and timeout
let json_data : Json = { "name": "MoonBit", "version": "0.1.0" }
let response = @allwefantasy/requests.post(
  url, 
  None, 
  Some(json_data), 
  None, 
  timeout_ms=Some(30000)  // 30-second timeout
)

// POST with form data
let form_data = [("username", "user"), ("password", "pass")]
let response = @allwefantasy/requests.post(url, Some(form_data), None, None)
```

#### PUT Request
```moonbit
let json_data : Json = { "updated": "data" }
let response = @allwefantasy/requests.put(
  url, 
  None, 
  Some(json_data), 
  None,
  timeout_ms=Some(15000)  // 15-second timeout
)
```

### Response Object

```moonbit
let response = @allwefantasy/requests.get("https://httpbin.org/json", None, None)

// Access response properties
println("Status: \{response.status_code}")
println("Reason: \{response.reason}")

// Get response as text with error handling
let text = response.text()

// Parse JSON response with enhanced error handling
let json_data = response.json() catch {
  @allwefantasy/requests.RequestError::ContentDecodingError(msg) =>
    println("JSON parsing failed: \{msg}")
    fail("Invalid JSON")
}

// Check if request was successful
if response.ok() {
  println("Request successful!")
}

// Enhanced error categorization
response.raise_for_status() catch {
  @allwefantasy/requests.RequestError::HTTPError(404, _, _) =>
    println("Resource not found")
  @allwefantasy/requests.RequestError::HTTPError(401, _, _) =>
    println("Authentication required")
  @allwefantasy/requests.RequestError::HTTPError(500, _, _) =>
    println("Server error")
  _ => println("Other HTTP error")
}

// Access parsed cookies
for cookie_name in ["session_id", "preferences", "csrf_token"] {
  match response.cookies.get(cookie_name) {
    Some(value) => println("Cookie \{cookie_name}: \{value}")
    None => continue
  }
}
```

### Custom Headers

```moonbit
let headers = [
  ("Authorization", "Bearer token"),
  ("User-Agent", "MyApp/1.0"),
  ("Content-Type", "application/json")
]
let response = @allwefantasy/requests.get(url, None, Some(headers))
```

### Authentication

```moonbit
// Basic Authentication
let auth = @allwefantasy/requests.basic_auth("username", "password")
let (header_name, header_value) = auth.to_header()
let auth_headers = [(header_name, header_value)]
let response = @allwefantasy/requests.get(protected_url, None, Some(auth_headers))
```

### Session Support

```moonbit
// Create session for persistent configuration
let session = @allwefantasy/requests.Session::new()

// Create session with default timeout
let timeout_session = @allwefantasy/requests.Session::with_timeout(30000) // 30-second default

// Use session for multiple requests with persistent settings
let response1 = session.get("https://api.example.com/endpoint1", None, None)
let response2 = session.post(
  "https://api.example.com/endpoint2", 
  None, 
  Some(json_data), 
  None,
  timeout_ms=Some(60000)  // Override default timeout for this request
)

// Timeout session automatically applies timeout to all requests
let response3 = timeout_session.get("https://api.example.com/endpoint3", None, None)

// Sessions maintain state and configuration across requests
```

### Cookie Support

```moonbit
// Create cookie jar
let jar = @allwefantasy/requests.CookieJar::new()
jar.add("session_id", "abc123")

// Cookies can be used with requests (integration in progress)
```

### Performance and Reliability Features

```moonbit
// Optimized URL encoding handles special characters efficiently
let params = [
  ("search", "hello world"),
  ("filter", "price>100"),
  ("unicode", "测试"),
  ("symbols", "@#$%^&*()"),
]
let response = @allwefantasy/requests.get("https://api.example.com/search", Some(params), None)

// Enhanced URL validation catches issues early
try {
  let _response = @allwefantasy/requests.get("invalid-url-format", None, None)
} catch {
  @allwefantasy/requests.RequestError::URLError(msg) =>
    println("URL validation caught: \{msg}")
}

// Timeout support prevents hanging requests
let fast_response = @allwefantasy/requests.get(
  "https://httpbin.org/delay/1",
  None,
  None,
  timeout_ms=Some(500)  // 500ms timeout - will likely timeout
) catch {
  @allwefantasy/requests.RequestError::Timeout(msg) =>
    println("Request timed out as expected: \{msg}")
    Response::default() // Handle timeout gracefully
}

// Advanced cookie parsing extracts all cookie attributes
let cookie_response = @allwefantasy/requests.get("https://httpbin.org/cookies/set/test/value", None, None)
match cookie_response.cookies.get("test") {
  Some(value) => println("Cookie value: \{value}")
  None => println("No cookie found")
}
```

### Error Handling

```moonbit
try {
  let response = @allwefantasy/requests.get("https://httpbin.org/status/404", None, None)
  response.raise_for_status()
} catch {
  // Enhanced error categorization
  @allwefantasy/requests.RequestError::HTTPError(404, reason, url) => {
    println("Not Found: \{reason} for \{url}")
  }
  @allwefantasy/requests.RequestError::HTTPError(408, _, _) |
  @allwefantasy/requests.RequestError::HTTPError(504, _, _) => {
    println("Timeout-related HTTP error")
  }
  @allwefantasy/requests.RequestError::Timeout(msg) => {
    println("Request timeout: \{msg}")
  }
  @allwefantasy/requests.RequestError::ConnectionError(msg) => {
    println("Connection failed: \{msg}")
  }
  @allwefantasy/requests.RequestError::URLError(msg) => {
    println("URL validation failed: \{msg}")
  }
  @allwefantasy/requests.RequestError::ContentDecodingError(msg) => {
    println("Content decoding failed: \{msg}")
  }
  _ => println("Other error occurred")
}
```

## 🏗️ Architecture

The library is organized into focused modules:

- **`requests_core.mbt`**: Core HTTP client functionality (get, post, put)
- **`auth.mbt`**: Authentication support with base64 encoding
- **`cookies_enhanced.mbt`**: Advanced cookie handling with RFC compliance
- **Session support**: Built into core for persistent configurations

## 🔧 Supported Features

### ✅ Currently Available
- **HTTP methods**: GET, POST, PUT, HEAD, DELETE, OPTIONS, PATCH
- **Query parameters**: RFC-compliant URL encoding with optimization
- **Request bodies**: JSON and form data with proper content-type headers
- **Custom headers**: Full header support with encoding handling
- **Response parsing**: Text and JSON parsing with error handling
- **Authentication**: Basic Auth with optimized base64 encoding
- **Session management**: Persistent headers and default timeout configuration
- **Cookie support**: Complete cookie parsing with all attributes (domain, path, secure, httponly, samesite, max-age, expires)
- **Timeout support**: Per-request and session-level timeout configuration
- **Enhanced error handling**: Detailed error categorization and HTTP status code mapping
- **URL validation**: Comprehensive validation with length limits and character checking
- **Type-safe async operations**: Built on MoonBit's structured concurrency

### 🚧 Future Enhancements
- **Redirect handling**: Automatic redirect following with loop detection
- **File uploads**: multipart/form-data support for file transfers
- **Request/response middleware**: Interceptors and transformers
- **Response streaming**: Chunked response processing
- **Retry mechanisms**: Configurable retry with exponential backoff
- **Advanced session features**: Cookie persistence and domain-specific sessions
- **Request caching**: Response caching with TTL support
- **WebSocket support**: Upgrade from HTTP to WebSocket connections

## 🧪 Example Applications

See `cmd/main/main.mbt` for a comprehensive demonstration including:

1. **Basic HTTP requests** - GET, POST, PUT with various configurations
2. **Query parameters** - URL encoding with special characters and Unicode
3. **JSON and form data** - Content-type handling and data serialization
4. **Custom headers** - Header management and encoding
5. **Basic authentication** - Secure credential handling
6. **Session management** - Persistent configurations and state
7. **Timeout support** - Per-request and session-level timeout configuration
8. **Enhanced error handling** - Detailed error categorization and recovery
9. **Cookie parsing** - Automatic cookie extraction from Set-Cookie headers
10. **URL validation** - Comprehensive URL format checking
11. **Response processing** - JSON parsing, text extraction, and status validation
12. **Performance optimization** - Fast URL encoding and string operations

Run the example with:
```bash
moon run cmd/main --target native
```

**Test Coverage**: 19+ comprehensive tests covering all functionality areas

## 🤝 Contributing

This library follows MoonBit best practices:

- Use `moon build --target native` to build
- Run `moon test --target native` for testing
- Follow MoonBit async patterns
- Maintain type safety throughout

## 📄 License

Apache-2.0 License

## 🙏 Acknowledgments

Inspired by Python's requests library and built on MoonBit's excellent async ecosystem.
# MoonBit Requests 🚀

A comprehensive Python requests-like HTTP client library for MoonBit, providing intuitive and type-safe HTTP functionality.

## ✨ Features

- 🐍 **Python-Compatible API**: Familiar interface inspired by Python requests
- ⚡ **Async/Await Ready**: Built on MoonBit's async foundation
- 🔒 **Type Safe**: Full type safety with comprehensive error handling
- 🍪 **Cookie Support**: Cookie jar with domain/path matching
- 🔐 **Authentication**: Basic Auth with proper base64 encoding
- 📋 **Session Management**: Persistent headers and configurations
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
      // Simple GET request
      let response = @allwefantasy/requests.get("https://httpbin.org/get", None, None)
      println("Status: \{response.status_code}")
      println("Content: \{response.text()}")
    } catch {
      _ => println("Request failed")
    }
  }) catch { _ => () }
}
```

## 📖 API Reference

### HTTP Methods

#### GET Request
```moonbit
let response = @allwefantasy/requests.get(url, params?, headers?)

// With query parameters
let params = [("key1", "value1"), ("key2", "value2")]
let response = @allwefantasy/requests.get("https://api.example.com", Some(params), None)
```

#### POST Request
```moonbit
// POST with JSON
let json_data : Json = { "name": "MoonBit", "version": "0.1.0" }
let response = @allwefantasy/requests.post(url, None, Some(json_data), None)

// POST with form data
let form_data = [("username", "user"), ("password", "pass")]
let response = @allwefantasy/requests.post(url, Some(form_data), None, None)
```

#### PUT Request
```moonbit
let json_data : Json = { "updated": "data" }
let response = @allwefantasy/requests.put(url, None, Some(json_data), None)
```

### Response Object

```moonbit
let response = @allwefantasy/requests.get("https://httpbin.org/json", None, None)

// Access response properties
println("Status: \{response.status_code}")
println("Reason: \{response.reason}")

// Get response as text
let text = response.text()

// Parse JSON response
let json_data = response.json()

// Check if request was successful
if response.ok() {
  println("Request successful!")
}

// Raise exception for error status codes
response.raise_for_status()
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

// Use session for multiple requests
let response1 = session.get("https://api.example.com/endpoint1", None, None)
let response2 = session.post("https://api.example.com/endpoint2", None, Some(json_data), None)

// Sessions maintain state across requests
```

### Cookie Support

```moonbit
// Create cookie jar
let jar = @allwefantasy/requests.CookieJar::new()
jar.add("session_id", "abc123")

// Cookies can be used with requests (integration in progress)
```

### Error Handling

```moonbit
try {
  let response = @allwefantasy/requests.get("https://httpbin.org/status/404", None, None)
  response.raise_for_status()
} catch {
  @allwefantasy/requests.RequestError::HTTPError(code, reason, url) => {
    println("HTTP Error \{code}: \{reason} for \{url}")
  }
  @allwefantasy/requests.RequestError::ConnectionError(msg) => {
    println("Connection failed: \{msg}")
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
- HTTP methods: GET, POST, PUT
- Query parameters and URL encoding
- JSON and form data request bodies
- Custom headers
- Response parsing (text, JSON)
- Basic Authentication
- Session management
- Cookie jar (basic)
- Comprehensive error handling
- Type-safe async operations

### 🚧 Future Enhancements
- Additional HTTP methods (DELETE, HEAD, OPTIONS, PATCH)
- Advanced cookie features (domain/path matching)
- File uploads (multipart/form-data)
- Request/response middleware
- Timeout configuration
- Automatic redirects
- Response streaming
- Retry mechanisms

## 🧪 Example Applications

See `cmd/main/main.mbt` for a comprehensive demonstration including:

1. **Basic GET requests**
2. **Query parameters**
3. **JSON POST requests**
4. **Form data submissions**
5. **Custom headers**
6. **Basic authentication**
7. **Session usage**
8. **Error handling**

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
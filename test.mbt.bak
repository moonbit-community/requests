///|
/// Test URL parsing functionality
test "url_parsing" {
  let url = parse_url("https://example.com:8080/path?query=value#fragment")
  
  assert_eq(url.scheme, "https")
  assert_eq(url.host, "example.com")
  assert_eq(url.port, Some(8080))
  assert_eq(url.path, "/path")
  assert_eq(url.query, Some("query=value"))
  assert_eq(url.fragment, Some("fragment"))
}

///|
/// Test URL encoding
test "url_encoding" {
  let encoded = percent_encode("hello world!")
  assert_eq(encoded, "hello%20world%21")
  
  let query_encoded = encode_query_params([("q", "hello world"), ("type", "test")])
  assert_eq(query_encoded, "q=hello%20world&type=test")
}

///|
/// Test cookie creation and management
test "cookie_management" {
  let jar = CookieJar::new()
  let cookie = Cookie::new("test", "value")
  jar.set(cookie)
  
  let url = parse_url("https://example.com")
  let cookie_header = jar.to_header(url)
  
  match cookie_header {
    Some(header) => assert_eq(header, "test=value")
    None => assert_true(false) // Should have cookie
  }
}

///|
/// Test cookie parsing from Set-Cookie header
test "set_cookie_parsing" {
  let jar = CookieJar::new()
  let url = parse_url("https://example.com")
  
  jar.add_from_response(url, "sessionid=abc123; Path=/; HttpOnly")
  
  let cookies = jar.get_for_url(url)
  assert_eq(cookies.length(), 1)
  assert_eq(cookies[0].name, "sessionid")
  assert_eq(cookies[0].value, "abc123")
  assert_eq(cookies[0].path, "/")
  assert_true(cookies[0].http_only)
}

///|
/// Test response creation and methods
test "response_methods" {
  let headers = [("Content-Type", "application/json")]
  let content = @encoding.encode("{\"hello\": \"world\"}", encoding=UTF8)
  
  let response = Response::new(200, "OK", headers, content, "https://example.com")
  
  assert_true(response.ok())
  assert_false(response.is_error())
  assert_false(response.is_redirect())
  
  let text = response.text()
  assert_eq(text, "{\"hello\": \"world\"}")
  
  match response.get_header("Content-Type") {
    Some(ct) => assert_eq(ct, "application/json")
    None => assert_true(false)
  }
  
  match response.get_header("content-type") { // Case insensitive
    Some(ct) => assert_eq(ct, "application/json")
    None => assert_true(false)
  }
}

///|
/// Test response JSON parsing
test "response_json" {
  let content = @encoding.encode("{\"name\": \"MoonBit\", \"version\": \"0.1.0\"}", encoding=UTF8)
  let response = Response::new(200, "OK", [], content, "https://example.com")
  
  try {
    let json = response.json()
    match json {
      Json::Object(obj) => {
        assert_eq(obj.get("name"), Some(Json::String("MoonBit")))
        assert_eq(obj.get("version"), Some(Json::String("0.1.0")))
      }
      _ => assert_true(false) // Should be object
    }
  } catch {
    _ => assert_true(false) // Should not error
  }
}

///|
/// Test response content iteration
test "response_iteration" {
  let content = @encoding.encode("Hello, World! This is a test content.", encoding=UTF8)
  let response = Response::new(200, "OK", [], content, "https://example.com")
  
  let mut total_bytes = 0
  let mut chunk_count = 0
  
  for chunk in response.iter_content(10) {
    total_bytes = total_bytes + chunk.length()
    chunk_count = chunk_count + 1
  }
  
  assert_eq(total_bytes, content.length())
  assert_true(chunk_count > 1) // Should be multiple chunks
}

///|
/// Test multipart encoding
test "multipart_encoding" {
  let form_data = [("field1", "value1"), ("field2", "value2")]
  let file_content = @encoding.encode("test file content", encoding=UTF8)
  let file_data = file_from_bytes("test.txt", file_content, Some("text/plain"))
  let files = [("file", file_data)]
  
  try {
    let (content, content_type) = encode_multipart(form_data, files)
    
    assert_true(content_type.starts_with("multipart/form-data; boundary="))
    assert_true(content.length() > 0)
    
    let content_str = @encoding.decode(content, encoding=UTF8)
    assert_true(content_str.contains("field1"))
    assert_true(content_str.contains("value1"))
    assert_true(content_str.contains("test file content"))
    assert_true(content_str.contains("filename=\"test.txt\""))
  } catch {
    error => {
      println("Multipart encoding error: \{error}")
      assert_true(false)
    }
  }
}

///|
/// Test content type guessing
test "content_type_guessing" {
  assert_eq(guess_content_type("document.pdf"), "application/pdf")
  assert_eq(guess_content_type("image.jpg"), "image/jpeg")
  assert_eq(guess_content_type("image.png"), "image/png")
  assert_eq(guess_content_type("data.json"), "application/json")
  assert_eq(guess_content_type("style.css"), "text/css")
  assert_eq(guess_content_type("script.js"), "application/javascript")
  assert_eq(guess_content_type("unknown.xyz"), "application/octet-stream")
}

///|
/// Test request options creation
test "request_options" {
  let options = RequestOptions::default()
  
  assert_eq(options.params, None)
  assert_eq(options.headers, None)
  assert_eq(options.data, None)
  assert_eq(options.json, None)
  assert_eq(options.files, None)
  assert_eq(options.auth, None)
  assert_eq(options.timeout, None)
  assert_eq(options.allow_redirects, Some(true))
  assert_eq(options.stream, Some(false))
}

///|
/// Test session creation and configuration
test "session_creation" {
  let session = Session::new()
  
  assert_eq(session.headers.length(), 0)
  assert_eq(session.auth, None)
  assert_eq(session.timeout, None)
  assert_true(session.allow_redirects)
  assert_false(session.stream)
  
  // Test session configuration
  session.headers = [("User-Agent", "TestAgent/1.0")]
  session.auth = Some(Auth::Basic("user", "pass"))
  session.allow_redirects = false
  
  assert_eq(session.headers.length(), 1)
  assert_eq(session.headers[0].0, "User-Agent")
  assert_eq(session.headers[0].1, "TestAgent/1.0")
  
  match session.auth {
    Some(Auth::Basic(user, pass)) => {
      assert_eq(user, "user")
      assert_eq(pass, "pass")
    }
    _ => assert_true(false)
  }
  
  assert_false(session.allow_redirects)
}

///|
/// Test error handling and types
test "error_types" {
  let http_error = http_error(404, "Not Found", "https://example.com")
  let timeout_error = timeout_error("Request timed out")
  let conn_error = connection_error("Connection refused")
  let json_error = json_error("Invalid JSON")
  
  match http_error {
    RequestError::HTTPError(code, reason, url) => {
      assert_eq(code, 404)
      assert_eq(reason, "Not Found")
      assert_eq(url, "https://example.com")
    }
    _ => assert_true(false)
  }
  
  match timeout_error {
    RequestError::Timeout(msg) => assert_eq(msg, "Request timed out")
    _ => assert_true(false)
  }
  
  match conn_error {
    RequestError::ConnectionError(msg) => assert_eq(msg, "Connection refused")
    _ => assert_true(false)
  }
  
  match json_error {
    RequestError::JSONError(msg) => assert_eq(msg, "Invalid JSON")
    _ => assert_true(false)
  }
}
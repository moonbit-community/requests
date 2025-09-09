///|
/// Example: Basic GET request
test "basic_get_request" {
  @async.with_event_loop(fn(_) {
    try {
      let response = get("https://httpbin.org/get", None, None, None, None, None, None)
      response.raise_for_status()
      assert_true(response.ok())
      println("Response status: \{response.status_code}")
      println("Response text: \{response.text()}")
    } catch {
      RequestError::HTTPError(code, reason, url) => {
        println("HTTP Error \{code}: \{reason} for \{url}")
      }
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: GET request with query parameters
test "get_with_params" {
  @async.with_event_loop(fn(_) {
    try {
      let params = [("q", "moonbit"), ("lang", "en")]
      let response = get("https://httpbin.org/get", Some(params), None, None, None, None, None)
      response.raise_for_status()
      println("URL with params: \{response.url}")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: POST request with JSON data
test "post_json" {
  @async.with_event_loop(fn(_) {
    try {
      let json_data = Json::object({
        "name": Json::string("MoonBit"),
        "version": Json::string("0.1.0"),
        "features": Json::array([
          Json::string("async"),
          Json::string("http")
        ])
      })
      
      let response = post(
        "https://httpbin.org/post",
        None, // data
        Some(json_data), // json
        None, // files
        None, // headers
        None, // auth
        None, // timeout
        None, // allow_redirects
        None  // stream
      )
      
      response.raise_for_status()
      let response_json = response.json()
      println("Posted JSON successfully: \{response_json.stringify()}")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: POST request with form data
test "post_form_data" {
  @async.with_event_loop(fn(_) {
    try {
      let form_data = [
        ("username", "testuser"),
        ("email", "test@example.com"),
        ("message", "Hello from MoonBit!")
      ]
      
      let response = post(
        "https://httpbin.org/post",
        Some(form_data), // data
        None, // json
        None, // files
        None, // headers
        None, // auth
        None, // timeout
        None, // allow_redirects
        None  // stream
      )
      
      response.raise_for_status()
      println("Form data posted successfully")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: Request with custom headers
test "request_with_headers" {
  @async.with_event_loop(fn(_) {
    try {
      let headers = [
        ("User-Agent", "MoonBit-Requests/0.1.0"),
        ("Accept", "application/json"),
        ("X-Custom-Header", "custom-value")
      ]
      
      let response = get("https://httpbin.org/headers", None, Some(headers), None, None, None, None)
      response.raise_for_status()
      println("Headers sent successfully")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: Basic authentication
test "basic_auth" {
  @async.with_event_loop(fn(_) {
    try {
      let auth = Auth::Basic("testuser", "testpass")
      let response = get("https://httpbin.org/basic-auth/testuser/testpass", None, None, Some(auth), None, None, None)
      response.raise_for_status()
      println("Basic auth successful")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: Session usage for persistent cookies
test "session_usage" {
  @async.with_event_loop(fn(_) {
    try {
      let session = Session::new()
      
      // Set a custom header for the session
      session.headers = [("User-Agent", "MoonBit-Session/0.1.0")]
      
      // First request - this might set cookies
      let response1 = session.get("https://httpbin.org/cookies/set/sessionid/12345", None, None, None, None, None, None)
      response1.raise_for_status()
      println("Session cookie set")
      
      // Second request - cookies should be automatically included
      let response2 = session.get("https://httpbin.org/cookies", None, None, None, None, None, None)
      response2.raise_for_status()
      println("Session cookies: \{response2.text()}")
      
      session.close()
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: File upload using multipart
test "file_upload" {
  @async.with_event_loop(fn(_) {
    try {
      // Create test file content
      let file_content = @encoding.encode("Hello from MoonBit file upload!", encoding=UTF8)
      let file_data = file_from_bytes("test.txt", file_content, Some("text/plain"))
      
      let files = [("file", file_data)]
      let form_data = [("description", "Test file upload from MoonBit")]
      
      let response = post(
        "https://httpbin.org/post",
        Some(form_data), // data
        None, // json
        Some(files), // files
        None, // headers
        None, // auth
        None, // timeout
        None, // allow_redirects
        None  // stream
      )
      
      response.raise_for_status()
      println("File upload successful")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: Handling different response formats
test "response_formats" {
  @async.with_event_loop(fn(_) {
    try {
      // JSON response
      let json_response = get("https://httpbin.org/json", None, None, None, None, None, None)
      json_response.raise_for_status()
      let json_data = json_response.json()
      println("JSON response keys: \{json_data.stringify()}")
      
      // Plain text response
      let text_response = get("https://httpbin.org/get", None, None, None, None, None, None)
      text_response.raise_for_status()
      let text_content = text_response.text()
      println("Text response length: \{text_content.length()}")
      
      // Access response headers
      match text_response.get_header("Content-Type") {
        Some(content_type) => println("Content-Type: \{content_type}")
        None => println("No Content-Type header found")
      }
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: Error handling
test "error_handling" {
  @async.with_event_loop(fn(_) {
    try {
      // This should return a 404 error
      let response = get("https://httpbin.org/status/404", None, None, None, None, None, None)
      response.raise_for_status() // This will throw an error
    } catch {
      RequestError::HTTPError(code, reason, url) => {
        println("Expected HTTP error: \{code} \{reason}")
        assert_eq(code, 404)
      }
      error => {
        println("Unexpected error: \{error}")
        assert_true(false) // Should not reach here
      }
    }
  })
}

///|
/// Example: Stream processing (iterating over response content)
test "stream_processing" {
  @async.with_event_loop(fn(_) {
    try {
      let response = get("https://httpbin.org/get", None, None, None, None, None, Some(true))
      response.raise_for_status()
      
      let mut total_bytes = 0
      for chunk in response.iter_content(1024) {
        total_bytes = total_bytes + chunk.length()
      }
      
      println("Streamed \{total_bytes} bytes total")
      assert_true(total_bytes > 0)
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: Timeout handling
test "timeout_example" {
  @async.with_event_loop(fn(_) {
    try {
      let timeout = Timeout::Total(5000) // 5 seconds
      let response = get("https://httpbin.org/delay/1", None, None, None, Some(timeout), None, None)
      response.raise_for_status()
      println("Request completed within timeout")
    } catch {
      RequestError::Timeout(msg) => println("Request timed out: \{msg}")
      error => println("Other error: \{error}")
    }
  })
}

///|
/// Example: Redirect handling
test "redirect_example" {
  @async.with_event_loop(fn(_) {
    try {
      // This URL redirects to another page
      let response = get("https://httpbin.org/redirect/3", None, None, None, None, Some(true), None)
      response.raise_for_status()
      
      println("Final URL after redirects: \{response.url}")
      println("Number of redirects: \{response.history.length()}")
      
      // Test disabling redirects
      let no_redirect_response = get("https://httpbin.org/redirect/1", None, None, None, None, Some(false), None)
      assert_true(no_redirect_response.is_redirect())
      println("Redirect status: \{no_redirect_response.status_code}")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Example: Working with cookies manually
test "cookie_example" {
  @async.with_event_loop(fn(_) {
    try {
      let cookie_jar = CookieJar::new()
      let url = parse_url("https://httpbin.org/cookies")
      
      // Manually set a cookie
      let cookie = Cookie::new("test_cookie", "test_value")
      cookie_jar.set(cookie)
      
      // Use the cookie jar in a request
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
      
      let response = request(Method::Get, "https://httpbin.org/cookies", Some(options))
      response.raise_for_status()
      println("Cookie sent successfully")
    } catch {
      error => println("Error: \{error}")
    }
  })
}
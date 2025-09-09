///|
/// Comprehensive demo program for MoonBit requests library
fn main {
  @async.with_event_loop(fn(_) {
    try {
      println("🚀 MoonBit Requests Library Demo")

      // Basic GET request
      println("\n📡 1. Basic GET Request")
      let response = @allwefantasy/requests.get(
        "https://httpbin.org/get",
        None,
        None,
      )
      println("   Status: \{response.status_code} \{response.reason}")
      println("   Success: \{response.ok()}")

      // GET with query parameters
      println("\n📡 2. GET with Query Parameters")
      let params = [("lang", "moonbit"), ("version", "0.1")]
      let param_response = @allwefantasy/requests.get(
        "https://httpbin.org/get",
        Some(params),
        None,
      )
      println("   Status: \{param_response.status_code}")

      // POST with JSON
      println("\n📡 3. POST with JSON Data")
      let json_data : Json = {
        "message": "Hello from MoonBit!",
        "timestamp": "2024-01-01",
      }
      let post_response = @allwefantasy/requests.post(
        "https://httpbin.org/post",
        None,
        Some(json_data),
        None,
      )
      println("   Status: \{post_response.status_code}")

      // POST with form data
      println("\n📡 4. POST with Form Data")
      let form_data = [("username", "moonbit"), ("action", "demo")]
      let form_response = @allwefantasy/requests.post(
        "https://httpbin.org/post",
        Some(form_data),
        None,
        None,
      )
      println("   Status: \{form_response.status_code}")

      // Custom headers
      println("\n📡 5. Request with Custom Headers")
      let headers = [("User-Agent", "MoonBit-Requests/1.0"), ("X-Demo", "true")]
      let header_response = @allwefantasy/requests.get(
        "https://httpbin.org/headers",
        None,
        Some(headers),
      )
      println("   Status: \{header_response.status_code}")

      // Basic Authentication  
      println("\n🔐 6. Basic Authentication")
      let auth = @allwefantasy/requests.basic_auth("user", "passwd")
      let (auth_header_name, auth_header_value) = auth.to_header()
      let auth_headers = [(auth_header_name, auth_header_value)]
      let auth_response = @allwefantasy/requests.get(
        "https://httpbin.org/basic-auth/user/passwd",
        None,
        Some(auth_headers),
      )
      println("   Auth Status: \{auth_response.status_code}")

      // Session usage
      println("\n📋 7. Session Usage")
      let session = @allwefantasy/requests.Session::new()
      let session_response = session.get(
        "https://httpbin.org/user-agent",
        None,
        None,
      )
      println("   Session Status: \{session_response.status_code}")

      // Error handling
      println("\n❌ 8. Error Handling (404)")
      let error_response = @allwefantasy/requests.get(
        "https://httpbin.org/status/404",
        None,
        None,
      )
      println("   Error Status: \{error_response.status_code}")
      println("   Is OK: \{error_response.ok()}")
      try {
        error_response.raise_for_status()
        println("   This should not print")
      } catch {
        @allwefantasy/requests.RequestError::HTTPError(code, reason, _url) =>
          println("   ✅ Caught expected HTTP error: \{code} \{reason}")
        @allwefantasy/requests.RequestError::ConnectionError(msg) =>
          println("   Connection error: \{msg}")
        @allwefantasy/requests.RequestError::Timeout(msg) =>
          println("   Timeout error: \{msg}")
        @allwefantasy/requests.RequestError::URLError(msg) =>
          println("   URL error: \{msg}")
        @allwefantasy/requests.RequestError::TooManyRedirects(msg) =>
          println("   Too many redirects: \{msg}")
        @allwefantasy/requests.RequestError::SSLError(msg) =>
          println("   SSL error: \{msg}")
        @allwefantasy/requests.RequestError::ContentDecodingError(msg) =>
          println("   Content decoding error: \{msg}")
        _ => println("   Other error occurred")
      }

      // Test additional error types
      println("\n🛠️ 10. Error Handling Test")
      try {
        let _invalid_response = @allwefantasy/requests.get(
          "http://invalid-domain-that-does-not-exist.com",
          None,
          None,
        )

      } catch {
        @allwefantasy/requests.RequestError::ConnectionError(msg) =>
          println("   ✅ Caught connection error: \{msg}")
        @allwefantasy/requests.RequestError::URLError(msg) =>
          println("   ✅ Caught URL error: \{msg}")
        @allwefantasy/requests.RequestError::HTTPError(code, reason, url) =>
          println("   HTTP error \{code}: \{reason} for \{url}")
        @allwefantasy/requests.RequestError::Timeout(msg) =>
          println("   Timeout error: \{msg}")
        @allwefantasy/requests.RequestError::TooManyRedirects(msg) =>
          println("   Too many redirects: \{msg}")
        @allwefantasy/requests.RequestError::SSLError(msg) =>
          println("   SSL error: \{msg}")
        @allwefantasy/requests.RequestError::ContentDecodingError(msg) =>
          println("   Content decoding error: \{msg}")
        _ => println("   Other error occurred")
      }
      // Additional HTTP Methods
      println("\n📡 9. Additional HTTP Methods")

      // HEAD request (won't have response body)
      let head_response = @allwefantasy/requests.head(
        "https://httpbin.org/get",
        None,
        None,
      )
      println("   HEAD Status: \{head_response.status_code}")
      println("   HEAD Content Length: \{head_response.content.length()}")

      // OPTIONS request
      let options_response = @allwefantasy/requests.options(
        "https://httpbin.org/",
        None,
      )
      println("   OPTIONS Status: \{options_response.status_code}")

      // PATCH request with JSON
      let patch_data : Json = {
        "update": "patch request",
        "timestamp": "2024-01-01",
      }
      let patch_response = @allwefantasy/requests.patch(
        "https://httpbin.org/patch",
        None,
        Some(patch_data),
        None,
      )
      println("   PATCH Status: \{patch_response.status_code}")
      println("\n🎉 All MoonBit Requests features demonstrated successfully!")
    } catch {
      @allwefantasy/requests.RequestError::ConnectionError(msg) =>
        println("⚠️  Connection error: \{msg}")
      @allwefantasy/requests.RequestError::URLError(msg) =>
        println("⚠️  URL error: \{msg}")
      @allwefantasy/requests.RequestError::HTTPError(code, reason, url) =>
        println("⚠️  HTTP error \{code}: \{reason} for \{url}")
      @allwefantasy/requests.RequestError::Timeout(msg) =>
        println("⚠️  Timeout error: \{msg}")
      @allwefantasy/requests.RequestError::TooManyRedirects(msg) =>
        println("⚠️  Too many redirects: \{msg}")
      @allwefantasy/requests.RequestError::SSLError(msg) =>
        println("⚠️  SSL error: \{msg}")
      @allwefantasy/requests.RequestError::ContentDecodingError(msg) =>
        println("⚠️  Content decoding error: \{msg}")
      _ =>
        println(
          "⚠️  Some network requests failed (expected in restricted environments)",
        )
    }
  }) catch {
    _ => ()
  }
}

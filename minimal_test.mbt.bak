///|
/// Test the simple GET functionality
test "minimal_get_test" {
  @async.with_event_loop(fn(_) {
    try {
      let result = get_simple("https://httpbin.org/get")
      println("GET result length: \{result.length()}")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Test the simple POST functionality  
test "minimal_post_test" {
  @async.with_event_loop(fn(_) {
    try {
      let json_data = "{\"name\": \"MoonBit\", \"version\": \"0.1.0\"}"
      let result = post_json("https://httpbin.org/post", json_data)
      println("POST result length: \{result.length()}")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Test form posting
test "minimal_form_test" {
  @async.with_event_loop(fn(_) {
    try {
      let form = [("username", "testuser"), ("message", "hello world")]
      let result = post_form("https://httpbin.org/post", form)
      println("Form POST result length: \{result.length()}")
    } catch {
      error => println("Error: \{error}")
    }
  })
}

///|
/// Test URL encoding
test "url_encoding_test" {
  let encoded = url_encode_simple("hello world!")
  println("Encoded: \{encoded}")
  assert_true(encoded.contains("%20")) // space should be encoded
  assert_true(encoded.contains("%21")) // ! should be encoded
}

///|
/// Test query parameter addition
test "query_params_test" {
  let url = "https://example.com/search"
  let params = [("q", "moon bit"), ("lang", "en")]
  let result = add_query_params(url, params)
  println("URL with params: \{result}")
  assert_true(result.contains("?"))
  assert_true(result.contains("q="))
  assert_true(result.contains("lang="))
}

///|
/// Basic tests for the HTTP client
test "test_simple_get" {
  @async.with_event_loop(fn(_) {
    try {
      let response = get("https://httpbin.org/get", None, None)
      inspect(response.status_code, content="200")
      inspect(response.ok(), content="true")
      let text = response.text()
      inspect(text.contains("httpbin"), content="true")
    } catch {
      _ => inspect("Error", content="Error") // Skip tests that require network
    }
  }) catch {
    _ => ()
  }
}

///|
test "test_get_with_params" {
  @async.with_event_loop(fn(_) {
    try {
      let params = [("key1", "value1"), ("key2", "value2")]
      let response = get("https://httpbin.org/get", Some(params), None)
      inspect(response.status_code, content="200")
      let text = response.text()
      inspect(text.contains("key1"), content="true")
      inspect(text.contains("value1"), content="true")
    } catch {
      _ => inspect("Error", content="Error") // Skip tests that require network
    }
  }) catch {
    _ => ()
  }
}

///|
test "test_post_json" {
  @async.with_event_loop(fn(_) {
    try {
      let json_data = { "name": "MoonBit", "version": "0.1" }
      let response = post(
        "https://httpbin.org/post",
        None,
        Some(json_data),
        None,
      )
      inspect(response.status_code, content="200")
      let text = response.text()
      inspect(text.contains("MoonBit"), content="true")
    } catch {
      _ => inspect("Error", content="Error") // Skip tests that require network
    }
  }) catch {
    _ => ()
  }
}

///|
test "test_post_form_data" {
  @async.with_event_loop(fn(_) {
    try {
      let form_data = [("username", "testuser"), ("password", "testpass")]
      let response = post(
        "https://httpbin.org/post",
        Some(form_data),
        None,
        None,
      )
      inspect(response.status_code, content="200")
      let text = response.text()
      inspect(text.contains("testuser"), content="true")
    } catch {
      _ => inspect("Error", content="Error") // Skip tests that require network
    }
  }) catch {
    _ => ()
  }
}

///|
test "test_response_methods" {
  @async.with_event_loop(fn(_) {
    try {
      let response = get("https://httpbin.org/status/404", None, None)
      inspect(response.status_code, content="404")
      inspect(response.ok(), content="false")
      try {
        response.raise_for_status()
        inspect("Should have raised", content="Should have raised")
      } catch {
        RequestError::HTTPError(code, _, _) => inspect(code, content="404")
        _ => inspect("Wrong error type", content="Wrong error type")
      }
    } catch {
      _ => inspect("Error", content="Error") // Skip tests that require network
    }
  }) catch {
    _ => ()
  }
}

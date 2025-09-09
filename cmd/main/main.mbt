///|
/// Demo program for MoonBit requests library
fn main {
  @async.with_event_loop(fn(_) {
    try {
      let response = @allwefantasy/requests.get(
        "https://httpbin.org/get",
        None,
        None,
      )
      println("Status: \{response.status_code}")
      println("Response: \{response.text()}")
    } catch {
      _ => println("Error: network request failed")
    }
  }) catch {
    _ => ()
  }
}

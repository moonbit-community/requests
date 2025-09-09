///|
/// HTTP methods supported by the requests library
pub enum Method {
  Get
  Post
  Put
  Delete
  Head
  Options
  Patch
} derive(Show, Eq)

///|
/// HTTP headers type alias
pub typealias Array[(String, String)] as Headers

///|
/// Query parameters type alias
pub typealias Array[(String, String)] as Query

///|
/// Form data type alias  
pub typealias Array[(String, String)] as Form

///|
/// Authentication methods
pub enum Auth {
  Basic(String, String)
} derive(Show, Eq)

///|
/// Request timeout configuration
pub enum Timeout {
  Total(Int)
  Detailed(Int, Int)
} derive(Show, Eq)

///|
/// Error types for the requests library
pub suberror RequestError {
  /// HTTP error with status code, reason and URL
  HTTPError(Int, String, String)
  /// Timeout error
  Timeout(String)
  /// Network/connection error
  ConnectionError(String)
  /// JSON parsing error
  JSONError(String)
  /// URL encoding error
  URLError(String)
  /// General request error
  RequestException(String)
} derive(Show)

///|
/// Convenience function to create HTTP errors
pub fn http_error(code : Int, reason : String, url : String) -> RequestError {
  RequestError::HTTPError(code, reason, url)
}

///|
/// Convenience function to create timeout errors
pub fn timeout_error(message : String) -> RequestError {
  RequestError::Timeout(message)
}

///|
/// Convenience function to create connection errors
pub fn connection_error(message : String) -> RequestError {
  RequestError::ConnectionError(message)
}

///|
/// Convenience function to create JSON errors
pub fn json_error(message : String) -> RequestError {
  RequestError::JSONError(message)
}

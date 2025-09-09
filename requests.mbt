///|
/// Convenience function for GET requests
pub async fn get(
  url : String,
  params : Query?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  let options = RequestOptions::{
    params,
    headers,
    cookies: None,
    data: None,
    json: None,
    files: None,
    auth,
    timeout,
    allow_redirects,
    stream,
  }
  request(Method::Get, url, Some(options))
}

///|
/// Convenience function for POST requests
pub async fn post(
  url : String,
  data : Form?,
  json : Json?,
  files : Files?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  let options = RequestOptions::{
    params: None,
    headers,
    cookies: None,
    data,
    json,
    files,
    auth,
    timeout,
    allow_redirects,
    stream,
  }
  request(Method::Post, url, Some(options))
}

///|
/// Convenience function for PUT requests
pub async fn put(
  url : String,
  data : Form?,
  json : Json?,
  files : Files?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  let options = RequestOptions::{
    params: None,
    headers,
    cookies: None,
    data,
    json,
    files,
    auth,
    timeout,
    allow_redirects,
    stream,
  }
  request(Method::Put, url, Some(options))
}

///|
/// Convenience function for DELETE requests
pub async fn delete(
  url : String,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  let options = RequestOptions::{
    params: None,
    headers,
    cookies: None,
    data: None,
    json: None,
    files: None,
    auth,
    timeout,
    allow_redirects,
    stream,
  }
  request(Method::Delete, url, Some(options))
}

///|
/// Convenience function for HEAD requests
pub async fn head(
  url : String,
  params : Query?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  let options = RequestOptions::{
    params,
    headers,
    cookies: None,
    data: None,
    json: None,
    files: None,
    auth,
    timeout,
    allow_redirects: Some(
      match allow_redirects {
        Some(val) => val
        None => false
      },
    ), // HEAD typically doesn't follow redirects
    stream,
  }
  request(Method::Head, url, Some(options))
}

///|
/// Convenience function for OPTIONS requests
pub async fn options(
  url : String,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  let options = RequestOptions::{
    params: None,
    headers,
    cookies: None,
    data: None,
    json: None,
    files: None,
    auth,
    timeout,
    allow_redirects,
    stream,
  }
  request(Method::Options, url, Some(options))
}

///|
/// Convenience function for PATCH requests
pub async fn patch(
  url : String,
  data : Form?,
  json : Json?,
  files : Files?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  let options = RequestOptions::{
    params: None,
    headers,
    cookies: None,
    data,
    json,
    files,
    auth,
    timeout,
    allow_redirects,
    stream,
  }
  request(Method::Patch, url, Some(options))
}

///|
/// Session for persistent connections, cookies, and default settings
pub struct Session {
  mut headers : Headers
  mut cookies : CookieJar
  mut auth : Auth?
  mut timeout : Timeout?
  mut allow_redirects : Bool
  mut stream : Bool
} derive(Show)

///|
/// Create a new session with default settings
pub fn Session::new() -> Session {
  Session::{
    headers: [],
    cookies: CookieJar::new(),
    auth: None,
    timeout: None,
    allow_redirects: true,
    stream: false,
  }
}

///|
/// Close the session (cleanup any resources)
pub fn Session::close(self : Session) -> Unit {
  // Currently no resources to clean up
  // This method is provided for API compatibility with Python requests
}

///|
/// Make a request using the session
pub async fn Session::request(
  self : Session,
  method : Method,
  url : String,
  params : Query?,
  data : Form?,
  json : Json?,
  files : Files?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  // Merge session settings with request-specific options
  let merged_headers = merge_headers(self.headers, headers)
  let merged_auth = match auth {
    Some(val) => Some(val)
    None => self.auth
  }
  let merged_timeout = match timeout {
    Some(val) => Some(val)
    None => self.timeout
  }
  let merged_allow_redirects = match allow_redirects {
    Some(val) => val
    None => self.allow_redirects
  }
  let merged_stream = match stream {
    Some(val) => val
    None => self.stream
  }
  let options = RequestOptions::{
    params,
    headers: Some(merged_headers),
    cookies: Some(self.cookies),
    data,
    json,
    files,
    auth: merged_auth,
    timeout: merged_timeout,
    allow_redirects: Some(merged_allow_redirects),
    stream: Some(merged_stream),
  }
  let response = request(method, url, Some(options))

  // Update session cookies with response cookies
  self.cookies.merge(response.cookies)
  response
}

///|
/// Session GET request
pub async fn Session::get(
  self : Session,
  url : String,
  params : Query?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  self.request(
    Method::Get,
    url,
    params,
    None, // data
    None, // json
    None, // files
    headers,
    auth,
    timeout,
    allow_redirects,
    stream,
  )
}

///|
/// Session POST request
pub async fn Session::post(
  self : Session,
  url : String,
  data : Form?,
  json : Json?,
  files : Files?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  self.request(
    Method::Post,
    url,
    None, // params
    data,
    json,
    files,
    headers,
    auth,
    timeout,
    allow_redirects,
    stream,
  )
}

///|
/// Session PUT request
pub async fn Session::put(
  self : Session,
  url : String,
  data : Form?,
  json : Json?,
  files : Files?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  self.request(
    Method::Put,
    url,
    None, // params
    data,
    json,
    files,
    headers,
    auth,
    timeout,
    allow_redirects,
    stream,
  )
}

///|
/// Session DELETE request
pub async fn Session::delete(
  self : Session,
  url : String,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  self.request(
    Method::Delete,
    url,
    None, // params
    None, // data
    None, // json
    None, // files
    headers,
    auth,
    timeout,
    allow_redirects,
    stream,
  )
}

///|
/// Session HEAD request
pub async fn Session::head(
  self : Session,
  url : String,
  params : Query?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  self.request(
    Method::Head,
    url,
    params,
    None, // data
    None, // json
    None, // files
    headers,
    auth,
    timeout,
    Some(
      match allow_redirects {
        Some(val) => val
        None => false
      },
    ), // HEAD typically doesn't follow redirects
    stream,
  )
}

///|
/// Session OPTIONS request
pub async fn Session::options(
  self : Session,
  url : String,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  self.request(
    Method::Options,
    url,
    None, // params
    None, // data
    None, // json
    None, // files
    headers,
    auth,
    timeout,
    allow_redirects,
    stream,
  )
}

///|
/// Session PATCH request
pub async fn Session::patch(
  self : Session,
  url : String,
  data : Form?,
  json : Json?,
  files : Files?,
  headers : Headers?,
  auth : Auth?,
  timeout : Timeout?,
  allow_redirects : Bool?,
  stream : Bool?,
) -> Response raise {
  self.request(
    Method::Patch,
    url,
    None, // params
    data,
    json,
    files,
    headers,
    auth,
    timeout,
    allow_redirects,
    stream,
  )
}

///|
/// Merge two header arrays, with second taking precedence
fn merge_headers(base : Headers, additional : Headers?) -> Headers {
  match additional {
    Some(extra) => {
      let mut result = base
      for extra_header in extra {
        let (name, value) = extra_header
        result = add_header(result, name, value)
      }
      result
    }
    None => base
  }
}

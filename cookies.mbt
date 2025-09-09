///|
/// A single HTTP cookie with its attributes
pub struct Cookie {
  name : String
  value : String
  domain : String?
  path : String
  secure : Bool
  http_only : Bool
  max_age : Int?  // in seconds
  expires : String?  // HTTP date string
} derive(Show)

///|
/// Create a new cookie with default values
pub fn Cookie::new(name : String, value : String) -> Cookie {
  Cookie::{
    name,
    value,
    domain: None,
    path: "/",
    secure: false,
    http_only: false,
    max_age: None,
    expires: None,
  }
}

///|
/// Cookie jar for managing multiple cookies
pub struct CookieJar {
  cookies : Array[Cookie]
} derive(Show)

///|
/// Create a new empty cookie jar
pub fn CookieJar::new() -> CookieJar {
  CookieJar::{ cookies: [] }
}

///|
/// Add or update a cookie in the jar
pub fn CookieJar::set(self : CookieJar, cookie : Cookie) -> Unit {
  // Find existing cookie with same name, domain, and path
  let mut found_index = -1
  for i, existing in self.cookies {
    if existing.name == cookie.name &&
       existing.domain == cookie.domain &&
       existing.path == cookie.path {
      found_index = i
      break
    }
  }
  
  if found_index >= 0 {
    self.cookies[found_index] = cookie
  } else {
    self.cookies.push(cookie)
  }
}

///|
/// Get a cookie value by name for a specific URL
pub fn CookieJar::get(self : CookieJar, name : String, url : URL) -> String? {
  for cookie in self.cookies {
    if cookie.name == name && matches_url(cookie, url) {
      return Some(cookie.value)
    }
  }
  None
}

///|
/// Get all cookies that match a URL
pub fn CookieJar::get_for_url(self : CookieJar, url : URL) -> Array[Cookie] {
  let result = []
  for cookie in self.cookies {
    if matches_url(cookie, url) {
      result.push(cookie)
    }
  }
  result
}

///|
/// Generate Cookie header value for a URL
pub fn CookieJar::to_header(self : CookieJar, url : URL) -> String? {
  let matching_cookies = self.get_for_url(url)
  if matching_cookies.is_empty() {
    return None
  }
  
  let cookie_pairs = matching_cookies.map(fn { cookie => cookie.name + "=" + cookie.value })
  Some(cookie_pairs.join("; "))
}

///|
/// Parse Set-Cookie header and add to jar
pub fn CookieJar::add_from_response(self : CookieJar, url : URL, set_cookie_header : String) -> Unit {
  guard parse_set_cookie(set_cookie_header, url) is Some(cookie) else { return }
  self.set(cookie)
}

///|
/// Merge another cookie jar into this one
pub fn CookieJar::merge(self : CookieJar, other : CookieJar) -> Unit {
  for cookie in other.cookies {
    self.set(cookie)
  }
}

///|
/// Check if a cookie matches a URL (domain, path, secure)
fn matches_url(cookie : Cookie, url : URL) -> Bool {
  // Check secure flag
  if cookie.secure && url.scheme != "https" {
    return false
  }
  
  // Check domain
  let domain_matches = match cookie.domain {
    None => true  // Host-only cookie matches any domain (simplified)
    Some(domain) => {
      let cookie_domain = domain.to_lower()
      let url_host = url.host.to_lower()
      
      if cookie_domain.starts_with(".") {
        // Domain cookie: matches if host ends with domain (without leading dot)
        let domain_suffix = cookie_domain[1:]
        url_host.ends_with(domain_suffix) && 
        (url_host == domain_suffix || url_host.ends_with("." + domain_suffix))
      } else {
        // Exact domain match
        url_host == cookie_domain
      }
    }
  }
  
  if !domain_matches {
    return false
  }
  
  // Check path - URL path must start with cookie path
  url.path.starts_with(cookie.path)
}

///|
/// Parse a Set-Cookie header value
fn parse_set_cookie(header : String, request_url : URL) -> Cookie? {
  let parts = header.split(";")
  guard parts.length() > 0 else { return None }
  
  // Parse name=value pair
  let name_value = parts[0].trim()
  guard name_value.find("=") is Some(eq_pos) else { return None }
  
  let name = name_value[0:eq_pos].trim()
  let value = name_value[eq_pos + 1:].trim()
  
  let mut cookie = Cookie::new(name, value)
  
  // Parse attributes
  for i in 1..<parts.length() {
    let attr = parts[i].trim().to_lower()
    
    if attr == "secure" {
      cookie.secure = true
    } else if attr == "httponly" {
      cookie.http_only = true
    } else if attr.starts_with("domain=") {
      cookie.domain = Some(attr[7:])
    } else if attr.starts_with("path=") {
      cookie.path = attr[5:]
    } else if attr.starts_with("max-age=") {
      cookie.max_age = try? attr[8:].to_int()
    } else if attr.starts_with("expires=") {
      cookie.expires = Some(attr[8:])
    }
  }
  
  // Set default domain if not specified
  if cookie.domain is None {
    cookie.domain = None  // Host-only cookie
  }
  
  Some(cookie)
}
///|
/// Enhanced Cookie support for MoonBit Requests

///|
/// Individual Cookie with full attributes
pub struct Cookie {
  name : String
  value : String
  domain : String?
  path : String
  secure : Bool
  http_only : Bool
  max_age_s : Int?
  expires_raw : String?
} derive(Show, Eq)

///|
/// Enhanced Cookie Jar with domain/path matching
pub struct EnhancedCookieJar {
  mut cookies : Array[Cookie]
} derive(Show)

///|
pub fn EnhancedCookieJar::new() -> EnhancedCookieJar {
  EnhancedCookieJar::{ cookies: [] }
}

///|
pub fn EnhancedCookieJar::set_simple(
  self : EnhancedCookieJar,
  name : String,
  value : String,
) -> Unit {
  let cookie = Cookie::{
    name,
    value,
    domain: None,
    path: "/",
    secure: false,
    http_only: false,
    max_age_s: None,
    expires_raw: None,
  }
  self.upsert(cookie)
}

///|
pub fn EnhancedCookieJar::get(
  self : EnhancedCookieJar,
  name : String,
) -> String? {
  for cookie in self.cookies {
    if cookie.name == name {
      return Some(cookie.value)
    }
  }
  None
}

///|
pub fn EnhancedCookieJar::upsert(
  self : EnhancedCookieJar,
  cookie : Cookie,
) -> Unit {
  // Find existing cookie and replace or add new
  let mut found_index = -1
  for i = 0; i < self.cookies.length(); i = i + 1 {
    let existing = self.cookies[i]
    if cookie_matches(existing, cookie) {
      found_index = i
      break
    }
  }
  if found_index >= 0 {
    // Replace existing cookie by rebuilding array
    let new_cookies = self.cookies.mapi(fn {
      i, existing_cookie =>
        if i == found_index {
          cookie
        } else {
          existing_cookie
        }
    })
    self.cookies = new_cookies
  } else {
    self.cookies.push(cookie)
  }
}

///|
pub fn EnhancedCookieJar::merge(
  self : EnhancedCookieJar,
  other : EnhancedCookieJar,
) -> Unit {
  for cookie in other.cookies {
    self.upsert(cookie)
  }
}

///|
/// URL structure for cookie matching
pub struct SimpleURL {
  scheme : String
  host : String
  path : String
} derive(Show)

///|
pub fn parse_simple_url(url : String) -> SimpleURL? {
  match url.find("://") {
    Some(scheme_end) => {
      let scheme = url[0:scheme_end].to_string() catch { _ => return None }
      let rest = url[scheme_end + 3:].to_string() catch { _ => return None }
      let (host, path) = match rest.find("/") {
        Some(path_start) => {
          let host = rest[0:path_start].to_string() catch { _ => return None }
          let path = rest[path_start:].to_string() catch { _ => return None }
          (host, path)
        }
        None => (rest, "/")
      }
      Some(SimpleURL::{ scheme, host, path })
    }
    None => None
  }
}

///|
pub fn EnhancedCookieJar::get_cookies_for_url(
  self : EnhancedCookieJar,
  url : String,
) -> Array[(String, String)] {
  match parse_simple_url(url) {
    Some(parsed_url) => {
      let applicable = []
      for cookie in self.cookies {
        if cookie_applies_to_url(cookie, parsed_url) {
          applicable.push((cookie.name, cookie.value))
        }
      }
      applicable
    }
    None => []
  }
}

///|
pub fn EnhancedCookieJar::to_cookie_header_for_url(
  self : EnhancedCookieJar,
  url : String,
) -> String? {
  let applicable = self.get_cookies_for_url(url)
  if applicable.is_empty() {
    None
  } else {
    let cookie_string = applicable
      .map(fn { (name, value) => name + "=" + value })
      .join("; ")
    Some(cookie_string)
  }
}

///|
/// Parse Set-Cookie header
pub fn EnhancedCookieJar::parse_and_add_set_cookie(
  self : EnhancedCookieJar,
  set_cookie_header : String,
  request_url : String,
) -> Unit {
  match parse_set_cookie_header(set_cookie_header, request_url) {
    Some(cookie) => self.upsert(cookie)
    None => ()
  }
}

///|
/// Cookie utility functions
fn cookie_matches(a : Cookie, b : Cookie) -> Bool {
  a.name == b.name && a.domain == b.domain && a.path == b.path
}

///|
fn cookie_applies_to_url(cookie : Cookie, url : SimpleURL) -> Bool {
  // Check secure flag
  if cookie.secure && url.scheme != "https" {
    return false
  }

  // Check domain
  let domain_ok = match cookie.domain {
    None => true // Host-only cookie
    Some(domain) => {
      let domain_lower = domain.to_lower()
      let host_lower = url.host.to_lower()
      if simple_string_starts_with(domain_lower, ".") {
        // Domain cookie: .example.com matches sub.example.com and example.com
        let domain_suffix = simple_string_substring(domain_lower, 1)
        simple_string_ends_with(host_lower, domain_suffix) &&
        (
          host_lower == domain_suffix ||
          simple_string_ends_with(host_lower, "." + domain_suffix)
        )
      } else {
        // Exact match
        host_lower == domain_lower
      }
    }
  }
  if not(domain_ok) {
    return false
  }

  // Check path
  simple_string_starts_with(url.path, cookie.path)
}

///|
fn parse_set_cookie_header(header : String, request_url : String) -> Cookie? {
  // Simple Set-Cookie parsing: name=value; attributes
  let parts = header.split(";")
  let parts_array = parts.to_array()
  if parts_array.is_empty() {
    return None
  }

  // Parse name=value
  let name_value_part = parts_array[0]
  match name_value_part.find("=") {
    Some(eq_pos) => {
      let name = name_value_part[0:eq_pos].to_string() catch {
        _ => return None
      }
      let value = name_value_part[eq_pos + 1:].to_string() catch {
        _ => return None
      }

      // Default attributes
      let mut domain = None
      let mut path = "/"
      let mut secure = false
      let mut http_only = false
      let mut max_age = None
      // expires parsing would go here if needed

      // Parse attributes
      for i = 1; i < parts_array.length(); i = i + 1 {
        let attr = parts_array[i].to_lower().to_string()
        if attr == "secure" {
          secure = true
        } else if attr == "httponly" {
          http_only = true
        } else if simple_string_starts_with(attr, "domain=") {
          domain = Some(simple_string_substring(attr, 7))
        } else if simple_string_starts_with(attr, "path=") {
          path = simple_string_substring(attr, 5)
        } else if simple_string_starts_with(attr, "max-age=") {
          let age_str = simple_string_substring(attr, 8)
          max_age = simple_parse_int(age_str)
        }
      }
      Some(Cookie::{
        name,
        value,
        domain,
        path,
        secure,
        http_only,
        max_age_s: max_age,
        expires_raw: None,
      })
    }
    None => None
  }
}

///|
/// Simple string utility functions
fn simple_string_starts_with(s : String, prefix : String) -> Bool {
  if prefix.length() > s.length() {
    false
  } else {
    let prefix_part = s[0:prefix.length()].to_string() catch {
      _ => return false
    }
    prefix_part == prefix
  }
}

///|
fn simple_string_ends_with(s : String, suffix : String) -> Bool {
  if suffix.length() > s.length() {
    false
  } else {
    let start = s.length() - suffix.length()
    let suffix_part = s[start:].to_string() catch { _ => return false }
    suffix_part == suffix
  }
}

///|
fn simple_string_substring(s : String, start : Int) -> String {
  if start >= s.length() {
    ""
  } else {
    s[start:].to_string() catch {
      _ => ""
    }
  }
}

///|
fn simple_parse_int(s : String) -> Int? {
  let mut result = 0
  if s.is_empty() {
    return None
  }
  for ch in s {
    let code = ch.to_int()
    if code >= '0'.to_int() && code <= '9'.to_int() {
      result = result * 10 + (code - '0'.to_int())
    } else {
      return None
    }
  }
  Some(result)
}

///|
/// Represents a file to be uploaded
pub enum FileData {
  /// Upload from file path
  FilePath(String, String?, String?)
  /// Upload from bytes in memory
  FileBytes(String, Bytes, String?)
} derive(Show, Eq)

///|
/// Files type for multipart uploads - maps field name to file data
pub typealias Array[(String, FileData)] as Files

///|
/// Generate a random boundary for multipart encoding
fn generate_boundary() -> String {
  let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let mut boundary = "----formdata-moonbit-"

  // Generate 16 random characters
  for _ in 0..<16 {
    let random_index = random_int() % chars.length()
    boundary = boundary + chars[random_index:random_index + 1]
  }
  boundary
}

///|
/// Simple random number generator (using current time as seed)
fn random_int() -> Int {
  // This is a simplified random number generator
  // In a real implementation, you might want to use a better RNG
  let seed = get_current_time_ms() % 1000000
  (seed * 1103515245 + 12345) % 2147483647
}

///|
/// Get current time in milliseconds (simplified)
fn get_current_time_ms() -> Int {
  // This would normally use system time
  // For now, using a fixed value for deterministic behavior
  1234567890
}

///|
/// Encode multipart form data
pub fn encode_multipart(
  form_data : Form,
  files : Files,
) -> (Bytes, String) raise {
  let boundary = generate_boundary()
  let crlf = "\r\n"
  let boundary_line = "--" + boundary + crlf
  let final_boundary = "--" + boundary + "--" + crlf
  let mut parts = []

  // Add form fields
  for form_field in form_data {
    let (name, value) = form_field
    let mut part = boundary_line
    part = part + "Content-Disposition: form-data; name=\"" + name + "\"" + crlf
    part = part + crlf + value + crlf
    parts.push(@encoding.encode(part, encoding=UTF8))
  }

  // Add files
  for file_field in files {
    let (field_name, file_data) = file_field
    match file_data {
      FilePath(path, filename, content_type) => {
        let actual_filename = match filename {
          Some(name) => name
          None => extract_filename(path)
        }
        let actual_content_type = match content_type {
          Some(ct) => ct
          None => "application/octet-stream"
        }

        // Read file content
        let file_content = read_file_bytes(path) catch {
          _ => raise RequestException("Failed to read file: " + path)
        }
        let mut part = boundary_line
        part = part +
          "Content-Disposition: form-data; name=\"" +
          field_name +
          "\"; filename=\"" +
          actual_filename +
          "\"" +
          crlf
        part = part + "Content-Type: " + actual_content_type + crlf + crlf
        let part_header = @encoding.encode(part, encoding=UTF8)
        let part_footer = @encoding.encode(crlf, encoding=UTF8)
        parts.push(part_header + file_content + part_footer)
      }
      FileBytes(filename, content, content_type) => {
        let actual_content_type = match content_type {
          Some(ct) => ct
          None => "application/octet-stream"
        }
        let mut part = boundary_line
        part = part +
          "Content-Disposition: form-data; name=\"" +
          field_name +
          "\"; filename=\"" +
          filename +
          "\"" +
          crlf
        part = part + "Content-Type: " + actual_content_type + crlf + crlf
        let part_header = @encoding.encode(part, encoding=UTF8)
        let part_footer = @encoding.encode(crlf, encoding=UTF8)
        parts.push(part_header + content + part_footer)
      }
    }
  }

  // Add final boundary
  parts.push(@encoding.encode(final_boundary, encoding=UTF8))

  // Combine all parts
  let mut total_content = b""
  for part in parts {
    total_content = total_content + part
  }
  let content_type = "multipart/form-data; boundary=" + boundary
  (total_content, content_type)
}

///|
/// Extract filename from file path
fn extract_filename(path : String) -> String {
  match path.rev_find("/") {
    Some(pos) => path[pos + 1:]
    None => path
  }
}

///|
/// Read file content as bytes (simplified implementation)
fn read_file_bytes(path : String) -> Bytes raise {
  // This is a simplified version - in reality you'd use the fs module
  // For now, return empty bytes
  b""
}

///|
/// Guess content type from filename extension
pub fn guess_content_type(filename : String) -> String {
  let lower_name = filename.to_lower()
  if lower_name.ends_with(".txt") {
    "text/plain"
  } else if lower_name.ends_with(".html") {
    "text/html"
  } else if lower_name.ends_with(".css") {
    "text/css"
  } else if lower_name.ends_with(".js") {
    "application/javascript"
  } else if lower_name.ends_with(".json") {
    "application/json"
  } else if lower_name.ends_with(".pdf") {
    "application/pdf"
  } else if lower_name.ends_with(".jpg") || lower_name.ends_with(".jpeg") {
    "image/jpeg"
  } else if lower_name.ends_with(".png") {
    "image/png"
  } else if lower_name.ends_with(".gif") {
    "image/gif"
  } else if lower_name.ends_with(".mp4") {
    "video/mp4"
  } else if lower_name.ends_with(".mp3") {
    "audio/mpeg"
  } else if lower_name.ends_with(".zip") {
    "application/zip"
  } else {
    "application/octet-stream"
  }
}

///|
/// Create a file upload from path
pub fn file_from_path(
  path : String,
  filename : String?,
  content_type : String?,
) -> FileData {
  let actual_content_type = match content_type {
    Some(ct) => Some(ct)
    None =>
      match filename {
        Some(fname) => Some(guess_content_type(fname))
        None => Some(guess_content_type(extract_filename(path)))
      }
  }
  FileData::FilePath(path, filename, actual_content_type)
}

///|
/// Create a file upload from bytes
pub fn file_from_bytes(
  filename : String,
  content : Bytes,
  content_type : String?,
) -> FileData {
  let actual_content_type = match content_type {
    Some(ct) => Some(ct)
    None => Some(guess_content_type(filename))
  }
  FileData::FileBytes(filename, content, actual_content_type)
}

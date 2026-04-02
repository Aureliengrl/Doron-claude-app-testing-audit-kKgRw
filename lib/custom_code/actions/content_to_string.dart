// Stub: contentToString action
// Converts dynamic content to a String representation

Future<String> contentToString(dynamic content) async {
  if (content == null) return '';
  if (content is String) return content;
  return content.toString();
}

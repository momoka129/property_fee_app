bool isValidImageUrl(String? url) {
  if (url == null) return false;
  if (url.isEmpty) return false;
  try {
    final uri = Uri.parse(url);
    return uri.hasScheme && uri.host.isNotEmpty;
  } catch (_) {
    return false;
  }
}



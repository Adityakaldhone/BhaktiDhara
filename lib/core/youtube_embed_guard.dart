/// Whether [url] is a Google / YouTube sign-in page. Embedded players must
/// never navigate to one: the app has no login, and Play review treats a
/// sign-in form inside the app as a login wall.
bool isSignInUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();
  return host == 'accounts.google.com' ||
      host.endsWith('.accounts.google.com') ||
      path.contains('servicelogin') ||
      path.contains('/signin') ||
      path.startsWith('/login') ||
      path.startsWith('/v3/signin');
}

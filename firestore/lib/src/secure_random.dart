/// `newSecureRandom()`: a cryptographically secure random generator that also
/// works in a dart2js node program.
library;

export 'secure_random_vm.dart'
    if (dart.library.js_interop) 'secure_random_js.dart';

// This stub will provide dummy implementations for dart:html classes so that code
// using dart:html can compile on non-web platforms.
class HtmlStyle {
  String display = '';
}

// A stub for the AnchorElement from dart:html.
class AnchorElement {
  AnchorElement({required String href});
  String? download;
  // Provide a style property with a default instance.
  final HtmlStyle style = HtmlStyle();

  // Stub for the click() method.
  void click() {}

  // Stub for the remove() method.
  void remove() {}
}

// A stub for the Body element.
class Body {
  // Provide an append() method that does nothing.
  void append(dynamic element) {}
}

// A stub for the Document.
class Document {
  // Provide a dummy body.
  final Body? body = Body();
}

// A getter for the document.
Document get document => Document();

// A stub for the Blob class.
class Blob {
  Blob(List<dynamic> parts);
}

// A stub for the Url helper.
class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

// This is a stub file which is used when compiling for platforms other than web

// Stub versions of the HTML classes we use
class Element {
  String? id;
  StyleElement style = StyleElement();

  void append(Element element) {}
  void remove() {}
}

class StyleElement {
  String position = '';
  String top = '';
  String left = '';
  String width = '';
  String height = '';
  String zIndex = '';
  String opacity = '';
}

class DivElement extends Element {
  DivElement() : super();
}

class Document {
  Element? body;

  Element? getElementById(String id) => null;
}

// Expose a top-level document variable
Document document = Document();

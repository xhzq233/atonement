import 'dart:html' as html;

void download({required String url}) {
  html.window.open(url, 'image');
}

class HtmlConverter 
{

  // Convert string by replacing common HTML tags.
  static String convert(String htmlString) {
    return htmlString.replaceAll('<p>', '\n')
        .replaceAll('</p>', '\n')
        .replaceAll('<li>', '\n')
        .replaceAll('</li>', '\n')
        .replaceAll('<ul>', '\n')
        .replaceAll('</ul>', '\n')
        .replaceAll('<i>', '')
        .replaceAll('</i>', '')
        .replaceAll('<b>', '')
        .replaceAll('</b>', '');
  }
}
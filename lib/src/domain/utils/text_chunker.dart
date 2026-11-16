class TextChunker {
  /// Splits a large text string into smaller chunks of approximately [chunkSize] words.
  static List<String> chunkText(String text, {int chunkSize = 200}) {
    final words = text.split(RegExp(r'\s+'));
    List<String> chunks = [];

    for (int i = 0; i < words.length; i += chunkSize) {
      int end = (i + chunkSize < words.length) ? i + chunkSize : words.length;
      chunks.add(words.sublist(i, end).join(' '));
    }

    return chunks;
  }
}
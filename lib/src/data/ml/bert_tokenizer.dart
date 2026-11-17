import 'dart:io';

class BertTokenizer {
  late Map<String, int> _vocab;
  bool _isLoaded = false;

  static const int clsToken = 101;
  static const int sepToken = 102;
  static const int unkToken = 100;

  /// Loads the vocab.txt file into memory
  Future<void> loadVocab(String vocabPath) async {
    _vocab = {};
    final file = File(vocabPath);
    final lines = await file.readAsLines();
    for (int i = 0; i < lines.length; i++) {
      _vocab[lines[i].trim()] = i;
    }
    _isLoaded = true;
  }

  /// Implements the standard BERT WordPiece tokenization algorithm
  List<int> tokenize(String text) {
    if (!_isLoaded) throw Exception("Vocabulary not loaded.");

    List<int> tokens = [clsToken];

    // Clean text: lowercase and separate punctuation
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'([^\w\s])'), r' $1 ');
    final words = cleanText.split(RegExp(r'\s+'));

    for (String word in words) {
      if (word.isEmpty) continue;

      int start = 0;
      bool isBad = false;
      List<int> subTokens = [];

      while (start < word.length) {
        int end = word.length;
        String? curSubStr;

        while (start < end) {
          String subStr = word.substring(start, end);
          if (start > 0) subStr = "##$subStr";

          if (_vocab.containsKey(subStr)) {
            curSubStr = subStr;
            break;
          }
          end -= 1;
        }

        if (curSubStr == null) {
          isBad = true;
          break;
        }

        subTokens.add(_vocab[curSubStr]!);
        start = end;
      }

      if (isBad) {
        tokens.add(unkToken);
      } else {
        tokens.addAll(subTokens);
      }
    }

    tokens.add(sepToken);
    return tokens;
  }
}
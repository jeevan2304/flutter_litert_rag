import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'bert_tokenizer.dart';

class TFLiteEmbeddingEngine {
  Interpreter? _interpreter;
  final BertTokenizer _tokenizer = BertTokenizer();

  // all-MiniLM-L6-v2 strict sequence length
  static const int _maxSequenceLength = 256;

  Future<void> initialize(String modelPath) async {
    try {
      _interpreter = await Interpreter.fromFile(File(modelPath));
      print("Embedding model loaded successfully.");
    } catch (e) {
      throw Exception("Failed to load embedding model: $e");
    }
  }

  List<double> generateEmbedding(String text) {
    if (_interpreter == null) {
      throw Exception("Embedding engine is not initialized.");
    }

    // 1. Tokenize the text
    List<int> tokens = _tokenizer.tokenize(text);

    // 2. Pad or truncate to exactly 256 length
    if (tokens.length > _maxSequenceLength) {
      tokens = tokens.sublist(0, _maxSequenceLength);
    } else {
      tokens.addAll(List.filled(_maxSequenceLength - tokens.length, 0));
    }

    // 3. Prepare inputs
    var inputIds = [tokens];
    var attentionMask = [
      tokens.map((t) => t == 0 ? 0 : 1).toList()
    ];

    // Only pass the two required inputs
    var inputs = [inputIds, attentionMask];

    // 4. Prepare the EXACT output tensor shape the model expects: [1, 384]
    var outputTensor = List.generate(1, (_) => List.filled(384, 0.0));
    var outputs = {0: outputTensor};

    // 5. Run Inference
    _interpreter!.runForMultipleInputs(inputs, outputs);

    // 6. The model already pooled it! Just return the first array directly.
    return outputTensor[0];
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
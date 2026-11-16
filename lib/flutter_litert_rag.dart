import 'dart:async';
import 'package:flutter/services.dart'; // Required for Channels
import 'src/data/local/objectbox_vector_database.dart';
import 'src/data/ml/tflite_embedding_engine.dart';
import 'src/domain/models/document_chunk.dart';
import 'src/domain/utils/text_chunker.dart';

class LiteRtRagEngine {
  static final LiteRtRagEngine _instance = LiteRtRagEngine._internal();
  factory LiteRtRagEngine() => _instance;
  LiteRtRagEngine._internal();

  final ObjectBoxVectorDatabase _vectorDb = ObjectBoxVectorDatabase();
  final TFLiteEmbeddingEngine _embeddingEngine = TFLiteEmbeddingEngine();

  // Define the channels exactly as named in Kotlin
  final MethodChannel _methodChannel = const MethodChannel('flutter_litert_rag_methods');
  final EventChannel _eventChannel = const EventChannel('flutter_litert_rag_events');

  Future<void> initialize({
    required String llmModelPath,
    required String embeddingModelPath,
  }) async {
    await _vectorDb.initialize();
    await _embeddingEngine.initialize(embeddingModelPath);

    // Trigger the Kotlin engine initialization
    await _methodChannel.invokeMethod('initializeLlm', {
      'modelPath': llmModelPath,
    });
    print("Gemma LiteRT Engine initialized successfully.");
  }

  Future<void> ingestDocument({
    required String documentId,
    required String text,
  }) async {
    List<String> textChunks = TextChunker.chunkText(text);
    for (String chunkText in textChunks) {
      List<double> vector = _embeddingEngine.generateEmbedding(chunkText);
      await _vectorDb.saveChunk(DocumentChunk(
        documentId: documentId,
        text: chunkText,
        embedding: vector,
      ));
    }
  }

  Stream<String> ask(String prompt) async* {
    List<double> promptVector = _embeddingEngine.generateEmbedding(prompt);
    List<DocumentChunk> relevantChunks = await _vectorDb.searchSimilar(promptVector, limit: 3);

    String context = relevantChunks.map((c) => c.text).join('\n\n');
    String finalPrompt = "Context:\n$context\n\nQuestion: $prompt\nAnswer:";

    // Create a StreamController to manage the incoming tokens from Kotlin
    final controller = StreamController<String>();

    // Listen to the EventChannel for streamed tokens
    final subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final token = event as String;
      if (token == "[DONE]") {
        controller.close(); // End the stream when Kotlin signals completion
      } else {
        controller.add(token); // Add the newly generated word to the Flutter UI
      }
    }, onError: (error) {
      controller.addError(error);
    });

    // Trigger the native generation process
    _methodChannel.invokeMethod('generateResponse', {
      'prompt': finalPrompt,
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });

    // Yield the tokens to the package consumer as they arrive
    yield* controller.stream;
  }

  void dispose() {
    _embeddingEngine.dispose();
    _vectorDb.close();
    _methodChannel.invokeMethod('disposeLlm');
  }
}
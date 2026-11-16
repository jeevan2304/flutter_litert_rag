import 'package:flutter/material.dart';
import 'package:flutter_litert_rag/flutter_litert_rag.dart';

void main() {
  runApp(const MaterialApp(home: RagTestScreen()));
}

class RagTestScreen extends StatefulWidget {
  const RagTestScreen({super.key});

  @override
  State<RagTestScreen> createState() => _RagTestScreenState();
}

class _RagTestScreenState extends State<RagTestScreen> {
  final LiteRtRagEngine _engine = LiteRtRagEngine();
  final TextEditingController _promptController = TextEditingController();

  String _uiConsole = "Initializing engines...\n";
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _bootUpRagPipeline();
  }

  Future<void> _bootUpRagPipeline() async {
    try {
      // 1. Initialize with the absolute ADB paths
      await _engine.initialize(
        llmModelPath: '/data/local/tmp/gemma-4-E2B-it.litertlm',
        embeddingModelPath: '/data/local/tmp/all-MiniLM-L6-v2-quant.tflite',
      );

      setState(() => _uiConsole += "Models loaded into RAM.\nIngesting private data...\n");

      // 2. Ingest some highly specific dummy data to test the Vector DB
      await _engine.ingestDocument(
        documentId: 'safechat_arch',
        text: 'SafeChat is a highly secure messaging application utilizing XMPP for socket communications. The local data is stored via SQLite with AES encryption. The master admin override code is 9876-ALPHA.',
      );

      setState(() {
        _uiConsole += "Vector DB ready. You can now ask questions.";
        _isReady = true;
      });
    } catch (e) {
      setState(() => _uiConsole += "Boot Error: $e");
    }
  }

  void _askAi() {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _uiConsole = ""; // Clear console for the answer
    });

    // 3. Query the engine and listen to the token stream
    final stream = _engine.ask(_promptController.text);

    stream.listen(
          (token) => setState(() => _uiConsole += token),
      onError: (error) => setState(() => _uiConsole += "\nStream Error: $error"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local RAG Engine Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _uiConsole,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    enabled: _isReady,
                    decoration: const InputDecoration(hintText: 'e.g., What is the SafeChat override code?'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isReady ? _askAi : null,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
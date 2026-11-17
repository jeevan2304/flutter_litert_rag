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
      await _engine.initialize(
        llmModelPath: '/data/local/tmp/gemma-4-E2B-it.litertlm',
        embeddingModelPath: '/data/local/tmp/all-MiniLM-L6-v2-quant.tflite',
        vocabPath: '/data/local/tmp/vocab.txt', // Pass the vocabulary file
      );

      setState(() => _uiConsole += "Models loaded into RAM.\nIngesting private data...\n");

      // Your complete resume formatted as a Dart multiline string
      String resumeText = '''
Summary
Mobile Application Developer with a strong foundation in Android development (Kotlin/Java) and deep expertise in cross-platform engineering with Flutter and Dart, with a strong focus on integrating intelligent AI workflows, Large Language Models (LLMs), and Retrieval-Augmented Generation (RAG).
Experienced in architecting robust, scalable real-time messaging systems utilizing XMPP (Openfire) and custom backends. Proven track record in application security, offline-first capabilities, and performance optimization, employing Clean Architecture principles and efficient state management to deliver seamless, intelligent user experiences.

Experience
Mobile Application Developer Capulus Technologies Private Limited
September 2025 – Present
– Spearheaded a secure cross-platform messaging app using Flutter/Dart, enforcing Clean Architecture, Provider for state management, and sqflite for offline persistence.
– Architected real-time 1:1 and Multi-User Chat (XEP-045) utilizing Openfire and xmpp plugin, leveraging native Smack (Android) and XMPPFramework (iOS) APIs.
– Integrated local AI capabilities utilizing Gemma and E2B models via Flutter native channels, engineering features for chat summarization, contextual reply suggestions, and an embedded conversational chatbot.
– Optimized multimedia sharing with native libx264 video compression and engineered granular chat features including message reactions, forwarding, and debounced typing indicators.
– Built a secure communication pipeline featuring strict E2EE (AES, ECDH, HKDF) and custom push notification interceptors for token/topic-based routing.
– Managed end-to-end cross-platform deployments, actively debugging and resolving complex native iOS plugin issues to ensure seamless group chat integrations and stable macOS builds.

Software Engineer Intern Dyashin Technosoft Private limited
August 2025 – Present
– Enhancing skills in Core Java, Advanced Java, JDBC, Spring, Spring Boot, Hibernate ORM, and related backend frameworks. Working on designing and implementing scalable back-end services, database-driven applications, and RESTful APIs.

Software Engineer Intern EM Electronix Private Limited
September 2024 – December 2024
– Worked on Android development using Java, XML layout designing, SDK and Gradle plugins, emulator, activities, and fragments, along with Firebase for authentication, real-time database, and cloud storage. Trained in web development with Python, Flask, JavaScript, and Postman, focusing on RESTful APIs. Skilled in PostgreSQL for database management and back-end development. Mastered Git and GitHub, where I presented and managed projects efficiently.

Projects
Safe Chat – Secure Real-Time Messaging App
Engineered a comprehensive cross-platform chat application using Flutter, Openfire, and a custom backend. Built the real-time communication core using xmpp plugin (backed by native Smack and XMPPFramework) to handle XEP-045 group chats, reactions, and forwarding. Implemented VoIP video calling capabilities ensuring seamless real-time audio/video communication. Integrated strict End-to-End Encryption (E2EE), Integrated Gemma and E2B AI models via native channels to provide intelligent chat summarization, reply suggestions, and a native chatbot.optimized media sharing with libx264 compression, and designed custom push notification interceptors. Successfully managed native iOS/Android deployments, resolving deep native plugin codebase issues for flawless cross-platform performance.

Healvia – Full-stack centralized healthcare platform
Built using Python (Django REST Framework), React.js (ShadCN + TypeScript), PostgreSQL, and Flutter (Dart). Currently migrating backend services to Spring Boot (Java) for enhanced scalability, security, and microservices support. Developed a responsive web interface and real-time mobile app for AI-powered personalized diet and exercise recommendations based on health records. Key features: doctor suggestions, cross-hospital medication tracking, appointment scheduling, emergency alerts, health dashboards (heart rate, sleep), and secure patient-doctor messaging.

Project Manager Kotlin MVVM Architecture
Developed a Project Manager Android app using Android Studio with Kotlin and MVVM architecture. Implemented Material Design with a modern dashboard UI (Adobe XD to Android Studio XML). Integrated Room (SQLite) database for secure internal data storage, functioning similarly to SharedPreferences, ensuring offline-first capability and efficient project/task management.

Triplit App
Triplit App Built a travel app using Flutter and Dart, allowing users to create groups, chat, and split trip expenses. Integrated Firebase for authentication, real-time Firestore database, and a travel recommendation ML model built in Google Colab and deployed via Firebase. Future updates include a Spring Boot backend for enhanced functionality. Tech Stack: Flutter, Dart, Firebase (Auth, Firestore, ML), Google Colab, Spring Boot(planned).

Education
2021 - 2025 Bachelor’s Degree at Navkis College of Engineering in CSE (GPA: 9.15/10.0)
2021 Class 12th state Board (99.50)
2019 Class 10th State Board (96.80)

Skills
LANGUAGES: Java, Dart, Kotlin, C, SQL
DEVELOPER TOOLS: Android Studio, IntelliJ IDEA, VS code, Cursor AI, Anti Gravity
TECHNOLOGIES AND FRAMEWORKS: Github, Postman, Firebase, Flutter, XMPP (Openfire), Gemma, E2B
      ''';

      await _engine.ingestDocument(
        documentId: 'jeevan_resume',
        text: resumeText,
      );

      setState(() {
        _uiConsole += "Vector DB ready. You can now ask questions about the resume.";
        _isReady = true;
      });
    } catch (e) {
      setState(() => _uiConsole += "Boot Error: $e");
    }
  }

  void _askAi() {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _uiConsole = "Thinking... 🧠\n\n"; // 1. Show thinking state
      _isReady = false; // Disable button while generating
    });

    final stream = _engine.ask(_promptController.text);
    _promptController.clear(); // 2. Clear the text field immediately

    stream.listen(
          (token) {
        setState(() {
          // Remove "Thinking..." once the first token arrives
          if (_uiConsole.contains("Thinking...")) _uiConsole = "";
          _uiConsole += token;
        });
      },
      onError: (error) => setState(() => _uiConsole += "\nError: $error"),
      onDone: () => setState(() => _isReady = true), // Re-enable UI when done
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
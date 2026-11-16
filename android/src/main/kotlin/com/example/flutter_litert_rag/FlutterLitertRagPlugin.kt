package com.example.flutter_litert_rag

import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.ConversationConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collect

class FlutterLitertRagPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private var engine: Engine? = null
    // Create a dedicated scope for heavy LLM operations
    private val pluginScope = CoroutineScope(Dispatchers.IO + Job())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // MethodChannel handles single commands (initialize, dispose)
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_litert_rag_methods")
        methodChannel.setMethodCallHandler(this)

        // EventChannel streams the token generation back to Dart
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_litert_rag_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeLlm" -> {
                val modelPath = call.argument<String>("modelPath")
                if (modelPath != null) {
                    pluginScope.launch {
                        try {
                            val config = EngineConfig(modelPath = modelPath)
                            engine = Engine(config)
                            engine?.initialize() // Blocks thread while mapping 2.6GB file to RAM
                            withContext(Dispatchers.Main) {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("INIT_FAILED", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGS", "modelPath is required", null)
                }
            }
            "generateResponse" -> {
                val prompt = call.argument<String>("prompt")
                val activeEngine = engine // Capture in a local immutable variable for thread safety

                if (prompt != null && activeEngine != null) {
                    pluginScope.launch {
                        try {
                            val conversation = activeEngine.createConversation(ConversationConfig())
                            val responseFlow = conversation.sendMessageAsync(prompt)

                            // Collect tokens as they are generated and send to Flutter
                            responseFlow.collect { chunk ->
                                withContext(Dispatchers.Main) {
                                    // Use toString() to extract the raw string token from the Message object
                                    eventSink?.success(chunk.toString())
                                }
                            }
                            conversation.close()

                            // Send a termination signal when generation is complete
                            withContext(Dispatchers.Main) {
                                eventSink?.success("[DONE]")
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                eventSink?.error("GEN_ERROR", e.message, null)
                                result.error("GEN_FAILED", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_STATE", "Engine not initialized or prompt is null", null)
                }
            }
            "disposeLlm" -> {
                engine?.close()
                engine = null
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        pluginScope.cancel()
    }
}
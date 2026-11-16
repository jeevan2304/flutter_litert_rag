abstract class LlmEngineRepository {
  Future<void> initialize(String modelPath);
  Stream<String> generateResponse(String prompt);
  Future<void> close();
}
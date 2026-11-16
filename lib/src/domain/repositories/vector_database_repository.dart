import '../models/document_chunk.dart';

abstract class VectorDatabaseRepository {
  Future<void> initialize();
  Future<void> saveChunk(DocumentChunk chunk);
  Future<List<DocumentChunk>> searchSimilar(List<double> queryEmbedding, {int limit = 3});
  void close();
}
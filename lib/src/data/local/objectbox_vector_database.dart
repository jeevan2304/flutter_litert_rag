import 'package:objectbox/objectbox.dart';
import '../../../objectbox.g.dart';
import '../../domain/models/document_chunk.dart';
import '../../domain/repositories/vector_database_repository.dart';

class ObjectBoxVectorDatabase implements VectorDatabaseRepository {
  late final Store _store;
  late final Box<DocumentChunk> _chunkBox;

  @override
  Future<void> initialize() async {
    // In a plugin, the developer passing the directory path is handled later
    _store = await openStore();
    _chunkBox = _store.box<DocumentChunk>();
  }

  @override
  Future<void> saveChunk(DocumentChunk chunk) async {
    _chunkBox.put(chunk);
  }

  @override
  Future<List<DocumentChunk>> searchSimilar(List<double> queryEmbedding, {int limit = 3}) async {
    // This utilizes ObjectBox's native high-speed C++ vector search
    final query = _chunkBox
        .query(DocumentChunk_.embedding.nearestNeighborsF32(queryEmbedding, limit))
        .build();

    final results = query.find();
    query.close();

    return results;
  }

  @override
  void close() {
    _store.close();
  }
}
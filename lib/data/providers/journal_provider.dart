import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/boards_api.dart';
import '../models/journal_entry.dart';

final journalProvider = FutureProvider<List<JournalEntry>>((ref) {
  return ref.read(boardsApiProvider).getJournal();
});

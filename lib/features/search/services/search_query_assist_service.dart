import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:western_malabar/app/env.dart';

class SearchQueryAssistResult {
  final String searchQuery;
  final List<String> aliases;
  final String source;

  const SearchQueryAssistResult({
    required this.searchQuery,
    this.aliases = const [],
    this.source = 'local',
  });

  factory SearchQueryAssistResult.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['aliases'];
    final aliases = rawAliases is List
        ? rawAliases
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
        : const <String>[];

    final primary = (json['searchQuery'] ??
            json['normalizedQuery'] ??
            json['canonicalQuery'] ??
            '')
        .toString()
        .trim();

    return SearchQueryAssistResult(
      searchQuery: primary.isNotEmpty
          ? primary
          : (aliases.isNotEmpty ? aliases.first : ''),
      aliases: aliases,
      source: (json['source'] ?? 'local').toString(),
    );
  }
}

class SearchQueryAssistService {
  const SearchQueryAssistService();

  static const _functionName = 'normalize-search-query';

  Future<SearchQueryAssistResult?> resolve(String rawQuery) async {
    final q = rawQuery.trim();
    if (q.length < 3) return null;

    try {
      final response = await http
          .post(
            Uri.parse('${Env.supabaseUrl}/functions/v1/$_functionName'),
            headers: {
              'Content-Type': 'application/json',
              'apikey': Env.supabaseAnonKey,
              'Authorization': 'Bearer ${Env.supabaseAnonKey}',
            },
            body: jsonEncode({'query': q}),
          )
          .timeout(const Duration(milliseconds: 1400));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final result = SearchQueryAssistResult.fromJson(body);
      return result.searchQuery.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }
}

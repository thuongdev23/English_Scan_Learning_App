import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../services/review_service.dart';
import 'edit_saved_word_screen.dart';
import 'word_result_screen.dart';

class MyWordsScreen extends StatefulWidget {
  const MyWordsScreen({super.key});

  @override
  State<MyWordsScreen> createState() => _MyWordsScreenState();
}

class _MyWordsScreenState extends State<MyWordsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'New', 'Learning', 'Mastered'];

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =====================================================
  // SEARCH + FILTER
  // =====================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterWords(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      final data = document.data();

      final word = (data['word'] as String? ?? '').toLowerCase();

      final vietnamese = (data['vietnamese'] as String? ?? '').toLowerCase();

      final example = (data['example'] as String? ?? '').toLowerCase();

      final masteryLevel = (data['masteryLevel'] as num?)?.toInt() ?? 0;

      final query = _searchQuery.trim().toLowerCase();

      // SEARCH ENGLISH + VIETNAMESE + EXAMPLE
      final matchesSearch =
          query.isEmpty ||
          word.contains(query) ||
          vietnamese.contains(query) ||
          example.contains(query);

      // FILTER BY MASTERY
      bool matchesFilter;

      switch (_selectedFilter) {
        case 'New':
          matchesFilter = masteryLevel == 0;
          break;

        case 'Learning':
          matchesFilter = masteryLevel >= 1 && masteryLevel < 4;
          break;

        case 'Mastered':
          matchesFilter = masteryLevel >= 4;
          break;

        case 'All':
        default:
          matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: getUserWordsCollection()
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // ---------------------------------------------
          // LOADING
          // ---------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // ---------------------------------------------
          // ERROR
          // ---------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your words.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allDocuments = snapshot.data?.docs ?? [];

          // ---------------------------------------------
          // EMPTY
          // ---------------------------------------------

          if (allDocuments.isEmpty) {
            return const _EmptyWordsView();
          }

          final filteredDocuments = _filterWords(allDocuments);

          final groupedWords = _groupWordsByDay(filteredDocuments);

          // ---------------------------------------------
          // CONTENT
          // ---------------------------------------------

          return CustomScrollView(
            slivers: [
              // =========================================
              // HEADER
              // =========================================

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Words 📚',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        '${allDocuments.length} '
                        '${allDocuments.length == 1 ? 'word' : 'words'} saved',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // =================================
                      // SEARCH
                      // =================================
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search your words...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();

                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: Colors.deepPurple.shade300,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =================================
                      // FILTER CHIPS
                      // =================================
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final selected = _selectedFilter == filter;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                selectedColor: Colors.deepPurple.shade100,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.deepPurple.shade800
                                      : Colors.grey.shade700,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? Colors.deepPurple.shade200
                                      : Colors.grey.shade300,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // =================================
                      // RESULT COUNT
                      // =================================
                      if (_searchQuery.isNotEmpty ||
                          _selectedFilter != 'All') ...[
                        const SizedBox(height: 12),

                        Text(
                          '${filteredDocuments.length} '
                          '${filteredDocuments.length == 1 ? 'result' : 'results'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // =========================================
              // NO MATCHING RESULTS
              // =========================================
              if (filteredDocuments.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 52)),

                          const SizedBox(height: 14),

                          const Text(
                            'No matching words',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Try another search or filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),

                          const SizedBox(height: 16),

                          TextButton.icon(
                            onPressed: () {
                              _searchController.clear();

                              setState(() {
                                _searchQuery = '';
                                _selectedFilter = 'All';
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Clear filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // =========================================
              // DATE GROUPS
              // =========================================
              if (filteredDocuments.isNotEmpty)
                for (final group in groupedWords.entries) ...[
                  // -------------------------------------
                  // DATE HEADER
                  // -------------------------------------

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Text(
                            group.key,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${group.value.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -------------------------------------
                  // WORDS
                  // -------------------------------------
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final document = group.value[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SavedWordCard(document: document),
                        );
                      }, childCount: group.value.length),
                    ),
                  ),
                ],

              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          );
        },
      ),
    );
  }
}

// =====================================================
// GROUP WORDS BY DAY
// =====================================================

Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupWordsByDay(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
) {
  final result = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

  for (final document in documents) {
    final data = document.data();

    final timestamp = data['createdAt'];

    String label;

    if (timestamp is Timestamp) {
      label = _dateLabel(timestamp.toDate());
    } else {
      label = 'Recently added';
    }

    result.putIfAbsent(label, () => []).add(document);
  }

  return result;
}

// =====================================================
// FRIENDLY DATE LABEL
// =====================================================

String _dateLabel(DateTime date) {
  final now = DateTime.now();

  final today = DateTime(now.year, now.month, now.day);

  final value = DateTime(date.year, date.month, date.day);

  final difference = today.difference(value).inDays;

  if (difference == 0) {
    return 'Today';
  }

  if (difference == 1) {
    return 'Yesterday';
  }

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[value.month - 1]} '
      '${value.day}, ${value.year}';
}

// =====================================================
// SAVED WORD CARD
// =====================================================

class _SavedWordCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  const _SavedWordCard({required this.document});

  // ===================================================
  // DELETE WORD
  // ===================================================

  Future<void> _delete(
    BuildContext context,
    String word,
    String? imagePath,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete word?'),
          content: Text('Remove "$word" from My Words?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await deleteSavedWord(document.id);

      // Delete saved local image too.
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);

        if (await file.exists()) {
          await file.delete();
        }
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$word deleted.')));
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not delete word: $e')));
    }
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    final data = document.data();

    final word = data['word'] as String? ?? '';

    final vietnamese = data['vietnamese'] as String? ?? '';

    final example = data['example'] as String? ?? '';

    final imagePath = data['localImagePath'] as String?;

    final masteryLevel = (data['masteryLevel'] as num?)?.toInt() ?? 0;

    final masteryLabel = getMasteryLabel(masteryLevel);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        // ---------------------------------------------
        // OPEN WORD
        // ---------------------------------------------
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WordResultScreen(
                imagePath: imagePath,
                detectedWord: word,
                vietnamese: vietnamese,
                exampleSentence: example,
              ),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // =======================================
              // PHOTO
              // =======================================

              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 66,
                  height: 66,
                  child: _buildWordImage(imagePath),
                ),
              ),

              const SizedBox(width: 14),

              // =======================================
              // WORD INFORMATION
              // =======================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      vietnamese,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _MasteryBadge(
                      masteryLevel: masteryLevel,
                      masteryLabel: masteryLabel,
                    ),
                  ],
                ),
              ),

              // =======================================
              // EDIT / DELETE MENU
              // =======================================
              PopupMenuButton<String>(
                tooltip: 'Word options',
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditSavedWordScreen(
                          documentId: document.id,
                          word: word,
                          vietnamese: vietnamese,
                          example: example,
                        ),
                      ),
                    );
                  }

                  if (value == 'delete') {
                    _delete(context, word, imagePath);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================
  // WORD IMAGE
  // ===================================================

  Widget _buildWordImage(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);

      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    return Container(
      color: Colors.deepPurple.shade50,
      child: const Icon(Icons.image_outlined, color: Colors.deepPurple),
    );
  }
}

// =====================================================
// MASTERY BADGE
// =====================================================

class _MasteryBadge extends StatelessWidget {
  final int masteryLevel;
  final String masteryLabel;

  const _MasteryBadge({required this.masteryLevel, required this.masteryLabel});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    if (masteryLevel >= 4) {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (masteryLevel >= 1) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey.shade700;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            masteryLabel,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 7),

        Text(
          '$masteryLevel/5',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }
}

// =====================================================
// EMPTY WORDS
// =====================================================

class _EmptyWordsView extends StatelessWidget {
  const _EmptyWordsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 64)),

            const SizedBox(height: 18),

            const Text(
              'No words yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Scan something around you and save your first word.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

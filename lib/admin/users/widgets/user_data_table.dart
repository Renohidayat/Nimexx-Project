import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserDataTable extends StatefulWidget {
  const UserDataTable({super.key});

  @override
  State<UserDataTable> createState() => _UserDataTableState();
}

class _UserDataTableState extends State<UserDataTable> {
  bool _loading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _allUserData = [];
  List<Map<String, dynamic>> _displayedUserData = [];
  String _searchQuery = '';
  int _itemsPerPage = 10;
  int _currentPage = 1;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // Batasi jumlah data yang diambil untuk pertama kali
      final initialBatch = usersSnapshot.docs.take(50).toList();

      final dataList = await _fetchUserDetails(initialBatch);

      if (!mounted) return;

      setState(() {
        _allUserData = dataList;
        _applySearchSortAndPagination();
        _loading = false;
      });

      // Load sisa data di background
      if (usersSnapshot.docs.length > 50) {
        final remainingDocs = usersSnapshot.docs.skip(50).toList();
        final remainingData = await _fetchUserDetails(remainingDocs);

        if (mounted) {
          setState(() {
            _allUserData.addAll(remainingData);
            _applySearchSortAndPagination();
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Gagal memuat data user: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUserDetails(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final futures = docs.map((doc) async {
      try {
        final uid = doc.id;
        final data = doc.data() as Map<String, dynamic>;

        final email = data['email']?.toString() ?? '-';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        // Gunakan transaction untuk mengurangi jumlah read
        final favoritesRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favorites');

        final historyRef = FirebaseFirestore.instance
            .collection('watch_history')
            .doc(uid)
            .collection('history');

        // Hanya ambil count saja untuk mengurangi data transfer
        final favoritesCount = await favoritesRef.count().get();
        final historyCount = await historyRef.count().get();

        return {
          'uid': uid,
          'email': email,
          'createdAt': createdAt,
          'favoritesCount': favoritesCount.count,
          'historyCount': historyCount.count,
        };
      } catch (e) {
        debugPrint('Error processing user ${doc.id}: $e');
        return null;
      }
    });

    final results = await Future.wait(futures);
    return results.whereType<Map<String, dynamic>>().toList();
  }

  void _applySearchSortAndPagination() {
    // Filter data berdasarkan search query
    final filtered =
        _allUserData.where((user) {
          if (_searchQuery.isEmpty) return true;

          final keyword = _searchQuery.toLowerCase();
          return user['email'].toString().toLowerCase().contains(keyword) ||
              user['uid'].toString().toLowerCase().contains(keyword);
        }).toList();

    // Sorting
    filtered.sort((a, b) {
      final aValue = _getSortValue(a, _sortColumnIndex);
      final bValue = _getSortValue(b, _sortColumnIndex);

      if (aValue == null) return _sortAscending ? 1 : -1;
      if (bValue == null) return _sortAscending ? -1 : 1;

      if (aValue is String && bValue is String) {
        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      } else if (aValue is num && bValue is num) {
        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      }
      return 0;
    });

    // Pagination
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    _displayedUserData = filtered.sublist(
      startIndex.clamp(0, filtered.length),
      endIndex.clamp(0, filtered.length),
    );
  }

  dynamic _getSortValue(Map<String, dynamic> user, int columnIndex) {
    switch (columnIndex) {
      case 0:
        return user['email'];
      case 1:
        return user['uid'];
      case 2:
        return user['createdAt'];
      case 3:
        return user['favoritesCount'];
      case 4:
        return user['historyCount'];
      default:
        return null;
    }
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _applySearchSortAndPagination();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          "Gagal memuat data pengguna",
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadUserData,
          child: const Text("Coba Lagi"),
        ),
      ],
    );
  }

  Widget _buildSearchAndControls(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: "Cari Email atau UID...",
              hintStyle: TextStyle(color: theme.hintColor),
              filled: true,
              fillColor: isDarkMode ? Colors.black26 : Colors.grey[100],
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 1;
                _applySearchSortAndPagination();
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        DropdownButton<int>(
          value: _itemsPerPage,
          items:
              [10, 25, 50, 100].map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text("$value baris"),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _itemsPerPage = value;
                _currentPage = 1;
                _applySearchSortAndPagination();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaginationControls(int filteredCount) {
    final totalPages = (filteredCount / _itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed:
              _currentPage > 1
                  ? () {
                    setState(() {
                      _currentPage--;
                      _applySearchSortAndPagination();
                    });
                  }
                  : null,
        ),
        Text(
          'Halaman $_currentPage/$totalPages',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed:
              _currentPage < totalPages
                  ? () {
                    setState(() {
                      _currentPage++;
                      _applySearchSortAndPagination();
                    });
                  }
                  : null,
        ),
      ],
    );
  }

  Widget _buildDataTable(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final filteredCount =
        _allUserData.where((user) {
          if (_searchQuery.isEmpty) return true;
          final keyword = _searchQuery.toLowerCase();
          return user['email'].toString().toLowerCase().contains(keyword) ||
              user['uid'].toString().toLowerCase().contains(keyword);
        }).length;

    return Column(
      children: [
        Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          thickness: 6,
          radius: const Radius.circular(8),
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            scrollDirection: Axis.vertical,
            child: Scrollbar(
              controller: _horizontalScrollController,
              thumbVisibility: true,
              thickness: 6,
              radius: const Radius.circular(8),
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                  ),
                  dataRowColor: MaterialStateProperty.all(
                    isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                  ),
                  columnSpacing: 20,
                  dividerThickness: 0.4,
                  headingTextStyle: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                  ),
                  dataTextStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 13,
                  ),
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  columns: [
                    DataColumn(label: const Text("Email"), onSort: _onSort),
                    DataColumn(label: const Text("UID"), onSort: _onSort),
                    DataColumn(
                      label: const Text("Tanggal Daftar"),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text("Favorit"),
                      onSort: _onSort,
                      numeric: true,
                    ),
                    DataColumn(
                      label: const Text("Histori"),
                      onSort: _onSort,
                      numeric: true,
                    ),
                  ],
                  rows:
                      _displayedUserData.map((user) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Tooltip(
                                message: user['email'] ?? '',
                                child: Text(
                                  user['email'] ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            DataCell(
                              Tooltip(
                                message: user['uid'] ?? '',
                                child: SelectableText(
                                  user['uid'] ?? '',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(_formatDate(user['createdAt']))),
                            DataCell(
                              Center(
                                child: Chip(
                                  label: Text(
                                    user['favoritesCount'].toString(),
                                  ),
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  labelStyle: TextStyle(
                                    color: theme.colorScheme.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Chip(
                                  label: Text(user['historyCount'].toString()),
                                  backgroundColor: theme.colorScheme.secondary
                                      .withOpacity(0.1),
                                  labelStyle: TextStyle(
                                    color: theme.colorScheme.secondary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildPaginationControls(filteredCount),
        const SizedBox(height: 8),
        Text(
          "Menampilkan ${_displayedUserData.length} dari $filteredCount pengguna "
          "(Total: ${_allUserData.length})",
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? _buildErrorWidget()
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Tabel Pengguna",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: "Refresh Data",
                        onPressed: _loadUserData,
                        color: theme.iconTheme.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSearchAndControls(context),
                  const SizedBox(height: 16),
                  if (_displayedUserData.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _searchQuery.isEmpty
                              ? "Tidak ada data pengguna"
                              : "❌ Tidak ada hasil ditemukan untuk '$_searchQuery'",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  if (_displayedUserData.isNotEmpty) _buildDataTable(context),
                ],
              ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/dashboard_search_provider.dart';

class DashboardSearchBar extends ConsumerStatefulWidget {
  const DashboardSearchBar({super.key});

  @override
  ConsumerState<DashboardSearchBar> createState() => _DashboardSearchBarState();
}

class _DashboardSearchBarState extends ConsumerState<DashboardSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _controller,
        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: '농가명 또는 디바이스명 검색',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon:
              query.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = "";
                    },
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../providers/city_search_provider.dart';
import 'animated_search_placeholder.dart';
import 'search_placeholder_phrases.dart';

/// The text field half of the search bar: a plain `TextField` with a
/// rotating [AnimatedSearchPlaceholder] behind it (shown only while
/// empty), a clear button once there's text, and debounced search.
///
/// Debouncing lives here rather than in [CitySearchNotifier] so the
/// notifier stays a plain, synchronously testable "call it, await it"
/// unit — this widget's `Timer` is what's under test with
/// `WidgetTester.pump(duration)`.
class SearchInputField extends ConsumerStatefulWidget {
  const SearchInputField({
    required this.controller,
    required this.focusNode,
    this.debounceDuration = const Duration(milliseconds: 400),
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Duration debounceDuration;

  @override
  ConsumerState<SearchInputField> createState() => _SearchInputFieldState();
}

class _SearchInputFieldState extends ConsumerState<SearchInputField> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  /// Toggles the placeholder/clear-button visibility on every keystroke —
  /// including a clear the parent triggers externally (e.g. a "use my
  /// location" button that calls `controller.clear()` directly), since
  /// this listens to the controller rather than `TextField.onChanged`.
  void _handleTextChanged() => setState(() {});

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      ref.read(citySearchProvider.notifier).search(value);
    });
  }

  void _searchNow(String value) {
    _debounce?.cancel();
    ref.read(citySearchProvider.notifier).search(value);
  }

  void _onClear() {
    _debounce?.cancel();
    widget.controller.clear();
    ref.read(citySearchProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = widget.controller.text.isEmpty;

    return Row(
      children: [
        Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (isEmpty)
                const IgnorePointer(
                  child: AnimatedSearchPlaceholder(phrases: kSearchPlaceholderPhrases),
                ),
              TextField(
                key: const Key('citySearchTextField'),
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: _scheduleSearch,
                onSubmitted: _searchNow,
                textInputAction: TextInputAction.search,
                style: theme.textTheme.bodyMedium,
                cursorColor: theme.colorScheme.primary,
                decoration: const InputDecoration(
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        if (!isEmpty)
          IconButton(
            key: const Key('citySearchClearButton'),
            onPressed: _onClear,
            icon: const Icon(Icons.close),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            color: theme.colorScheme.onSurfaceVariant,
            tooltip: 'Clear search',
          ),
      ],
    );
  }
}

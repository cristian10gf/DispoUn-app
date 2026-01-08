import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';

/// Widget de input de busqueda reutilizable
class SearchInput extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final bool autofocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const SearchInput({
    super.key,
    this.hintText = AppStrings.search,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onSubmitted: widget.onSubmitted,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon ?? const Icon(Icons.search),
        suffixIcon: _hasText
            ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearText)
            : widget.suffixIcon,
      ),
    );
  }
}

/// Widget de busqueda con debounce
class DebouncedSearchInput extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final Duration debounceDuration;
  final TextEditingController? controller;

  const DebouncedSearchInput({
    super.key,
    this.hintText = AppStrings.search,
    required this.onChanged,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.controller,
  });

  @override
  State<DebouncedSearchInput> createState() => _DebouncedSearchInputState();
}

class _DebouncedSearchInputState extends State<DebouncedSearchInput> {
  late TextEditingController _controller;
  String _lastValue = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value) {
    if (value == _lastValue) return;
    _lastValue = value;

    Future.delayed(widget.debounceDuration, () {
      if (_controller.text == value) {
        widget.onChanged(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SearchInput(
      controller: _controller,
      hintText: widget.hintText,
      onChanged: _onChanged,
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// Shared search surface for community discovery and the private library.
class SoundShareSearchField extends StatefulWidget {
  const SoundShareSearchField({
    super.key,
    required this.controller,
    this.hintText,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.compact = false,
    this.enableShortcut = false,
  });

  final TextEditingController controller;
  final String? hintText, label;
  final ValueChanged<String>? onChanged, onSubmitted;
  final VoidCallback? onClear;
  final bool compact, enableShortcut;

  @override
  State<SoundShareSearchField> createState() => _SoundShareSearchFieldState();
}

class _SoundShareSearchFieldState extends State<SoundShareSearchField>
    with AutomaticKeepAliveClientMixin {
  final _focus = FocusNode();
  bool _hovered = false;
  bool _active = false;

  @override
  bool get wantKeepAlive => widget.enableShortcut;

  @override
  void didUpdateWidget(covariant SoundShareSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableShortcut != widget.enableShortcut) updateKeepAlive();
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleShortcut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _active =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
  }

  bool _handleShortcut(KeyEvent event) {
    final keyboard = HardwareKeyboard.instance;
    if (!mounted ||
        !widget.enableShortcut ||
        !_active ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.keyK ||
        !(keyboard.isControlPressed || keyboard.isMetaPressed) ||
        keyboard.isAltPressed) {
      return false;
    }
    _focus.requestFocus();
    return true;
  }

  void _clear() {
    widget.controller.clear();
    if (widget.onClear != null) {
      widget.onClear!();
    } else {
      widget.onChanged?.call('');
    }
    _focus.requestFocus();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleShortcut);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.colors;
    final t = context.l10n;
    final platform = Theme.of(context).platform;
    final shortcut =
        platform == TargetPlatform.macOS || platform == TargetPlatform.iOS
        ? '⌘ K'
        : 'Ctrl K';
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _focus.hasFocus) {
          _focus.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.controller, _focus]),
          builder: (context, _) => LayoutBuilder(
            builder: (context, bounds) {
              final hasText = widget.controller.text.isNotEmpty;
              final showShortcut =
                  widget.enableShortcut &&
                  !hasText &&
                  bounds.maxWidth >= 360 &&
                  MediaQuery.textScalerOf(context).scale(14) < 20;
              return TextFieldTapRegion(
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: _focus.hasFocus
                        ? colors.surface
                        : colors.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      widget.compact ? 24 : 30,
                    ),
                    border: Border.all(
                      color: _focus.hasFocus
                          ? colors.primary
                          : _hovered
                          ? colors.secondaryText
                          : colors.fieldBorder,
                    ),
                    boxShadow: [
                      if (_focus.hasFocus)
                        BoxShadow(
                          color: colors.primary.withValues(alpha: .12),
                          spreadRadius: 3,
                        ),
                    ],
                  ),
                  child: Semantics(
                    label: widget.label ?? t.searchLabel,
                    hint: widget.enableShortcut
                        ? t.searchShortcut(shortcut)
                        : null,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      onTapOutside: (_) => _focus.unfocus(),
                      maxLength: 120,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(fontSize: widget.compact ? 14 : 16),
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? t.searchHint,
                        hintStyle: TextStyle(color: colors.secondaryText),
                        counterText: '',
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.only(
                          top: widget.compact ? 14 : 19,
                          bottom: widget.compact ? 14 : 19,
                          right: !hasText && !showShortcut ? 20 : 0,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: _focus.hasFocus
                              ? colors.primary
                              : colors.secondaryText,
                        ),
                        prefixIconConstraints: BoxConstraints(
                          minWidth: widget.compact ? 48 : 56,
                          minHeight: 48,
                        ),
                        suffixIcon: !hasText && !showShortcut
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (showShortcut)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: Tooltip(
                                        message: t.searchShortcut(shortcut),
                                        child: ExcludeSemantics(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.surface,
                                              border: Border.all(
                                                color: colors.border,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              shortcut,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colors.secondaryText,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (hasText)
                                    IconButton(
                                      tooltip: t.clearSearch,
                                      onPressed: _clear,
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                      ),
                                    ),
                                  if (hasText && widget.onSubmitted != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: IconButton.filled(
                                        tooltip: t.search,
                                        onPressed: () => widget.onSubmitted!(
                                          widget.controller.text,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: colors.action,
                                          foregroundColor: colors.onAction,
                                          minimumSize: const Size(48, 48),
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

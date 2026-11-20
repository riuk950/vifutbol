import 'package:material_ui/material_ui.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_colors.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_radii_spacing.dart';
import 'package:vifutbol/presentation/design_system/kick_pulse_typography.dart';

/// Reusable real-time search bar adhering to KickPulse Mobile tokens and ergonomic
/// touch constraints (>= 44px height and fast-clear action).
class KickPulseSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const KickPulseSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.controller,
    this.focusNode,
  });

  @override
  State<KickPulseSearchBar> createState() => _KickPulseSearchBarState();
}

class _KickPulseSearchBarState extends State<KickPulseSearchBar> {
  late final TextEditingController _internalController;
  late final FocusNode _internalFocusNode;
  bool _isOwnController = false;
  bool _isOwnFocusNode = false;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController();
      _isOwnController = true;
    }
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      _isOwnFocusNode = true;
    }
    _effectiveController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onTextChanged);
    if (_isOwnController) {
      _internalController.dispose();
    }
    if (_isOwnFocusNode) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _clearSearch() {
    _effectiveController.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _effectiveController.text.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(
        minHeight: KickPulseRadiiSpacing.minTouchTarget,
      ),
      decoration: BoxDecoration(
        color: KickPulseColors.surfaceBase,
        borderRadius: BorderRadius.circular(KickPulseRadiiSpacing.chipRadius),
        border: Border.all(
          color: _effectiveFocusNode.hasFocus
              ? KickPulseColors.accentPrimary
              : KickPulseColors.borderSubtle,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Center(
        child: TextField(
          controller: _effectiveController,
          focusNode: _effectiveFocusNode,
          style: KickPulseTypography.bodyPrimary.copyWith(
            color: KickPulseColors.textPrimary,
          ),
          onChanged: widget.onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: widget.hintText,
            hintStyle: KickPulseTypography.bodyPrimary.copyWith(
              color: KickPulseColors.textTertiary,
            ),
            icon: const Icon(
              Icons.search,
              size: 20.0,
              color: KickPulseColors.textSecondary,
            ),
            suffixIcon: hasText
                ? IconButton(
                    key: const Key('search_bar_clear_button'),
                    icon: const Icon(
                      Icons.clear,
                      size: 18.0,
                      color: KickPulseColors.textSecondary,
                    ),
                    splashRadius: 20.0,
                    constraints: const BoxConstraints(
                      minWidth: KickPulseRadiiSpacing.minTouchTarget,
                      minHeight: KickPulseRadiiSpacing.minTouchTarget,
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

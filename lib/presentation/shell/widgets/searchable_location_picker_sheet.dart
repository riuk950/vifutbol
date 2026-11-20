import 'package:material_ui/material_ui.dart';

import '../../design_system/kick_pulse_colors.dart';
import '../../design_system/kick_pulse_radii_spacing.dart';
import '../../design_system/kick_pulse_typography.dart';

/// Searchable modal bottom sheet for selecting a Colombian department or municipality.
class SearchableLocationPickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedItem;
  final String searchPlaceholder;
  final String emptyMessage;

  const SearchableLocationPickerSheet({
    super.key,
    required this.title,
    required this.items,
    this.selectedItem,
    required this.searchPlaceholder,
    required this.emptyMessage,
  });

  /// Displays the modal bottom sheet and returns the selected item or null.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> items,
    String? selectedItem,
    required String searchPlaceholder,
    required String emptyMessage,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchableLocationPickerSheet(
        title: title,
        items: items,
        selectedItem: selectedItem,
        searchPlaceholder: searchPlaceholder,
        emptyMessage: emptyMessage,
      ),
    );
  }

  @override
  State<SearchableLocationPickerSheet> createState() =>
      _SearchableLocationPickerSheetState();
}

class _SearchableLocationPickerSheetState
    extends State<SearchableLocationPickerSheet> {
  late final TextEditingController _searchController;
  late List<String> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final normalized = _normalize(query);
    setState(() {
      if (normalized.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => _normalize(item).contains(normalized))
            .toList(growable: false);
      }
    });
  }

  static String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Material(
      color: KickPulseColors.surfaceElevated,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(KickPulseRadiiSpacing.cardRadius),
      ),
      child: SizedBox(
        height: mediaQuery.size.height * 0.75,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: KickPulseRadiiSpacing.spaceSm),
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KickPulseColors.textSecondary.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: KickPulseRadiiSpacing.spaceMd),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceMd,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: KickPulseTypography.cardTitle,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: KickPulseColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KickPulseRadiiSpacing.spaceMd,
                  vertical: KickPulseRadiiSpacing.spaceXs,
                ),
                child: TextField(
                  key: const Key('location_picker_search_field'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  autofocus: false,
                  style: KickPulseTypography.bodyPrimary,
                  decoration: InputDecoration(
                    hintText: widget.searchPlaceholder,
                    hintStyle: KickPulseTypography.bodyPrimary.copyWith(
                      color: KickPulseColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: KickPulseColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            color: KickPulseColors.textSecondary,
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: KickPulseColors.surfaceBase,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: KickPulseRadiiSpacing.spaceMd,
                      vertical: KickPulseRadiiSpacing.spaceSm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        KickPulseRadiiSpacing.chipRadius,
                      ),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Divider(color: KickPulseColors.borderSubtle, height: 1),
              // List or Empty State
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            KickPulseRadiiSpacing.spaceLg,
                          ),
                          child: Text(
                            widget.emptyMessage,
                            key: const Key('location_picker_empty_state'),
                            style: KickPulseTypography.captionMeta,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        key: const Key('location_picker_list'),
                        itemCount: _filteredItems.length,
                        itemBuilder: (ctx, index) {
                          final item = _filteredItems[index];
                          final isSelected = item == widget.selectedItem;

                          return ListTile(
                            title: Text(
                              item,
                              style: KickPulseTypography.bodyPrimary.copyWith(
                                color: isSelected
                                    ? KickPulseColors.accentWarning
                                    : KickPulseColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: KickPulseColors.accentWarning,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

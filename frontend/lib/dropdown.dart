import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TextFieldMultipleDropDown extends StatefulWidget {
  final List<String> options;
  final String text;
  final Function(List<String>) onSelectedItemsChanged;
  final List<String>? initialValues;
  final bool? disabled;

  const TextFieldMultipleDropDown({
    super.key,
    required this.options,
    required this.text,
    required this.onSelectedItemsChanged,
    this.initialValues,
    this.disabled,
  });

  @override
  State<TextFieldMultipleDropDown> createState() =>
      _TextFieldMultipleDropDownState();
}

class _TextFieldMultipleDropDownState extends State<TextFieldMultipleDropDown> {
  final List<String> _selectedItems = [];
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValues != null) {
      _selectedItems.addAll(widget.initialValues!);
      widget.onSelectedItemsChanged(_selectedItems);
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      items: widget.options,
      isMultiSelect: true,
      showSearchField: true,
      showSelectAllButton: true,
      hintText: widget.text,
      itemBuilder: (item) {
        return Text(
          item,
          style: TextStyle(
            fontSize: 16,
            overflow: TextOverflow.ellipsis,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        );
      },
      onChanged: (value) {
        widget.onSelectedItemsChanged(value);
      },
    );
  }
}

class TextFieldSingleDropDown extends StatefulWidget {
  final List<String> options;
  final String text;
  final Function(String) onSelectedItemsChanged;
  final String? initialValue;
  final bool? disabled;

  const TextFieldSingleDropDown({
    super.key,
    required this.options,
    required this.text,
    required this.onSelectedItemsChanged,
    required this.initialValue,
    this.disabled,
  });

  @override
  State<TextFieldSingleDropDown> createState() =>
      _TextFieldSingleDropDownState();
}

class _TextFieldSingleDropDownState extends State<TextFieldSingleDropDown> {
  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      isMultiSelect: false,
      showSearchField: false,
      items: widget.options,
      selectedItems: widget.initialValue != null ? [widget.initialValue!] : [],
      itemBuilder: (item) {
        return Text(
          item,
          style: TextStyle(
            fontSize: 16,
            overflow: TextOverflow.ellipsis,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        );
      },
      onChanged: (value) {
        widget.onSelectedItemsChanged(value);
      },
    );
  }
}

class CustomDropdown<T> extends StatefulWidget {
  final List<T> items;
  final List<T> selectedItems;
  final bool isMultiSelect;
  final bool showSearchField;
  final bool showSelectAllButton;
  final String hintText;
  final Widget Function(T item) itemBuilder;
  final ValueChanged onChanged;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    this.selectedItems = const [],
    this.isMultiSelect = false,
    this.showSearchField = true,
    this.showSelectAllButton = false,
    this.hintText = "Bitte auswählen...",
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final TextEditingController _searchController = TextEditingController();
  late List<T> _filteredItems;
  late List<T> _selected;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _selected = List.from(widget.selectedItems);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _removeDropdown();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items
          .where((item) =>
              widget.itemBuilder(item).toString().toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _removeDropdown();
    }

    setState(() {});
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchController.clear();
    setState(() {
      _filteredItems = widget.items;
    });
  }

  void _toggleAll(bool selectAll) {
    setState(() {
      _selected = selectAll ? List.from(widget.items) : [];
    });
    widget.onChanged(_selected);
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeDropdown,
              child: Container(),
            ),
          ),
          Positioned(
            width: size.width,
            left: offset.dx,
            top: offset.dy + size.height,
            child: CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(0.0, size.height + 5.0),
              showWhenUnlinked: false,
              child: Material(
                elevation: 4.0,
                child: StatefulBuilder(
                  builder: (context, menuSetState) => Container(
                    constraints: BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dialogTheme.backgroundColor,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showSearchField)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 50,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText:
                                      "${AppLocalizations.of(context).search}...",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        if (widget.isMultiSelect && widget.showSelectAllButton)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(
                                    () => _toggleAll(true),
                                  );
                                  menuSetState(() {});
                                },
                                child: Text(
                                    AppLocalizations.of(context).selectAll),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(
                                    () => _toggleAll(false),
                                  );

                                  menuSetState(() {});
                                },
                                child: Text(
                                    AppLocalizations.of(context).deselectAll),
                              ),
                            ],
                          ),
                        if (widget.showSearchField ||
                            (widget.showSelectAllButton &&
                                widget.isMultiSelect))
                          const Divider(height: 0.5),
                        Expanded(
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              children: _filteredItems.map((item) {
                                final selected = _selected.contains(item);

                                return widget.isMultiSelect
                                    ? CheckboxListTile(
                                        title: widget.itemBuilder(item),
                                        value: selected,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            value == true
                                                ? _selected.add(item)
                                                : _selected.remove(item);
                                          });
                                          menuSetState(() {});
                                          widget.onChanged(_selected);
                                        },
                                      )
                                    : ListTile(
                                        title: widget.itemBuilder(item),
                                        onTap: () {
                                          setState(() {
                                            _selected = [item];
                                            widget.onChanged(_selected.last);
                                            _removeDropdown();
                                          });
                                        },
                                      );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: AbsorbPointer(
          child: TextFormField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: widget.hintText,
              suffixIcon: _overlayEntry == null
                  ? const Icon(Icons.arrow_drop_down)
                  : const Icon(Icons.arrow_drop_up),
            ),
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
            ),
            controller: TextEditingController(
              text: widget.isMultiSelect
                  ? _selected.map((e) => e.toString()).join(', ')
                  : (_selected.isNotEmpty ? _selected.first.toString() : ''),
            ),
          ),
        ),
      ),
    );
  }
}

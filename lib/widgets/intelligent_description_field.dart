import 'package:flutter/material.dart';
import '../services/intelligent_autocomplete_service.dart';

class IntelligentDescriptionField extends StatefulWidget {
  final TextEditingController controller;
  final String userId;
  final Function(String)? onDescriptionSelected;

  const IntelligentDescriptionField({
    super.key,
    required this.controller,
    required this.userId,
    this.onDescriptionSelected,
  });

  @override
  State<IntelligentDescriptionField> createState() => _IntelligentDescriptionFieldState();
}

class _IntelligentDescriptionFieldState extends State<IntelligentDescriptionField> {
  final IntelligentAutoCompleteService _autoCompleteService = IntelligentAutoCompleteService();
  List<ExpenseSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _autoCompleteService.initialize();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.length >= 2) {
      _getSuggestions(text);
    } else {
      _hideSuggestions();
    }
  }

  Future<void> _getSuggestions(String input) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await _autoCompleteService.getSuggestions(input, widget.userId);
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
        
        if (suggestions.isNotEmpty) {
          _showSuggestionsOverlay();
        } else {
          _hideSuggestions();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _suggestions = [];
        });
        _hideSuggestions();
      }
    }
  }

  void _showSuggestionsOverlay() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return _buildSuggestionItem(suggestion);
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showSuggestions = true;
    });
  }

  Widget _buildSuggestionItem(ExpenseSuggestion suggestion) {
    IconData icon;
    Color iconColor;
    
    switch (suggestion.type) {
      case SuggestionType.personal:
        icon = Icons.history;
        iconColor = Colors.blue;
        break;
      case SuggestionType.indian:
        icon = Icons.local_offer;
        iconColor = Colors.orange;
        break;
      case SuggestionType.pattern:
        icon = Icons.lightbulb;
        iconColor = Colors.green;
        break;
    }

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, size: 16, color: iconColor),
      ),
      title: Text(
        suggestion.text,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: _buildSubtitle(suggestion),
      onTap: () => _selectSuggestion(suggestion.text),
    );
  }

  Widget? _buildSubtitle(ExpenseSuggestion suggestion) {
    if (suggestion.type == SuggestionType.personal && suggestion.frequency > 1) {
      return Text(
        'Used ${suggestion.frequency} times',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    }
    
    if (suggestion.type == SuggestionType.indian) {
      return Text(
        'Popular in India',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    }
    
    return null;
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.onDescriptionSelected?.call(suggestion);
    _hideSuggestions();
  }

  void _hideSuggestions() {
    _removeOverlay();
    setState(() {
      _showSuggestions = false;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: 'Description',
          prefixIcon: const Icon(Icons.description),
          suffixIcon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _showSuggestions
                  ? IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up),
                      onPressed: _hideSuggestions,
                    )
                  : null,
          helperText: 'Type to get smart suggestions from your history',
        ),
        onTap: () {
          if (widget.controller.text.length >= 2 && _suggestions.isNotEmpty) {
            _showSuggestionsOverlay();
          }
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a description';
          }
          return null;
        },
      ),
    );
  }
}
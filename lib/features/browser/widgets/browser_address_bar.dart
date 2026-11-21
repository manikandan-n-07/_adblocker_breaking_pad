import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/browser_tab.dart';
import '../utils/browser_constants.dart';
import '../utils/url_helper.dart';
import 'protection_shield.dart';

class BrowserAddressBar extends StatefulWidget {
  final BrowserTab tab;
  final ValueChanged<String> onNavigate;
  final VoidCallback onReload;
  final VoidCallback onStop;

  const BrowserAddressBar({
    super.key,
    required this.tab,
    required this.onNavigate,
    required this.onReload,
    required this.onStop,
  });

  @override
  State<BrowserAddressBar> createState() => _BrowserAddressBarState();
}

class _BrowserAddressBarState extends State<BrowserAddressBar> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.tab.url);
    _focusNode.addListener(() {
      setState(() {
        _isEditing = _focusNode.hasFocus;
        if (_isEditing) {
          _textController.text = widget.tab.url == 'about:blank' ? '' : widget.tab.url;
          _textController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _textController.text.length,
          );
        }
      });
    });
  }

  @override
  void didUpdateWidget(BrowserAddressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && widget.tab.url != oldWidget.tab.url) {
      _textController.text = widget.tab.url == 'about:blank' ? '' : widget.tab.url;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    _focusNode.unfocus();
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onNavigate(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHttps = UrlHelper.isSecure(widget.tab.url);
    final domain = UrlHelper.extractDomain(widget.tab.url);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: BrowserConstants.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _isEditing ? Colors.white : BrowserConstants.borderLight,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Security / Lock Indicator
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                isHttps ? Icons.lock_outline : Icons.info_outline,
                size: 16,
                color: Colors.white,
              ),
            ),

          const SizedBox(width: 8),

          // URL / Input TextField
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search or enter address',
                      hintStyle: TextStyle(color: BrowserConstants.textSecondary, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _submit(),
                  )
                : GestureDetector(
                    onTap: () => _focusNode.requestFocus(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        domain.isEmpty
                            ? (widget.tab.url.isEmpty || widget.tab.url == 'about:blank'
                                ? 'Search or type URL'
                                : widget.tab.url)
                            : domain,
                        style: TextStyle(
                          color: domain.isEmpty
                              ? BrowserConstants.textSecondary
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: domain.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
          ),

          // If editing: Paste and Clear buttons
          if (_isEditing) ...[
            if (_textController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 18, color: Colors.white),
                onPressed: () {
                  _textController.clear();
                  setState(() {});
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            IconButton(
              icon: const Icon(Icons.paste, size: 16, color: Colors.white),
              tooltip: 'Paste',
              onPressed: () async {
                final data = await Clipboard.getData('text/plain');
                if (data?.text != null) {
                  _textController.text = data!.text!;
                  _submit();
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ] else ...[
            // Protection Shield with Blocked Count Badge
            GestureDetector(
              onTap: () => ProtectionShieldSheet.show(context, widget.tab),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: BrowserConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BrowserConstants.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield,
                      size: 15,
                      color: Colors.white,
                    ),
                    if (widget.tab.blockedCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${widget.tab.blockedCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Reload or Stop Button
            IconButton(
              icon: Icon(
                widget.tab.isLoading ? Icons.close : Icons.refresh,
                size: 18,
                color: Colors.white,
              ),
              onPressed: widget.tab.isLoading ? widget.onStop : widget.onReload,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Widget render markdown block-level: heading, list, paragraph
/// + inline: **bold**, *italic*, `code`.
/// Nhẹ, không cần package, đủ đẹp cho AI chat / insight.
class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MarkdownText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle();
    final blocks = _splitBlocks(text);

    final widgets = <Widget>[];
    for (int i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      widgets.add(_renderBlock(b, base));
      if (i < blocks.length - 1) {
        widgets.add(SizedBox(height: _gapFor(b, blocks[i + 1])));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  double _gapFor(_Block prev, _Block next) {
    if (prev.kind == _Kind.heading || next.kind == _Kind.heading) return 8;
    if (prev.kind == _Kind.listItem && next.kind == _Kind.listItem) return 4;
    return 6;
  }

  Widget _renderBlock(_Block b, TextStyle base) {
    switch (b.kind) {
      case _Kind.heading:
        final size = (base.fontSize ?? 14) + (b.headingLevel == 1 ? 4 : 2);
        final hStyle = base.merge(TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: size,
          height: 1.3,
        ));
        return _rich(b.text, hStyle);

      case _Kind.listItem:
        final marker = b.orderedIndex != null ? '${b.orderedIndex}.' : '•';
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: b.orderedIndex != null ? 22 : 16,
                child: Text(
                  marker,
                  style: base.merge(const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              Expanded(child: _rich(b.text, base)),
            ],
          ),
        );

      case _Kind.paragraph:
        return _rich(b.text, base);
    }
  }

  Widget _rich(String input, TextStyle base) {
    return RichText(
      text: TextSpan(style: base, children: _parseInline(input, base)),
    );
  }

  // ========== Block splitter ==========
  List<_Block> _splitBlocks(String raw) {
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final blocks = <_Block>[];
    final paraBuf = <String>[];

    void flushPara() {
      if (paraBuf.isEmpty) return;
      blocks.add(_Block(
        kind: _Kind.paragraph,
        text: paraBuf.join(' ').trim(),
      ));
      paraBuf.clear();
    }

    final headingRe = RegExp(r'^(#{1,6})\s+(.+)$');
    final ulRe = RegExp(r'^\s*[-*•]\s+(.+)$');
    final olRe = RegExp(r'^\s*(\d+)\.\s+(.+)$');

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        flushPara();
        continue;
      }
      final h = headingRe.firstMatch(line);
      if (h != null) {
        flushPara();
        blocks.add(_Block(
          kind: _Kind.heading,
          text: h.group(2)!.trim(),
          headingLevel: h.group(1)!.length,
        ));
        continue;
      }
      final ol = olRe.firstMatch(line);
      if (ol != null) {
        flushPara();
        blocks.add(_Block(
          kind: _Kind.listItem,
          text: ol.group(2)!.trim(),
          orderedIndex: int.tryParse(ol.group(1)!),
        ));
        continue;
      }
      final ul = ulRe.firstMatch(line);
      if (ul != null) {
        flushPara();
        blocks.add(_Block(kind: _Kind.listItem, text: ul.group(1)!.trim()));
        continue;
      }
      paraBuf.add(line.trim());
    }
    flushPara();
    return blocks;
  }

  // ========== Inline parser ==========
  List<InlineSpan> _parseInline(String input, TextStyle base) {
    final spans = <InlineSpan>[];
    // ***bold italic*** | **bold** | *italic* | `code` | ~~strike~~
    final pattern = RegExp(
      r'(\*\*\*([^*]+)\*\*\*)|(\*\*([^*]+)\*\*)|(\*([^*\s][^*]*?)\*)|(`([^`]+)`)|(~~([^~]+)~~)',
      multiLine: true,
    );

    int lastEnd = 0;
    for (final match in pattern.allMatches(input)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: input.substring(lastEnd, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: base.merge(const TextStyle(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          )),
        ));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: base.merge(const TextStyle(fontWeight: FontWeight.w700)),
        ));
      } else if (match.group(5) != null) {
        spans.add(TextSpan(
          text: match.group(6),
          style: base.merge(const TextStyle(fontStyle: FontStyle.italic)),
        ));
      } else if (match.group(7) != null) {
        spans.add(TextSpan(
          text: match.group(8),
          style: base.merge(TextStyle(
            fontFamily: 'monospace',
            backgroundColor: (base.color ?? Colors.black).withOpacity(0.12),
          )),
        ));
      } else if (match.group(9) != null) {
        spans.add(TextSpan(
          text: match.group(10),
          style: base.merge(const TextStyle(
            decoration: TextDecoration.lineThrough,
          )),
        ));
      }
      lastEnd = match.end;
    }
    if (lastEnd < input.length) {
      spans.add(TextSpan(text: input.substring(lastEnd)));
    }
    return spans;
  }
}

enum _Kind { paragraph, heading, listItem }

class _Block {
  final _Kind kind;
  final String text;
  final int? headingLevel;
  final int? orderedIndex;
  _Block({
    required this.kind,
    required this.text,
    this.headingLevel,
    this.orderedIndex,
  });
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SignaturePoint {
  final Offset offset;
  final Paint paint;
  SignaturePoint(this.offset, this.paint);
}

class DigitalSignaturePad extends StatefulWidget {
  final ValueChanged<List<List<Offset>>> onSignatureChanged;
  final VoidCallback? onClear;
  final double height;
  final String signerLabel;

  const DigitalSignaturePad({
    super.key,
    required this.onSignatureChanged,
    this.onClear,
    this.height = 180,
    this.signerLabel = 'Hospital Waste Officer Signature',
  });

  @override
  State<DigitalSignaturePad> createState() => _DigitalSignaturePadState();
}

class _DigitalSignaturePadState extends State<DigitalSignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
    widget.onSignatureChanged([]);
    widget.onClear?.call();
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
      widget.onSignatureChanged(List.from(_strokes));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070B14).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _strokes.isEmpty ? Colors.white.withOpacity(0.18) : const Color(0xFF00F5A0).withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.draw_rounded, size: 16, color: Color(0xFF00F5A0)),
                    const SizedBox(width: 6),
                    Text(
                      widget.signerLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo_rounded, size: 18, color: Colors.white70),
                      tooltip: 'Undo last stroke',
                      onPressed: _strokes.isEmpty ? null : _undo,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      tooltip: 'Clear signature',
                      onPressed: _strokes.isEmpty && _currentStroke.isEmpty ? null : _clear,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // Canvas Area
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              child: Stack(
                children: [
                  // Signature baseline guide
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        const Text('✕', style: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.white12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sign above line',
                          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                  // Gesture area & painter
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _currentStroke = [details.localPosition];
                        _strokes.add(_currentStroke);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _currentStroke.add(details.localPosition);
                      });
                    },
                    onPanEnd: (details) {
                      widget.onSignatureChanged(List.from(_strokes));
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(strokes: _strokes),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5A0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke, paint);
      } else {
        final path = Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

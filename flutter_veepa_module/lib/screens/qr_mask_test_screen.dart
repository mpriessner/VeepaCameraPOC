import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Test screen to find the correct QR mask pattern for User ID frames
/// Shows all 8 mask patterns (0-7) for comparison with official app screenshots
class QrMaskTestScreen extends StatefulWidget {
  const QrMaskTestScreen({super.key});

  @override
  State<QrMaskTestScreen> createState() => _QrMaskTestScreenState();
}

class _QrMaskTestScreenState extends State<QrMaskTestScreen> {
  // ACTUAL DATA from official app (decoded from screenshots):
  // Frame 2 (User ID #1): {"BS":"c8eaf8e038f1","P":"6wKe727e","U":"303628825","S":"4G-Gateway-DE38F1"}
  // Frame 3 (User ID #2): {"BS":"c8eaf8e038f1","U":"303628825","A":"3"}

  // Data variants for Frame 2 (User ID #1) - 33 modules
  final List<String> _frame2Variants = [
    '{"BS":"c8eaf8e038f1","P":"6wKe727e","U":"303628825","S":"4G-Gateway-DE38F1"}', // Exact from official
    '{"BS":"c8eaf8e038f1","P":"6wKe727e","U":"","S":"4G-Gateway-DE38F1"}',          // Without user ID
  ];

  // Data variants for Frame 3 (User ID #2) - 29 modules
  final List<String> _frame3Variants = [
    '{"BS":"c8eaf8e038f1","U":"303628825","A":"3"}',  // Exact from official
    '{"U":"303628825","BS":"c8eaf8e038f1","A":"3"}',  // Different key order
  ];

  int _selectedVariantIndex = 0;
  int _errorCorrectionLevel = QrErrorCorrectLevel.L;

  // Which User ID frame to test (1 or 2)
  int _userIdFrame = 1;

  // Get current variants based on frame
  List<String> get _currentVariants => _userIdFrame == 1 ? _frame2Variants : _frame3Variants;

  // Expected module counts from official app
  int get _expectedModuleCount => _userIdFrame == 1 ? 33 : 29;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Mask Pattern Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.deepPurple.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User ID Frame selector
                Row(
                  children: [
                    const Text('Frame: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ChoiceChip(
                      label: const Text('#2 (Full+U)'),
                      selected: _userIdFrame == 1,
                      onSelected: (_) => setState(() {
                        _userIdFrame = 1;
                        _selectedVariantIndex = 0;
                      }),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('#3 (BS+U+A)'),
                      selected: _userIdFrame == 2,
                      onSelected: (_) => setState(() {
                        _userIdFrame = 2;
                        _selectedVariantIndex = 0;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Data variant selector
                const Text('Data (from decoded official QR):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Wrap(
                  spacing: 8,
                  children: List.generate(_currentVariants.length, (i) {
                    final label = i == 0 ? 'Exact match' : 'Variant ${i + 1}';
                    return ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 11)),
                      selected: _selectedVariantIndex == i,
                      onSelected: (_) => setState(() => _selectedVariantIndex = i),
                    );
                  }),
                ),
                Text(
                  _currentVariants[_selectedVariantIndex.clamp(0, _currentVariants.length - 1)],
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade700, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                // Error correction selector
                Row(
                  children: [
                    const Text('Error Correction: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...['L', 'M', 'Q', 'H'].asMap().entries.map((e) {
                      final levels = [QrErrorCorrectLevel.L, QrErrorCorrectLevel.M, QrErrorCorrectLevel.Q, QrErrorCorrectLevel.H];
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: _errorCorrectionLevel == levels[e.key],
                          onSelected: (_) => setState(() => _errorCorrectionLevel = levels[e.key]),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Official screenshot for comparison
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'Official App - User ID #$_userIdFrame',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      'Expected: $_expectedModuleCount modules (V${_userIdFrame == 1 ? 4 : 3})',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                    ),
                    const SizedBox(height: 8),
                    Image.asset(
                      _userIdFrame == 1
                        ? 'assets/qr_images/frame2_userid1.png'
                        : 'assets/qr_images/frame3_userid2.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Grid of all 8 mask patterns
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All 8 Mask Patterns (V$_typeNumber = $_expectedModuleCount modules)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Compare each pattern with official screenshot above',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, maskIndex) {
                        return _buildMaskPatternCard(maskIndex);
                      },
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

  // Get the type number (version) for the current frame
  // typeNumber 4 = 33 modules, typeNumber 3 = 29 modules
  int get _typeNumber => _userIdFrame == 1 ? 4 : 3;

  Widget _buildMaskPatternCard(int maskPattern) {
    final variantIndex = _selectedVariantIndex.clamp(0, _currentVariants.length - 1);
    final data = _currentVariants[variantIndex];

    try {
      // Force specific QR version to match official app size
      final qrCode = QrCode(_typeNumber, _errorCorrectionLevel);
      qrCode.addData(data);

      final qrImage = QrImage.withMaskPattern(qrCode, maskPattern);
      final moduleCount = qrImage.moduleCount;
      final sizeMatches = moduleCount == _expectedModuleCount;

      return Card(
        elevation: sizeMatches ? 4 : 1,
        color: sizeMatches ? Colors.white : Colors.grey.shade100,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              color: sizeMatches ? Colors.deepPurple : Colors.grey,
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    'Mask $maskPattern',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$moduleCount mod${sizeMatches ? " ✓" : ""}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sizeMatches ? Colors.greenAccent : Colors.white70,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: CustomPaint(
                  painter: QrPainter(qrImage),
                  size: const Size(80, 80),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Card(
        child: Center(child: Text('Error: $e', style: const TextStyle(fontSize: 10))),
      );
    }
  }
}

/// Custom painter to render QrImage
class QrPainter extends CustomPainter {
  final QrImage qrImage;

  QrPainter(this.qrImage);

  @override
  void paint(Canvas canvas, Size size) {
    final moduleCount = qrImage.moduleCount;
    final moduleSize = size.width / moduleCount;

    final darkPaint = Paint()..color = Colors.black;
    final lightPaint = Paint()..color = Colors.white;

    // Fill background white
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);

    // Draw modules
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(x * moduleSize, y * moduleSize, moduleSize, moduleSize),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

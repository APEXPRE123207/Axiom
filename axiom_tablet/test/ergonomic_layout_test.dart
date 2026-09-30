import 'package:flutter_test/flutter_test.dart';
import 'package:axiom_tablet/keyboard/standard_layout.dart';
import 'package:axiom_tablet/keyboard/ergonomic_layout.dart';

void main() {
  test('ErgonomicLayout preserves all logical keys and scancodes', () {
    final standardKeys = StandardLayout.getRows()
        .expand((row) => row)
        .map((k) => k.logicalCode)
        .toSet();

    final leftKeys = ErgonomicLayout.getLeftRows().expand((row) => row);
    final rightKeys = ErgonomicLayout.getRightRows().expand((row) => row);
    final ergoKeys = [...leftKeys, ...rightKeys].map((k) => k.logicalCode).toSet();

    // Verify all primary keys are present in both
    for (final code in ["A", "Z", "SPACE", "ENTER", "BACKSPACE", "TAB", "SHIFT", "CTRL", "ESCAPE"]) {
      expect(standardKeys.contains(code), isTrue, reason: "Standard missing $code");
      expect(ergoKeys.contains(code), isTrue, reason: "Ergonomic missing $code");
    }

    // Verify all unique logical keys in Standard exist in Ergonomic
    expect(ergoKeys, standardKeys);

    // Ergonomic layout has 78 physical keys (due to dual left and right thumb spacebars)
    expect(leftKeys.length + rightKeys.length, 78);
  });
}

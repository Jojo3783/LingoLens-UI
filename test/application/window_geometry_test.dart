import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/window_geometry.dart';

void main() {
  test('panel near the centre stays at the requested gap', () {
    const workArea = DesktopRect(left: 0, top: 0, width: 1920, height: 1080);

    final panel = positionPanelNearCursor(
      workArea: workArea,
      cursorX: 600,
      cursorY: 300,
      panelWidth: 760,
      panelHeight: 720,
    );

    expect(panel.left, 616);
    expect(panel.top, 316);
  });

  test('panel clamps to a negative-coordinate monitor edge', () {
    const workArea = DesktopRect(
      left: -1920,
      top: -100,
      width: 1920,
      height: 1080,
    );

    final panel = positionPanelNearCursor(
      workArea: workArea,
      cursorX: -1915,
      cursorY: -95,
      panelWidth: 760,
      panelHeight: 720,
    );

    expect(panel.left, -1899);
    expect(panel.top, -79);
    expect(panel.right, lessThanOrEqualTo(workArea.right));
    expect(panel.bottom, lessThanOrEqualTo(workArea.bottom));
  });

  test('oversized panel is bounded by the usable work area', () {
    const workArea = DesktopRect(left: 100, top: 200, width: 500, height: 400);

    final panel = positionPanelNearCursor(
      workArea: workArea,
      cursorX: 350,
      cursorY: 400,
      panelWidth: 1200,
      panelHeight: 900,
    );

    expect(panel.width, workArea.width);
    expect(panel.height, workArea.height);
    expect(panel.left, workArea.left);
    expect(panel.top, workArea.top);
  });
}

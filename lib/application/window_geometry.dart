final class DesktopRect {
  const DesktopRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
}

DesktopRect positionPanelNearCursor({
  required DesktopRect workArea,
  required double cursorX,
  required double cursorY,
  required double panelWidth,
  required double panelHeight,
  double gap = 16,
}) {
  final width = panelWidth.clamp(0, workArea.width).toDouble();
  final height = panelHeight.clamp(0, workArea.height).toDouble();
  final left = (cursorX + gap).clamp(workArea.left, workArea.right - width);
  final top = (cursorY + gap).clamp(workArea.top, workArea.bottom - height);
  return DesktopRect(
    left: left.toDouble(),
    top: top.toDouble(),
    width: width,
    height: height,
  );
}

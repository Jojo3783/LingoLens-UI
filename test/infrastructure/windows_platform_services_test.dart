import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingolens/application/windows_platform_contracts.dart';
import 'package:lingolens/infrastructure/windows/windows_platform_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SelectedTextCaptureOutcome> captureClipboardStatus({
    required String channelName,
    required String status,
  }) async {
    final channel = MethodChannel('test/windows_platform/$channelName');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'captureClipboardFallback') {
            throw StateError('unexpected capture method: ${call.method}');
          }
          return <String, Object?>{'status': status};
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    return WindowsSelectedTextService(channel: channel).capture();
  }

  test('successful capture invokes only bounded clipboard fallback', () async {
    const channel = MethodChannel('test/windows_platform/primary');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method != 'captureClipboardFallback') {
            throw StateError('unexpected capture method: ${call.method}');
          }
          return <String, Object?>{
            'status': 'success',
            'text': 'clipboard selected text',
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final service = WindowsSelectedTextService(channel: channel);
    final result = await service.capture(
      timeout: const Duration(milliseconds: 900),
    );

    expect(result, isA<SelectedTextCaptureSuccess>());
    expect(
      (result as SelectedTextCaptureSuccess).text,
      'clipboard selected text',
    );
    expect(calls.map((call) => call.method), ['captureClipboardFallback']);
    expect(calls.single.arguments, <String, Object?>{'timeoutMs': 900});
  });

  test('production capture never invokes captureSelectedText', () async {
    const channel = MethodChannel('test/windows_platform/no-uia');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return <String, Object?>{
            'status': 'success',
            'text': 'clipboard selected text',
          };
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final service = WindowsSelectedTextService(channel: channel);
    final result = await service.capture();

    expect(result, isA<SelectedTextCaptureSuccess>());
    expect(calls, ['captureClipboardFallback']);
    expect(calls, isNot(contains('captureSelectedText')));
  });

  test('Clipboard invocation receives the full caller timeout', () async {
    const channel = MethodChannel('test/windows_platform/timeout');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return <String, Object?>{'status': 'captureTimeout'};
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final service = WindowsSelectedTextService(channel: channel);
    final result = await service.capture(
      timeout: const Duration(milliseconds: 700),
    );

    expect(result, isA<SelectedTextCaptureFailure>());
    expect(
      (result as SelectedTextCaptureFailure).code,
      WindowsCaptureFailureCode.captureTimeout,
    );
    expect(calls.map((call) => call.method), ['captureClipboardFallback']);
    expect(calls.single.arguments, <String, Object?>{'timeoutMs': 700});
  });

  test('clipboardRestoreFailed remains typed', () async {
    final result = await captureClipboardStatus(
      channelName: 'restore-failure',
      status: 'clipboardRestoreFailed',
    );

    expect(result, isA<SelectedTextCaptureFailure>());
    expect(
      (result as SelectedTextCaptureFailure).code,
      WindowsCaptureFailureCode.clipboardRestoreFailed,
    );
  });

  test('clipboardConcurrentModification remains typed', () async {
    final result = await captureClipboardStatus(
      channelName: 'concurrent-modification',
      status: 'clipboardConcurrentModification',
    );

    expect(result, isA<SelectedTextCaptureFailure>());
    expect(
      (result as SelectedTextCaptureFailure).code,
      WindowsCaptureFailureCode.clipboardConcurrentModification,
    );
  });

  test('captureTimeout remains typed', () async {
    final result = await captureClipboardStatus(
      channelName: 'capture-timeout',
      status: 'captureTimeout',
    );

    expect(result, isA<SelectedTextCaptureFailure>());
    expect(
      (result as SelectedTextCaptureFailure).code,
      WindowsCaptureFailureCode.captureTimeout,
    );
  });

  test('clipboardSnapshotUnsupported remains typed', () async {
    final result = await captureClipboardStatus(
      channelName: 'snapshot-unsupported',
      status: 'clipboardSnapshotUnsupported',
    );

    expect(result, isA<SelectedTextCaptureFailure>());
    expect(
      (result as SelectedTextCaptureFailure).code,
      WindowsCaptureFailureCode.clipboardSnapshotUnsupported,
    );
  });

  test('cancel invokes the existing native cancelCapture method', () async {
    const channel = MethodChannel('test/windows_platform/cancel');
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final service = WindowsSelectedTextService(channel: channel);
    await service.cancel();

    expect(calls, ['cancelCapture']);
  });

  test(
    'a late clipboard completion becomes typed cancellation after a newer capture',
    () async {
      const channel = MethodChannel('test/windows_platform/latest');
      final first = Completer<Object?>();
      var calls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method != 'captureClipboardFallback') {
              throw StateError('unexpected capture method: ${call.method}');
            }
            calls++;
            if (calls == 1) {
              return first.future;
            }
            return <String, Object?>{
              'status': 'success',
              'text': 'newer selected text',
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final service = WindowsSelectedTextService(channel: channel);
      final older = service.capture();
      await Future<void>.delayed(Duration.zero);
      final newer = service.capture();
      expect(await newer, isA<SelectedTextCaptureSuccess>());
      first.complete(<String, Object?>{
        'status': 'success',
        'text': 'stale selected text',
      });

      expect(
        await older,
        const SelectedTextCaptureFailure(WindowsCaptureFailureCode.cancelled),
      );
    },
  );
}

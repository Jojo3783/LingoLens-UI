import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/analysis_controller.dart';
import '../application/analysis_state.dart';
import '../application/windows_capture_controller.dart';
import '../application/windows_platform_contracts.dart';
import '../domain/provider_contracts.dart';
import 'analysis_input_section.dart';
import 'analysis_mode_selection_panel.dart';
import 'analysis_state_panel.dart';
import 'lingolens_surface.dart';

final class AnalysisPage extends StatefulWidget {
  const AnalysisPage({
    required this.controller,
    required this.onFailureScenarioChanged,
    this.providerDisclosure,
    this.windowsCapture,
    super.key,
  });

  final AnalysisController controller;
  final ValueChanged<bool> onFailureScenarioChanged;
  final ProviderDisclosure? providerDisclosure;
  final WindowsCaptureController? windowsCapture;

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

final class _AnalysisPageState extends State<AnalysisPage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  StreamSubscription<WindowsCaptureState>? _windowsCaptureSubscription;
  bool _failureScenario = false;

  @override
  void initState() {
    super.initState();
    _windowsCaptureSubscription = widget.windowsCapture?.states.listen(
      _handleWindowsCaptureState,
    );
    final initialState = widget.windowsCapture?.state;
    if (initialState != null) {
      _handleWindowsCaptureState(initialState);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    unawaited(_windowsCaptureSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          unawaited(widget.windowsCapture?.dismissPanel());
        },
      },
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: StreamBuilder<AnalysisSessionState>(
                  stream: widget.controller.states,
                  initialData: widget.controller.state,
                  builder: (context, snapshot) {
                    final state = snapshot.data ?? const AnalysisIdle();
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const LingoLensSectionHeader(
                            title: '分析',
                            description: '輸入文字，確認模式，再取得可採取的語言結果。',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '手動輸入 → 模式選擇 → 分析結果',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (widget.providerDisclosure != null)
                            LingoLensStatusCard(
                              key: const ValueKey('provider-disclosure'),
                              title: widget.providerDisclosure!.providerName,
                              message: widget.providerDisclosure!.message,
                              icon: Icons.verified_user_outlined,
                            ),
                          if (widget.providerDisclosure != null)
                            const SizedBox(height: 16),
                          if (widget.windowsCapture != null)
                            StreamBuilder<WindowsCaptureState>(
                              stream: widget.windowsCapture!.states,
                              initialData: widget.windowsCapture!.state,
                              builder: (context, snapshot) {
                                final failure = snapshot.data?.failure;
                                if (failure == null) {
                                  return const SizedBox.shrink();
                                }
                                return Semantics(
                                  liveRegion: true,
                                  container: true,
                                  label: failure.userMessage,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: LingoLensStatusCard(
                                      title: 'Windows 擷取狀態',
                                      message: failure.userMessage,
                                      icon: Icons.desktop_windows_outlined,
                                      tone: Theme.of(context).colorScheme,
                                    ),
                                  ),
                                );
                              },
                            ),
                          AnalysisInputSection(
                            inputController: _inputController,
                            inputFocusNode: _inputFocusNode,
                            enabled: state.phase != AnalysisPhase.loading,
                            onChanged: widget.controller.updateDraft,
                            onSubmitted: _submit,
                          ),
                          const SizedBox(height: 16),
                          AnalysisModeSelectionPanel(
                            controller: widget.controller,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              Semantics(
                                button: true,
                                label: '送出分析',
                                child: FilledButton.icon(
                                  key: const ValueKey('submit-analysis'),
                                  onPressed:
                                      state.phase == AnalysisPhase.loading
                                          ? null
                                          : _submit,
                                  icon: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('送出分析'),
                                ),
                              ),
                              if (state.phase == AnalysisPhase.loading)
                                Semantics(
                                  button: true,
                                  label: '取消分析',
                                  child: OutlinedButton.icon(
                                    key: const ValueKey(
                                      'cancel-analysis',
                                    ),
                                    onPressed: widget.controller.cancel,
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('取消分析'),
                                  ),
                                ),
                              if (state.phase == AnalysisPhase.failure ||
                                  state.phase == AnalysisPhase.cancelled)
                                Semantics(
                                  button: true,
                                  label: '重試',
                                  child: OutlinedButton.icon(
                                    key: const ValueKey('retry-analysis'),
                                    onPressed: widget.controller.retry,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('重試'),
                                  ),
                                ),
                            ],
                          ),
                          if (kDebugMode) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: ExpansionTile(
                                key: const ValueKey('developer-section'),
                                shape: const Border(),
                                leading: const Icon(
                                  Icons.developer_mode_rounded,
                                  size: 20,
                                ),
                                title: const Text('Developer'),
                                subtitle: const Text(
                                  '僅限 deterministic development data',
                                ),
                                children: [
                                  SwitchListTile(
                                    key: const ValueKey('failure-scenario'),
                                    value: _failureScenario,
                                    title: const Text(
                                      '模擬 typed Provider failure',
                                    ),
                                    subtitle:
                                        const Text('不會傳送 network request'),
                                    onChanged:
                                        state.phase == AnalysisPhase.loading
                                            ? null
                                            : (value) {
                                                setState(
                                                  () => _failureScenario = value,
                                                );
                                                widget.onFailureScenarioChanged(
                                                  value,
                                                );
                                              },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          AnalysisStatePanel(
                            controller: widget.controller,
                            state: state,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() => widget.controller.submit(_inputController.text);

  void _handleWindowsCaptureState(WindowsCaptureState state) {
    final capturedText = state.capturedText;
    if (capturedText == null || _inputController.text == capturedText) {
      return;
    }
    _inputController.value = TextEditingValue(
      text: capturedText,
      selection: TextSelection.collapsed(offset: capturedText.length),
    );
    widget.controller.updateDraft(capturedText);
    if (state.phase == WindowsCapturePhase.captured) {
      _inputFocusNode.requestFocus();
    }
  }
}

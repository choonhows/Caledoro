import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/subtask_generation_provider.dart';
import '../theme.dart';

class AiSubtaskGeneratorWidget extends ConsumerStatefulWidget {
  final TaskModel task;

  const AiSubtaskGeneratorWidget({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<AiSubtaskGeneratorWidget> createState() =>
      _AiSubtaskGeneratorWidgetState();
}

class _AiSubtaskGeneratorWidgetState
    extends ConsumerState<AiSubtaskGeneratorWidget> {
  bool _showRegenerateConfirm = false;

  bool get _hasAcceptedSubtasks =>
      widget.task.subtasks.any((s) => !s.suggested);

  bool get _hasSuggestedSubtasks =>
      widget.task.subtasks.any((s) => s.suggested);

  Future<void> _generate() async {
    await ref.read(subtaskGenerationProvider.notifier).generate(
          taskTitle: widget.task.title,
          taskDescription: widget.task.description,
        );
  }

  void _onGeneratePressed() {
    if (_hasAcceptedSubtasks || _hasSuggestedSubtasks) {
      setState(() => _showRegenerateConfirm = true);
    } else {
      _generate();
    }
  }

  Future<void> _acceptSuggested(SubtaskModel subtask) async {
    await ref
        .read(taskListProvider.notifier)
        .acceptSubtask(widget.task.id, subtask.id);
  }

  Future<void> _rejectSuggested(SubtaskModel subtask) async {
    await ref
        .read(taskListProvider.notifier)
        .rejectSubtask(widget.task.id, subtask.id);
  }

  Future<void> _acceptAll() async {
    await ref
        .read(taskListProvider.notifier)
        .acceptAllSubtasks(widget.task.id);
    ref.read(subtaskGenerationProvider.notifier).reset();
  }

  Future<void> _rejectAll() async {
    await ref
        .read(taskListProvider.notifier)
        .rejectAllSubtasks(widget.task.id);
    ref.read(subtaskGenerationProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final genState = ref.watch(subtaskGenerationProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final suggestedSubtasks = genState.status == SubtaskGenerationStatus.success
        ? (genState.subtasks.where((s) => s.suggested).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        : (widget.task.subtasks.where((s) => s.suggested).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (genState.status == SubtaskGenerationStatus.idle) ...[
          if (_showRegenerateConfirm) ...[
            _buildRegenerateConfirm(cs, tt),
          ] else ...[
            _buildGenerateButton(cs, tt),
          ],
        ],
        if (genState.status == SubtaskGenerationStatus.generating) ...[
          _buildLoadingState(cs, tt),
        ],
        if (genState.status == SubtaskGenerationStatus.success) ...[
          if (suggestedSubtasks.isNotEmpty) ...[
            _buildSuggestedHeader(cs, tt, suggestedSubtasks.length),
            const SizedBox(height: 8),
            ...suggestedSubtasks.map(
              (subtask) => _buildSuggestedRow(cs, tt, subtask),
            ),
            const SizedBox(height: 12),
            _buildAcceptRejectAllRow(cs, tt),
          ] else ...[
            _buildEmptyAfterAccept(cs, tt),
          ],
        ],
        if (genState.status == SubtaskGenerationStatus.error ||
            genState.status == SubtaskGenerationStatus.offline) ...[
          _buildErrorState(cs, tt, genState),
        ],
      ],
    );
  }

  Widget _buildGenerateButton(ColorScheme cs, TextTheme tt) {
    final hasSubtasks = _hasAcceptedSubtasks || _hasSuggestedSubtasks;
    return GestureDetector(
      onTap: _onGeneratePressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            Text(
              hasSubtasks ? 'Regenerate with AI' : 'Generate subtasks with AI',
              style: tt.bodyMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegenerateConfirm(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will replace current subtasks with AI suggestions.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      setState(() => _showRegenerateConfirm = false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _showRegenerateConfirm = false);
                    ref.read(subtaskGenerationProvider.notifier).reset();
                    _generate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: CozyColors.onPrimary,
                  ),
                  child: const Text('Regenerate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs, TextTheme tt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Generating subtasks...',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedHeader(ColorScheme cs, TextTheme tt, int count) {
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          'AI Suggestions ($count)',
          style: tt.titleSmall?.copyWith(color: cs.onSurface),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => ref.read(subtaskGenerationProvider.notifier).reset(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  Widget _buildSuggestedRow(
      ColorScheme cs, TextTheme tt, SubtaskModel subtask) {
    return AnimatedOpacity(
      key: ValueKey('suggested-${subtask.id}'),
      duration: const Duration(milliseconds: 200),
      opacity: 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                subtask.label,
                style: tt.bodySmall?.copyWith(color: cs.onSurface),
              ),
            ),
            const SizedBox(width: 8),
            _buildActionChip(
              cs: cs,
              tt: tt,
              label: 'Accept',
              icon: Icons.check_rounded,
              onTap: () => _acceptSuggested(subtask),
              isPrimary: true,
            ),
            const SizedBox(width: 6),
            _buildActionChip(
              cs: cs,
              tt: tt,
              label: 'Reject',
              icon: Icons.close_rounded,
              onTap: () => _rejectSuggested(subtask),
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required ColorScheme cs,
    required TextTheme tt,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: isPrimary ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptRejectAllRow(ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: _acceptAll,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: const Text('Accept all'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton.icon(
            onPressed: _rejectAll,
            icon: Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Reject all'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAfterAccept(ColorScheme cs, TextTheme tt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'All suggestions reviewed. Add subtasks manually or regenerate.',
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorState(
      ColorScheme cs, TextTheme tt, SubtaskGenerationState genState) {
    final isOffline =
        genState.status == SubtaskGenerationStatus.offline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOffline
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: cs.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  genState.errorMessage ??
                      (isOffline
                          ? 'No internet connection'
                          : 'Generation failed'),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    ref.read(subtaskGenerationProvider.notifier).reset();
                  },
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(subtaskGenerationProvider.notifier).reset();
                    _generate();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: CozyColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Or add subtasks manually below',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

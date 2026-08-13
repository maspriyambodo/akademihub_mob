import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ujian_question_entity.dart';
import '../../domain/entities/ujian_session_entity.dart';
import '../../domain/repositories/ujian_repository.dart';

class UjianSessionPage extends StatefulWidget {
  final UjianSessionEntity session;
  final UjianRepository? repository;

  const UjianSessionPage({super.key, required this.session, this.repository});

  @override
  State<UjianSessionPage> createState() => _UjianSessionPageState();
}

class _UjianSessionPageState extends State<UjianSessionPage> {
  late UjianSessionEntity _session = widget.session;
  late final UjianRepository _repository = widget.repository ?? sl();
  final _saving = <int>{};
  List<UjianQuestionEntity> _questions = const [];
  Timer? _timer;
  int? _remainingSeconds;
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _setAuthoritativeTimer(_session);
    if (_session.status == UjianSessionStatus.mengerjakan) _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setAuthoritativeTimer(UjianSessionEntity session) {
    _timer?.cancel();
    final backendSeconds = session.sisaWaktu;
    if (backendSeconds == null) {
      _remainingSeconds = null;
      return;
    }
    final started = DateTime.tryParse(session.waktuMulai ?? '')?.toLocal();
    final elapsed = started == null
        ? 0
        : DateTime.now().difference(started).inSeconds.clamp(0, backendSeconds);
    _remainingSeconds = (backendSeconds - elapsed).clamp(0, backendSeconds);
    if (session.status != UjianSessionStatus.mengerjakan) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds == null || _remainingSeconds == 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remainingSeconds = _remainingSeconds! - 1);
    });
  }

  Future<void> _refreshSession() async {
    final result = await _repository.getSesi(_session.id);
    if (!mounted || result.isFailure) return;
    setState(() {
      _session = result.requireData;
      if (_session.status != UjianSessionStatus.mengerjakan) {
        _questions = const [];
      }
      _setAuthoritativeTimer(_session);
    });
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await _repository.getSoal(_session.id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _questions = result.requireData.toList();
      } else {
        _loadError = result.requireFailure.message;
      }
    });
  }

  Future<void> _mulai() async {
    setState(() => _loading = true);
    final result = await _repository.mulaiSesi(_session.id);
    if (!mounted) return;
    if (result.isFailure) {
      setState(() => _loading = false);
      return _error(result.requireFailure.message);
    }
    setState(() {
      _session = result.requireData;
      _setAuthoritativeTimer(_session);
    });
    await _loadQuestions();
  }

  Future<void> _save(
    UjianQuestionEntity question, {
    int? optionId,
    String? text,
    bool? doubtful,
  }) async {
    if (_session.status != UjianSessionStatus.mengerjakan ||
        _saving.contains(question.id)) {
      return;
    }
    final answer = question.answer;
    final nextOption = optionId ?? answer?.optionId;
    final nextText = text ?? answer?.text;
    if (question.isMultipleChoice && nextOption == null) return;
    if (question.isEssay && (nextText?.trim().isEmpty ?? true)) return;
    setState(() => _saving.add(question.id));
    final result = await _repository.saveJawaban(
      sesiId: _session.id,
      soalId: question.id,
      opsiId: question.isMultipleChoice ? nextOption : null,
      teks: question.isEssay ? nextText?.trim() : null,
      raguRagu: doubtful ?? answer?.doubtful ?? false,
    );
    if (!mounted) return;
    setState(() {
      _saving.remove(question.id);
      if (result.isSuccess) {
        final index = _questions.indexWhere((item) => item.id == question.id);
        _questions[index] = question.copyWith(answer: result.requireData);
      }
    });
    if (result.isFailure) _error(result.requireFailure.message);
  }

  Future<void> _selesaikan() async {
    if (_saving.isNotEmpty) {
      return _error('Tunggu semua jawaban selesai disimpan');
    }
    if (_questions.isEmpty) return _error('Soal ujian belum tersedia');
    final unanswered = _questions
        .where((question) => !question.isAnswered)
        .length;
    if (unanswered > 0) {
      return _error('$unanswered soal belum dijawab');
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan ujian?'),
        content: Text(
          '${_questions.length} jawaban tersimpan. Jawaban tidak dapat diubah setelah ujian selesai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    final result = await _repository.selesaikanSesi(_session.id);
    if (!mounted) return;
    if (result.isFailure) {
      setState(() => _loading = false);
      return _error(result.requireFailure.message);
    }
    setState(() {
      _session = result.requireData;
      _questions = const [];
      _loading = false;
      _setAuthoritativeTimer(_session);
    });
    await _refreshSession();
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String get _timerLabel {
    final seconds = _remainingSeconds;
    if (seconds == null) return '--:--:--';
    return Duration(
      seconds: seconds,
    ).toString().split('.').first.padLeft(8, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ujian Online'),
        actions: [
          if (_session.status == UjianSessionStatus.mengerjakan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _timerLabel,
                  key: const Key('exam-timer'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _refreshSession();
              if (_session.status == UjianSessionStatus.mengerjakan) {
                await _loadQuestions();
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _session.namaUjian,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text('Status: ${_session.statusLabel}'),
                if (_session.status == UjianSessionStatus.selesai) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Nilai ${_session.nilaiAkhir.toStringAsFixed(2)}',
                    key: const Key('exam-result'),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Benar ${_session.totalBenar} · Salah ${_session.totalSalah}',
                  ),
                ],
                const SizedBox(height: 16),
                if (_session.status == UjianSessionStatus.belumMulai)
                  FilledButton.icon(
                    onPressed: _loading ? null : _mulai,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Mulai Ujian'),
                  ),
                if (_loadError != null)
                  Card(
                    child: ListTile(
                      title: Text(_loadError!),
                      trailing: IconButton(
                        onPressed: _loadQuestions,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  ),
                if (_session.status == UjianSessionStatus.mengerjakan)
                  ..._questions.indexed.map(
                    (entry) => _QuestionCard(
                      key: ValueKey(entry.$2.id),
                      number: entry.$1 + 1,
                      question: entry.$2,
                      enabled:
                          _session.status == UjianSessionStatus.mengerjakan &&
                          !_saving.contains(entry.$2.id),
                      saving: _saving.contains(entry.$2.id),
                      onOption: (id) => _save(entry.$2, optionId: id),
                      onEssay: (text) => _save(entry.$2, text: text),
                      onDoubtful: (value) => _save(entry.$2, doubtful: value),
                    ),
                  ),
                if (_session.status == UjianSessionStatus.mengerjakan) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('finalize-exam'),
                    onPressed: _loading ? null : _selesaikan,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Selesaikan Ujian'),
                  ),
                ],
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final int number;
  final UjianQuestionEntity question;
  final bool enabled;
  final bool saving;
  final ValueChanged<int> onOption;
  final ValueChanged<String> onEssay;
  final ValueChanged<bool> onDoubtful;

  const _QuestionCard({
    super.key,
    required this.number,
    required this.question,
    required this.enabled,
    required this.saving,
    required this.onOption,
    required this.onEssay,
    required this.onDoubtful,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.question.answer?.text,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.number}. ${question.question}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (question.isMultipleChoice)
              RadioGroup<int>(
                groupValue: question.answer?.optionId,
                onChanged: (value) {
                  if (widget.enabled && value != null) widget.onOption(value);
                },
                child: Column(
                  children: question.options
                      .map(
                        (option) => RadioListTile<int>(
                          value: option.id,
                          enabled: widget.enabled,
                          title: Text(option.text),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              )
            else if (question.isEssay) ...[
              TextField(
                key: Key('essay-${question.id}'),
                controller: _controller,
                enabled: widget.enabled,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Tulis jawaban',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: widget.enabled
                    ? () => widget.onEssay(_controller.text)
                    : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan Jawaban'),
              ),
            ] else
              const Text('Tipe soal tidak didukung'),
            CheckboxListTile(
              value: question.answer?.doubtful ?? false,
              onChanged: widget.enabled && question.isAnswered
                  ? (value) => widget.onDoubtful(value ?? false)
                  : null,
              title: const Text('Ragu-ragu'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (widget.saving) const LinearProgressIndicator(),
            if (question.isAnswered && !widget.saving)
              const Text(
                'Tersimpan',
                style: TextStyle(color: AppColors.success),
              ),
          ],
        ),
      ),
    );
  }
}

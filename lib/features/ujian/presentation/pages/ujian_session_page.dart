import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ujian_question_entity.dart';
import '../../domain/entities/ujian_session_entity.dart';
import '../../domain/repositories/ujian_repository.dart';

class UjianSessionPage extends StatefulWidget {
  final UjianSessionEntity session;
  final UjianRepository? repository;
  final DateTime Function()? nowProvider;

  const UjianSessionPage({
    super.key,
    required this.session,
    this.repository,
    this.nowProvider,
  });

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

  DateTime _getNow() {
    return (widget.nowProvider ?? () => ApiClient.currentServerTime)().toUtc();
  }

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final formatted = raw.contains('T') ? raw : raw.replaceAll(' ', 'T');
    return DateTime.tryParse(formatted)?.toUtc();
  }

  @override
  void initState() {
    super.initState();
    _setAuthoritativeTimer(_session);
    if (_session.status == UjianSessionStatus.mengerjakan &&
        !_session.isTimedOut &&
        (_remainingSeconds == null || _remainingSeconds! > 0)) {
      _loadQuestions();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setAuthoritativeTimer(UjianSessionEntity session) {
    _timer?.cancel();
    if (session.isTimedOut) {
      _remainingSeconds = 0;
      return;
    }

    final deadline = _parseDateTime(session.deadlineAt);
    if (deadline != null) {
      final remaining = deadline.difference(_getNow()).inSeconds;
      _remainingSeconds = remaining < 0 ? 0 : remaining;
    } else if (session.sisaWaktu != null) {
      final backendSeconds = session.sisaWaktu!;
      final started = _parseDateTime(session.waktuMulai);
      final elapsed = started == null
          ? 0
          : _getNow().difference(started).inSeconds.clamp(0, backendSeconds);
      _remainingSeconds = (backendSeconds - elapsed).clamp(0, backendSeconds);
    } else {
      _remainingSeconds = null;
    }

    if (session.status != UjianSessionStatus.mengerjakan ||
        (_remainingSeconds != null && _remainingSeconds! <= 0)) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      final d = _parseDateTime(_session.deadlineAt);
      int newRemaining;
      if (d != null) {
        newRemaining = d.difference(_getNow()).inSeconds;
      } else if (_remainingSeconds != null) {
        newRemaining = _remainingSeconds! - 1;
      } else {
        return;
      }

      if (newRemaining <= 0) {
        _timer?.cancel();
        setState(() => _remainingSeconds = 0);
        _refreshSession();
      } else {
        setState(() => _remainingSeconds = newRemaining);
      }
    });
  }

  Future<void> _refreshSession() async {
    final result = await _repository.getSesi(_session.id);
    if (!mounted || result.isFailure) return;
    setState(() {
      _session = result.requireData;
      if (_session.status != UjianSessionStatus.mengerjakan ||
          _session.isTimedOut ||
          (_remainingSeconds != null && _remainingSeconds! <= 0)) {
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
    if (_session.isTimedOut || (_remainingSeconds != null && _remainingSeconds! <= 0)) {
      _error('Waktu ujian habis');
      await _refreshSession();
      return;
    }
    setState(() => _saving.add(question.id));
    final nextDoubtful = doubtful ?? question.answer?.doubtful ?? false;
    final result = await _repository.saveJawaban(
      sesiId: _session.id,
      soalId: question.id,
      opsiId: optionId ?? question.answer?.optionId,
      teks: text ?? question.answer?.text,
      raguRagu: nextDoubtful,
    );
    if (!mounted) return;
    setState(() => _saving.remove(question.id));
    if (result.isFailure) {
      _error(result.requireFailure.message);
      await _refreshSession();
      return;
    }
    final answer = result.requireData;
    setState(() {
      _questions = _questions
          .map((q) => q.id == question.id ? q.copyWith(answer: answer) : q)
          .toList();
    });
  }

  Future<void> _selesaikan() async {
    final emptyCount = _questions.where((q) => !q.isAnswered).length;
    if (emptyCount > 0) {
      return _error('$emptyCount soal belum dijawab');
    }

    setState(() => _loading = true);
    final result = await _repository.selesaikanSesi(_session.id);
    if (!mounted) return;
    if (result.isFailure) {
      setState(() => _loading = false);
      _error(result.requireFailure.message);
      await _refreshSession();
      return;
    }
    setState(() {
      _loading = false;
      _session = result.requireData;
      _questions = const [];
      _setAuthoritativeTimer(_session);
    });
  }

  void _error(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Widget _buildTimerBadge() {
    final remaining = _remainingSeconds;
    final minutes = remaining == null ? 0 : remaining ~/ 60;
    final seconds = remaining == null ? 0 : remaining % 60;
    final label = remaining == null
        ? '--:--'
        : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (remaining ?? 0) <= 60
            ? AppColors.error.withAlpha(30)
            : AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Sisa waktu: $label',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: (remaining ?? 0) <= 60 ? AppColors.error : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_session.isTimedOut) {
      return Card(
        key: const Key('timeout-banner'),
        color: AppColors.error.withAlpha(25),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.timer_off_outlined, color: AppColors.error, size: 40),
              SizedBox(height: 8),
              Text(
                'Waktu Ujian Habis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.error,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Waktu ujian habis. Sesi Anda telah diautofinalisasi oleh server.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_session.status == UjianSessionStatus.selesai) {
      return Card(
        key: const Key('exam-result'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Nilai ${(_session.nilaiAkhir ?? 0).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Benar: ${_session.totalBenar} • Salah: ${_session.totalSalah}',
              ),
            ],
          ),
        ),
      );
    }

    if (_session.status == UjianSessionStatus.menungguKoreksi) {
      return Card(
        key: const Key('awaiting-grading'),
        color: Colors.amber.withAlpha(35),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.hourglass_empty_outlined,
                color: Colors.amber,
                size: 40,
              ),
              const SizedBox(height: 8),
              const Text(
                'Menunggu Koreksi Guru',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              const Text(
                'Jawaban essay Anda telah tersimpan dan sedang diperiksa.',
                textAlign: TextAlign.center,
              ),
              if (_session.nilaiProvisional != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Nilai sementara ${_session.nilaiProvisional!.toStringAsFixed(2)}',
                  key: const Key('provisional-result'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_session.status == UjianSessionStatus.belumMulai) {
      return Column(
        children: [
          const Text('Ujian belum dimulai.'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _mulai,
            child: const Text('Mulai Ujian'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final inputsEnabled =
        _session.status == UjianSessionStatus.mengerjakan &&
        !_session.isTimedOut &&
        (_remainingSeconds == null || _remainingSeconds! > 0) &&
        !_loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_session.namaUjian),
        actions: [
          if (_session.status == UjianSessionStatus.mengerjakan)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: _buildTimerBadge()),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSession,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 12),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_loadError != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      _loadError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadQuestions,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            if (_session.status == UjianSessionStatus.mengerjakan) ...[
              for (var i = 0; i < _questions.length; i++)
                _QuestionCard(
                  number: i + 1,
                  question: _questions[i],
                  enabled: inputsEnabled,
                  saving: _saving.contains(_questions[i].id),
                  onOption: (opId) => _save(_questions[i], optionId: opId),
                  onEssay: (text) => _save(_questions[i], text: text),
                  onDoubtful: (r) => _save(_questions[i], doubtful: r),
                ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                key: const Key('finalize-exam'),
                onPressed: inputsEnabled ? _selesaikan : null,
                icon: const Icon(Icons.check_outlined),
                label: const Text('Selesaikan Ujian'),
              ),
            ],
          ],
        ),
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
              Column(
                children: question.options
                    .map(
                      (option) => RadioListTile<int>(
                        value: option.id,
                        groupValue: question.answer?.optionId,
                        onChanged: (value) {
                          if (widget.enabled && value != null) {
                            widget.onOption(value);
                          }
                        },
                        title: Text(option.text),
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
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

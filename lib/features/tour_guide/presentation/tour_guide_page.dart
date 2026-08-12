import 'package:flutter/material.dart';

import '../domain/entities/tour_guide_answer.dart';
import '../domain/repositories/tour_guide_repository.dart';

class TourGuidePage extends StatefulWidget {
  const TourGuidePage({super.key, required this.repository});

  final TourGuideRepository? repository;

  @override
  State<TourGuidePage> createState() => _TourGuidePageState();
}

class _TourGuidePageState extends State<TourGuidePage> {
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[
    const _ChatMessage(
      text:
          'مرحباً، أنا المساعد الذكي في سوف 360. أساعدك في إعداد زيارة مميزة لوادي سوف عبر اقتراح مسارات ومعلومات ثقافية ونصائح عملية من المعالم المنشورة.',
      isUser: false,
    ),
  ];
  var _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _askPreset(String question) {
    _controller.text = question;
    _send();
  }

  Future<void> _send() async {
    final repository = widget.repository;
    final question = _controller.text.trim();
    if (repository == null || question.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text: question, isUser: true));
      _controller.clear();
      _isSending = true;
    });

    try {
      final answer = await repository.ask(question: question);
      if (!mounted) return;
      setState(
          () => _messages.add(_ChatMessage(answer: answer, isUser: false)));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          const _ChatMessage(
            text:
                'يتعذر عليّ الإجابة الآن. تحقق من اتصال الإنترنت ثم أعد المحاولة.',
            isUser: false,
            isError: true,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.repository != null;
    return Scaffold(
      appBar: AppBar(title: const Text('المساعد الذكي')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: _GuideHero(isAvailable: isAvailable),
          ),
          if (isAvailable)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _PromptChip(
                      label: 'زيارة نصف يوم',
                      onTap: () =>
                          _askPreset('ماذا تقترح لزيارة نصف يوم في وادي سوف؟')),
                  _PromptChip(
                      label: 'معالم تراثية',
                      onTap: () => _askPreset(
                          'ما أبرز المعالم التراثية المنشورة في وادي سوف؟')),
                  _PromptChip(
                      label: 'نصائح الزيارة',
                      onTap: () => _askPreset(
                          'ما النصائح العملية لزيارة وادي سوف اليوم؟')),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: _GuideUnavailableNotice(),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return const _TypingIndicator();
                return _MessageBubble(message: _messages[index]);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: isAvailable && !_isSending,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'اسأل عن مكان، تجربة أو برنامج زيارة…',
                        prefixIcon: Icon(Icons.auto_awesome_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'إرسال السؤال',
                    onPressed: isAvailable && !_isSending ? _send : null,
                    icon: const Icon(Icons.send_rounded),
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

class _ChatMessage {
  const _ChatMessage(
      {this.text, this.answer, required this.isUser, this.isError = false});

  final String? text;
  final TourGuideAnswer? answer;
  final bool isUser;
  final bool isError;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final answer = message.answer;
    final text = answer?.answer ?? message.text ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isUser
                ? scheme.primary
                : message.isError
                    ? scheme.errorContainer
                    : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isUser ? scheme.onPrimary : scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (answer?.suggestions.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  ...answer!.suggestions.map(
                    (suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $suggestion'),
                    ),
                  ),
                ],
                if (answer?.disclaimer?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    answer!.disclaimer!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideHero extends StatelessWidget {
  const _GuideHero({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF193F38),
                child:
                    Icon(Icons.auto_awesome_rounded, color: Color(0xFFE5B65A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مساعدك الذكي في وادي سوف',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      isAvailable
                          ? 'اسأل عن المعالم وبرامج الزيارة والنصائح العملية.'
                          : 'يتطلب المساعد اتصالاً آمناً بخدمة Souf360.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ActionChip(
          avatar: const Icon(Icons.chat_bubble_outline, size: 16),
          label: Text(label),
          onPressed: onTap,
        ),
      );
}

class _GuideUnavailableNotice extends StatelessWidget {
  const _GuideUnavailableNotice();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'المساعد الذكي غير متاح حالياً. يمكنك متابعة الاستكشاف من الخريطة وبوصلة سوف، ثم إعادة المحاولة عند توفر الاتصال الآمن.',
          ),
        ),
      );
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('يجري المساعد إعداد الإجابة…'),
            ],
          ),
        ),
      );
}

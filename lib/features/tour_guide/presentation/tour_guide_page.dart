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
          'Bonjour, je suis votre guide Souf Tour. Je peux vous aider à préparer une découverte respectueuse d’El Oued : idées de parcours, culture locale et conseils pratiques.',
      isUser: false,
    ),
  ];
  var _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                'Je ne peux pas répondre pour le moment. Vérifiez votre connexion puis réessayez.',
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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guide intelligent',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Une aide conversationnelle fondée sur les informations publiées. Vérifiez toujours les conditions de visite auprès des sources locales.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!isAvailable) ...[
                  const SizedBox(height: 12),
                  const _GuideUnavailableNotice(),
                ],
              ],
            ),
          ),
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
                        hintText:
                            'Ex. Que me conseillez-vous pour une demi-journée ?',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Envoyer la question',
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

class _GuideUnavailableNotice extends StatelessWidget {
  const _GuideUnavailableNotice();

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Le guide sera disponible une fois Supabase configuré avec une clé publique et la fonction tour-guide déployée.',
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
              Text('Le guide prépare sa réponse…'),
            ],
          ),
        ),
      );
}

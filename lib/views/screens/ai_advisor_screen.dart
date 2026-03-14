import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/farm_providers.dart';
import '../../viewmodels/locale_provider.dart';
import '../widgets/glass_card.dart';

class AiAdvisorScreen extends ConsumerStatefulWidget {
  const AiAdvisorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends ConsumerState<AiAdvisorScreen> {
  final _questionCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _ask([String? question]) async {
    final farm = ref.read(selectedFarmProvider);
    final ds = ref.read(dashboardProvider);
    final gemini = ref.read(geminiServiceProvider);
    final languageCode = ref.read(localeProvider).languageCode;

    final userQ = question ?? _questionCtrl.text.trim();
    if (userQ.isNotEmpty) {
      setState(() => _messages.add(_ChatMessage(text: userQ, isUser: true)));
      _questionCtrl.clear();
    }

    setState(() => _isLoading = true);
    _scrollToBottom();

    final ndvi = ds.vegetation?.ndvi ?? ds.summary?.ndvi ?? 0.0;
    final soilMoist = ds.summary?.soilMoisture ?? 0.0;
    final temp = ds.summary?.temperature ?? 0.0;
    final rain = ds.summary?.rainProbability ?? 0.0;

    String? pestAdvisory;
    if (ds.cropAdvisory.isNotEmpty) {
      pestAdvisory = ds.cropAdvisory
          .map((a) => '${a.title}: ${a.symptoms} → ${a.solution}')
          .join('; ');
    }

    String? calendarInfo;
    if (ds.cropCalendar.isNotEmpty) {
      calendarInfo = ds.cropCalendar
          .map((c) => 'Day ${c.range}: ${c.recommended}')
          .join('; ');
    }

    try {
      final response = await gemini.getAdvice(
        cropType: farm?.cropType ?? 'Unknown',
        ndvi: ndvi,
        soilMoisture: soilMoist,
        temperature: temp,
        rainProbability: rain,
        pestAdvisory: pestAdvisory,
        cropCalendar: calendarInfo,
        userQuestion: userQ.isNotEmpty ? userQ : null,
      );
      final localized = await gemini.translateText(
        text: response,
        targetLanguageCode: languageCode,
      );
      setState(() {
        _messages.add(_ChatMessage(text: localized, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: 'Error: $e', isUser: false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final farm = ref.watch(selectedFarmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.softPurple, size: 20),
            SizedBox(width: 8),
            Text(
              'AI FARM ADVISOR',
              style: TextStyle(
                color: AppColors.softPurple,
                fontSize: 16,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick action chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickChip(
                    '🌱 General Assessment',
                    () => _ask('Give me a general farm health assessment'),
                  ),
                  const SizedBox(width: 8),
                  _quickChip(
                    '💧 Irrigation Advice',
                    () => _ask('When should I irrigate my crop?'),
                  ),
                  const SizedBox(width: 8),
                  _quickChip(
                    '🐛 Pest Control',
                    () => _ask(
                      'What pests should I watch for and how to control them?',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _quickChip(
                    '🌿 Fertilizer Plan',
                    () => _ask('What fertilizer should I apply now?'),
                  ),
                  const SizedBox(width: 8),
                  _quickChip(
                    '📊 Yield Forecast',
                    () => _ask(
                      'What is the expected yield based on current conditions?',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 48,
                            color: AppColors.softPurple,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'AI Farm Advisor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            farm != null
                                ? 'Ask me anything about your ${farm.cropType} farm.\nI have access to your NDVI, weather, and advisory data.'
                                : 'Select a farm first to get personalized recommendations.',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length && _isLoading) {
                        return _aiTypingIndicator();
                      }
                      return _messageBubble(_messages[i]);
                    },
                  ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryAccent.withOpacity(0.2),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ask about your farm...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _ask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : () => _ask(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey : AppColors.softPurple,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.softPurple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.softPurple.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.softPurple,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _messageBubble(_ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primaryAccent.withOpacity(0.15)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? AppColors.primaryAccent.withOpacity(0.3)
                : AppColors.softPurple.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUser ? Icons.person : Icons.auto_awesome,
                  color: isUser
                      ? AppColors.primaryAccent
                      : AppColors.softPurple,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  isUser ? 'You' : 'AI Advisor',
                  style: TextStyle(
                    color: isUser
                        ? AppColors.primaryAccent
                        : AppColors.softPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.softPurple.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.softPurple,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Analyzing farm data...',
              style: TextStyle(color: AppColors.softPurple, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

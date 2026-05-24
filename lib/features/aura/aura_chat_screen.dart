import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';

class AuraChatScreen extends StatefulWidget {
  const AuraChatScreen({super.key});

  @override
  State<AuraChatScreen> createState() => _AuraChatScreenState();
}

class _AuraChatScreenState extends State<AuraChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  // Örnek hızlı sorular
  List<String> getQuickQuestions(bool isTr) {
    return isTr
        ? [
            '🍳 Kahvaltılık öneri',
            '🥗 Düşük kalorili yemek',
            '🍰 Kolay tatlı tarifi',
            '🥘 Akşam yemeği fikri',
          ]
        : [
            '🍳 Breakfast suggestion',
            '🥗 Low calorie food',
            '🍰 Easy dessert recipe',
            '🥘 Dinner idea',
          ];
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.isEmpty) {
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      _messages.add(_ChatMessage(
        text: isTr
            ? 'Merhaba! Ben Aura Şef 👨‍🍳\n\nMutfakla ilgili her şeyi bana sorabilirsin. Tarif, malzeme önerisi, pişirme tekniği… Hadi başlayalım!'
            : 'Hello! I am Aura Chef 👨‍🍳\n\nYou can ask me anything about the kitchen. Recipes, ingredient ideas, cooking techniques... Let\'s get started!',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final userId = ServiceLocator.auth.currentUser?.uid;
    if (userId != null) {
      ServiceLocator.gamification.incrementAction(userId, 'aiUsesCount');
      ServiceLocator.gamification.incrementDailyQuest(userId, 'dailyAiChats');
    }

    try {
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      final response = await ServiceLocator.groqChat.sendMessage(text.trim(), isTurkish: isTr);

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final isTr = Localizations.localeOf(context).languageCode == 'tr';
        setState(() {
          _messages.add(_ChatMessage(
            text: isTr ? 'Bir hata oluştu. Lütfen tekrar deneyin.' : 'An error occurred. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  // ───────────── AppBar ─────────────
  PreferredSizeWidget _buildAppBar() {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new,
            size: 20, color: AppColors.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.accent,
                ],
              ),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTr ? 'Aura Şef' : 'Aura Chef',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                isTr ? 'AI Mutfak Asistanı' : 'AI Kitchen Assistant',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded,
              size: 22, color: AppColors.onSurfaceVariant),
          onPressed: () {
            ServiceLocator.groqChat.clearHistory();
            setState(() {
              _messages.clear();
              _messages.add(_ChatMessage(
                text: isTr
                    ? 'Sohbet sıfırlandı! 🔄\nYeni bir konuşmaya başlayalım. Ne pişirmek istersin?'
                    : 'Chat reset! 🔄\nLet\'s start a new conversation. What would you like to cook?',
                isUser: false,
                timestamp: DateTime.now(),
              ));
            });
          },
          tooltip: isTr ? 'Sohbeti Sıfırla' : 'Reset Chat',
        ),
      ],
    );
  }

  // ───────────── Mesaj Listesi ─────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _messages.length + (_messages.length <= 1 ? 1 : 0),
      itemBuilder: (context, index) {
        // İlk mesajdan sonra hızlı sorular
        if (index == _messages.length && _messages.length <= 1) {
          return _buildQuickQuestions();
        }
        return _buildMessageBubble(_messages[index], index);
      },
    );
  }

  // ───────────── Hızlı Sorular ─────────────
  Widget _buildQuickQuestions() {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    final quickQuestions = getQuickQuestions(isTr);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              isTr ? 'Hızlı başlangıç:' : 'Quick start:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickQuestions.map((q) {
              return GestureDetector(
                onTap: () => _sendMessage(q),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    q,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  // ───────────── Mesaj Baloncuğu ─────────────
  Widget _buildMessageBubble(_ChatMessage message, int index) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? AppColors.primary : Colors.black)
                        .withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isUser
                      ? Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurface,
                            ),
                            strong: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                            em: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.onSurface,
                            ),
                            h2: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                            ),
                            h3: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            listBullet: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                          shrinkWrap: true,
                        ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? AppColors.onPrimary.withValues(alpha: 0.6)
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ───────────── Yazıyor Göstergesi ─────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child:
                const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  // ───────────── Mesaj Giriş Alanı ─────────────
  Widget _buildInputArea() {
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: isTr ? 'Aura Şef\'e sor...' : 'Ask Aura Chef...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                      onSubmitted: (text) => _sendMessage(text),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────── Mesaj Modeli ─────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

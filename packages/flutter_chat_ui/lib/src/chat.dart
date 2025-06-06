import 'package:cross_cache/cross_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:provider/provider.dart';
import 'chat_animated_list/chat_animated_list.dart';
import 'chat_input.dart';
import 'chat_message/chat_message_internal.dart';
import 'utils/chat_input_height_notifier.dart';
import 'utils/load_more_notifier.dart';
import 'utils/typedefs.dart';

class Chat extends StatefulWidget {
  static const Color _sentinelColor = Colors.transparent;

  final String currentUserId;
  final ResolveUserCallback resolveUser;
  final ChatController chatController;
  final Builders? builders;
  final CrossCache? crossCache;
  final ChatTheme? theme;
  final OnMessageSendCallback? onMessageSend;
  final OnMessageTapCallback? onMessageTap;
  final OnMessageLongPressCallback? onMessageLongPress;
  final OnAttachmentTapCallback? onAttachmentTap;
  final Color? backgroundColor;
  final Decoration? decoration;
  final DateFormat? timeFormat;

  const Chat({
    super.key,
    required this.currentUserId,
    required this.resolveUser,
    required this.chatController,
    this.builders,
    this.crossCache,
    this.theme,
    this.onMessageSend,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onAttachmentTap,
    this.backgroundColor = _sentinelColor,
    this.decoration,
    this.timeFormat,
  });

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with WidgetsBindingObserver {
  late ChatTheme _theme;
  late Builders _builders;
  late final CrossCache _crossCache;
  late DateFormat _timeFormat;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateTheme();
    _updateBuilders();
    _crossCache = widget.crossCache ?? CrossCache();
    _timeFormat = widget.timeFormat ?? DateFormat('HH:mm');
  }

  @override
  void didUpdateWidget(covariant Chat oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.theme != widget.theme) {
      _updateTheme();
    }

    if (oldWidget.builders != widget.builders) {
      _updateBuilders();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Only try to dispose cross cache if it's not provided, since
    // users might want to keep downloading media even after the chat
    // is disposed.
    if (widget.crossCache == null) {
      _crossCache.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.currentUserId),
        Provider.value(value: widget.resolveUser),
        Provider.value(value: widget.chatController),
        Provider.value(value: _theme),
        Provider.value(value: _builders),
        Provider.value(value: _crossCache),
        Provider.value(value: _timeFormat),
        Provider.value(value: widget.onMessageSend),
        Provider.value(value: widget.onMessageTap),
        Provider.value(value: widget.onMessageLongPress),
        Provider.value(value: widget.onAttachmentTap),
        ChangeNotifierProvider(create: (_) => ChatInputHeightNotifier()),
        ChangeNotifierProvider(create: (_) => LoadMoreNotifier()),
        Provider(create: (_) => UserCache(maxSize: 100)),
      ],
      child: Container(
        color:
            widget.backgroundColor == Chat._sentinelColor
                ? _theme.colors.surface
                : widget.backgroundColor,
        decoration: widget.decoration,
        child: Stack(
          children: [
            _builders.chatAnimatedListBuilder?.call(context, _buildItem) ??
                ChatAnimatedList(itemBuilder: _buildItem),
            _builders.inputBuilder?.call(context) ?? const ChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    Message message,
    int index,
    Animation<double> animation, {
    int? messageGroupingTimeoutInSeconds,
    bool? isRemoved,
  }) {
    return ChatMessageInternal(
      key: ValueKey(message),
      message: message,
      index: index,
      animation: animation,
      messageGroupingTimeoutInSeconds: messageGroupingTimeoutInSeconds,
      isRemoved: isRemoved,
    );
  }

  void _updateTheme() {
    _theme = widget.theme ?? ChatTheme.light();
  }

  void _updateBuilders() {
    _builders = widget.builders ?? const Builders();
  }
}

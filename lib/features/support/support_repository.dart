import '../../core/api_client.dart';
import '../../core/app_exception.dart';
import '../../core/dates.dart';
import '../../core/session_repository.dart';

/// A static FAQ entry. [question]/[answer] hold i18n keys (`sup.faq.*`)
/// resolved at the presentation layer.
class Faq {
  const Faq(this.id, this.questionKey, this.answerKey);

  final int id;
  final String questionKey;
  final String answerKey;
}

const List<Faq> faqCatalog = [
  Faq(1, 'sup.faq.1.q', 'sup.faq.1.a'),
  Faq(2, 'sup.faq.2.q', 'sup.faq.2.a'),
  Faq(3, 'sup.faq.3.q', 'sup.faq.3.a'),
  Faq(4, 'sup.faq.4.q', 'sup.faq.4.a'),
];

class ChatMessage {
  ChatMessage({required this.id, required this.authorRole, required this.body, required this.createdAt, this.authorName});

  final String id;
  final String authorRole;
  final String body;
  final String createdAt;
  final String? authorName;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        authorRole: json['authorRole']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
        authorName: json['authorName']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorRole': authorRole,
        'body': body,
        'createdAt': createdAt,
        'authorName': authorName,
      };
}

class SupportChat {
  SupportChat({
    required this.id,
    this.residentId = '',
    this.residentName = '',
    this.topic = 'Soporte',
    this.status = 'open',
    this.messages = const [],
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String id;
  final String residentId;
  final String residentName;
  final String topic;
  final String status;
  final List<ChatMessage> messages;
  final String createdAt;
  final String updatedAt;

  factory SupportChat.fromJson(Map<String, dynamic> json) => SupportChat(
        id: json['id']?.toString() ?? '',
        residentId: json['residentId']?.toString() ?? '',
        residentName: json['residentName']?.toString() ?? '',
        topic: json['topic']?.toString() ?? 'Soporte',
        status: json['status']?.toString() ?? 'open',
        messages: (json['messages'] as List? ?? const [])
            .map((e) => ChatMessage.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'residentId': residentId,
        'residentName': residentName,
        'topic': topic,
        'status': status,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  SupportChat copyWith({List<ChatMessage>? messages, String? updatedAt}) => SupportChat(
        id: id,
        residentId: residentId,
        residentName: residentName,
        topic: topic,
        status: status,
        messages: messages ?? this.messages,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Support data access (resident side: FAQs + own chats).
class SupportRepository {
  SupportRepository(this._api, this._session);

  final ApiClient _api;
  final SessionRepository _session;

  List<Faq> faqs() => faqCatalog;

  /// `GET supportChats?residentId=` sorted by last activity.
  Future<List<SupportChat>> listChatsForResident(String residentId) => apiCall(() async {
        final response = await _api.dio.get<List<dynamic>>(
          'supportChats',
          queryParameters: _api.ownerParams({
            'residentId': residentId,
            '_sort': 'updatedAt',
            '_order': 'desc',
          }),
        );
        return (response.data ?? const [])
            .map((e) => SupportChat.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });

  /// `POST supportChats`
  Future<SupportChat> createChat({
    required String residentId,
    required String residentName,
    required String topic,
  }) =>
      apiCall(() async {
        final ownerId = _session.activeDataOwnerId;
        if (ownerId == null) throw AppException('OWNER_REQUIRED', '');
        final now = Dates.nowIso();
        final response = await _api.dio.post<dynamic>(
          'supportChats',
          data: {
            'id': 'support-chat-${DateTime.now().millisecondsSinceEpoch}',
            'ownerAdminId': ownerId,
            'residentId': residentId,
            'residentName': residentName,
            'topic': topic.trim().isEmpty ? 'Soporte' : topic.trim(),
            'status': 'open',
            'messages': <dynamic>[],
            'createdAt': now,
            'updatedAt': now,
          },
        );
        return SupportChat.fromJson(
          (response.data as Map?)?.cast<String, dynamic>() ?? const {},
        );
      });

  Future<SupportChat> getChat(String id) => apiCall(() async {
        final response = await _api.dio.get<Map<dynamic, dynamic>>('supportChats/$id');
        return SupportChat.fromJson((response.data ?? const {}).cast<String, dynamic>());
      });

  /// Read-modify-write, mirroring the web `appendMessageInternal`.
  Future<SupportChat> appendMessage(String chatId, String authorRole, String body, {String? authorName}) =>
      apiCall(() async {
        final chat = await getChat(chatId);
        final now = Dates.nowIso();
        final row = ChatMessage(
          id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
          authorRole: authorRole,
          body: body.trim(),
          createdAt: now,
          authorName: authorName,
        );
        final updated = chat.copyWith(
          messages: [...chat.messages, row],
          updatedAt: now,
        );
        final response = await _api.dio.put<Map<dynamic, dynamic>>(
          'supportChats/$chatId',
          data: updated.toJson(),
        );
        return SupportChat.fromJson((response.data ?? const {}).cast<String, dynamic>());
      });
}

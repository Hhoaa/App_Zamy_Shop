import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/chat.dart';

class SupabaseChatService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Ensure a chat exists between user and admin; return chat id
  static Future<int?> ensureChatWithAdmin(int userId, int adminId) async {
    try {
      // Allow creating chat even if userId == adminId (for testing/admin self-chat)
      // Fetch the unique chat between the two participants (either order), prefer earliest
      final existing = await _client
          .from('chats')
          .select()
          .or(
            'and(ma_nguoi_dung_1.eq.$userId,ma_nguoi_dung_2.eq.$adminId),and(ma_nguoi_dung_1.eq.$adminId,ma_nguoi_dung_2.eq.$userId)',
          )
          .order('ngay_tao', ascending: true)
          .limit(1);
      if (existing.isNotEmpty) {
        return existing.first['ma_chat'] as int;
      }
      final inserted =
          await _client.from('chats').insert({
            'ma_nguoi_dung_1': userId,
            'ma_nguoi_dung_2': adminId,
            'trang_thai': true,
          }).select();
      if (inserted.isNotEmpty) return inserted.first['ma_chat'] as int;
      return null;
    } catch (e) {
      print('Chat ensure error: $e');
      return null;
    }
  }

  static Future<List<ChatMessage>> fetchMessages(int chatId) async {
    try {
      final res = await _client
          .from('chat_messages')
          .select()
          .eq('ma_chat', chatId)
          .order('thoi_gian_gui', ascending: true);
      return (res as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Fetch messages error: $e');
      return [];
    }
  }

  static Future<bool> sendMessage({
    required int chatId,
    required int senderId,
    required String content,
    String type = 'text',
    int? parentId,
  }) async {
    try {
      final payload = {
        'ma_chat': chatId,
        'ma_nguoi_gui': senderId,
        'noi_dung': content,
        'loai_tin_nhan': type,
        'da_doc': false,
        'ma_tin_nhan_cha': parentId,
      };
      // Debug payload
      // ignore: avoid_print
      print('[CHAT] insert message payload: ' + payload.toString());
      final inserted =
          await _client
              .from('chat_messages')
              .insert(payload)
              .select('ma_tin_nhan, ma_nguoi_gui, thoi_gian_gui')
              .single();
      // ignore: avoid_print
      print('[CHAT] insert ok -> ' + inserted.toString());
      return true;
    } catch (e) {
      print('[CHAT][ERROR] sendMessage failed: $e');
      return false;
    }
  }

  static Stream<List<ChatMessage>> subscribeMessages(int chatId) {
    // Use simple polling for now to avoid realtime client issues
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['ma_tin_nhan'])
        .eq('ma_chat', chatId)
        .order('thoi_gian_gui', ascending: true)
        .map((rows) => rows.map((e) => ChatMessage.fromJson(e)).toList());
  }

  // Gửi tin nhắn đầu tiên của user và tự động phản hồi từ admin nếu là lần đầu
  static Future<bool> sendUserMessageWithAutoAdminReply({
    required int chatId,
    required int userId,
    int? adminId,
    required String content,
  }) async {
    try {
      // Gửi tin nhắn của user
      final ok = await sendMessage(
        chatId: chatId,
        senderId: userId,
        content: content,
      );
      print('[CHAT] user message sent: ' + ok.toString());
      if (!ok) return false;

      // Gửi auto-reply ngay sau mỗi tin nhắn của user (không cần if)
      int resolvedAdminId =
          adminId ?? await _getOtherParticipantId(chatId, userId) ?? userId;
      print('[CHAT] resolved adminId: ' + resolvedAdminId.toString());
      if (resolvedAdminId != userId) {
        final autoText =
            'Xin chào! Đây là tin nhắn tự động từ admin. Chúng tôi sẽ phản hồi bạn sớm nhất có thể, vui lòng chờ.';
        final adminOk = await sendMessage(
          chatId: chatId,
          senderId: resolvedAdminId,
          content: autoText,
        );
        print('[CHAT] admin auto-reply inserted: ' + adminOk.toString());
        if (!adminOk) {
          // Fallback: lưu tin nhắn auto-reply như hệ thống để vẫn hiển thị được
          final fallbackOk = await sendMessage(
            chatId: chatId,
            senderId: userId,
            content: autoText,
            type: 'auto_admin',
          );
          print(
            '[CHAT] fallback auto_admin inserted by user: ' +
                fallbackOk.toString(),
          );
        }
      }

      return true;
    } catch (e) {
      print('[CHAT][ERROR] sendUserMessageWithAutoAdminReply: $e');
      return false;
    }
  }

  // Lấy ID người còn lại trong cuộc chat (ví dụ admin) so với currentUserId
  static Future<int?> _getOtherParticipantId(
    int chatId,
    int currentUserId,
  ) async {
    try {
      final row =
          await _client
              .from('chats')
              .select('ma_nguoi_dung_1, ma_nguoi_dung_2')
              .eq('ma_chat', chatId)
              .maybeSingle();
      print('[CHAT] chat row for participants: ' + (row?.toString() ?? 'null'));
      if (row == null) return null;
      final a = row['ma_nguoi_dung_1'] as int?;
      final b = row['ma_nguoi_dung_2'] as int?;
      if (a == null && b == null) return null;
      if (a == currentUserId) return b;
      if (b == currentUserId) return a;
      // fallback: trả về a nếu có
      return a ?? b;
    } catch (_) {
      print('[CHAT][ERROR] _getOtherParticipantId failed');
      return null;
    }
  }
}

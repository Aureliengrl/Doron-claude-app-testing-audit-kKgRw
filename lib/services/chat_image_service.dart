import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '/utils/app_logger.dart';
import '/services/firebase_data_service.dart';

/// Service d'envoi d'images dans le chat.
class ChatImageService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();

  /// Ouvre le sélecteur d'images et envoie l'image dans le chat.
  /// Retourne true si envoyé avec succès.
  static Future<bool> pickAndSendImage({
    required String chatId,
    ImageSource source = ImageSource.gallery,
  }) async {
    final myUid = FirebaseDataService.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return false;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked == null) return false;

      // Compresser l'image
      final compressed = await _compressImage(File(picked.path));
      final fileToUpload = compressed ?? File(picked.path);

      // Upload vers Firebase Storage
      final fileName =
          'chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}_$myUid.jpg';
      final ref = _storage.ref().child(fileName);
      final uploadTask = await ref.putFile(
        fileToUpload,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final imageUrl = await uploadTask.ref.getDownloadURL();

      // Envoyer le message de type image
      final messageRef =
          _db.collection('chats').doc(chatId).collection('messages').doc();

      await messageRef.set({
        'id': messageRef.id,
        'senderId': myUid,
        'text': imageUrl,
        'type': 'image',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Mettre à jour le dernier message du chat
      await _db.collection('chats').doc(chatId).update({
        'lastMessage': '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      AppLogger.debug('Image sent in chat $chatId', 'Chat');
      return true;
    } catch (e) {
      AppLogger.debug('ChatImageService.pickAndSendImage: $e', 'Chat');
      return false;
    }
  }

  /// Compresse une image pour le chat.
  static Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/chat_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      AppLogger.debug('ChatImageService._compressImage: $e', 'Chat');
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../di/service_locator.dart';

class CustomUserAvatar extends StatelessWidget {
  final double radius;
  
  final String? userId;
  
  const CustomUserAvatar({super.key, this.radius = 20, this.userId});

  @override
  Widget build(BuildContext context) {
    final uid = userId ?? ServiceLocator.auth.currentUser?.uid;
    if (uid == null) return _buildFallback('U');

    return StreamBuilder<Map<String, dynamic>?>(
      stream: ServiceLocator.profile.getUserProfileStream(uid),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final photoUrl = data?['photoUrl'] as String?;
        final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
        final initial = data?['displayName']?.isNotEmpty == true 
            ? data!['displayName'][0].toUpperCase() 
            : 'U';

        if (!hasPhoto) return _buildFallback(initial);

        return CircleAvatar(
          radius: radius,
          backgroundImage: photoUrl.startsWith('data:image')
              ? MemoryImage(base64Decode(photoUrl.split(',').last)) as ImageProvider
              : CachedNetworkImageProvider(photoUrl),
        );
      },
    );
  }

  Widget _buildFallback(String letter) {
    return CircleAvatar(
      radius: radius,
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/v2ray_provider.dart';
import '../providers/language_provider.dart';
import '../services/tiksar_plus_service.dart';

/// Simple and user-friendly server source selector
/// 
/// Allows users to choose between:
/// - Tiksar Smart (default, intelligent protocol selection)
/// - Tiksar Plus (high-speed servers)
class ServerSourceSelector extends StatelessWidget {
  const ServerSourceSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<V2RayProvider>(
      builder: (context, provider, child) {
        // Auto mode is always enabled - always show selector
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: Colors.white.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Consumer<LanguageProvider>(
                  builder: (context, langProvider, _) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.dns,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                langProvider.translate('server_source.title'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                langProvider.translate('server_source.subtitle'),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Server count info
                if (provider.autoServers.isNotEmpty)
                  Consumer<LanguageProvider>(
                    builder: (context, langProvider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF10B981),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              langProvider.translate(
                                'server_source.servers_loaded',
                                parameters: {'count': '${provider.autoServers.length}'}
                              ),
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 16),
                
                // Server options
                Consumer<LanguageProvider>(
                  builder: (context, langProvider, _) {
                    return Column(
                      children: [
                        _buildServerOption(
                          context: context,
                          provider: provider,
                          langProvider: langProvider,
                          title: langProvider.translate('server_source.smart_title'),
                          subtitle: langProvider.translate('server_source.smart_subtitle'),
                          source: TiksarPlusService.sourceSmart,
                          isRecommended: true,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        _buildServerOption(
                          context: context,
                          provider: provider,
                          langProvider: langProvider,
                          title: langProvider.translate('server_source.plus_title'),
                          subtitle: langProvider.translate('server_source.plus_subtitle'),
                          source: TiksarPlusService.sourcePlus,
                          isRecommended: false,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServerOption({
    required BuildContext context,
    required V2RayProvider provider,
    required LanguageProvider langProvider,
    required String title,
    required String subtitle,
    required String source,
    bool isRecommended = false,
  }) {
    final bool isSelected = provider.serverSource == source;
    
    return GestureDetector(
      onTap: provider.isLoadingServers 
          ? null 
          : () async {
              // Show confirmation dialog
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Icon(
                        Icons.swap_horiz,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        langProvider.translate('server_source.change_dialog_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    langProvider.translate(
                      'server_source.change_dialog_message',
                      parameters: {'title': title}
                    ),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        langProvider.translate('common.cancel'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(langProvider.translate('server_source.switch_button')),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Show loading
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                try {
                  await provider.changeServerSource(source);
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          langProvider.translate(
                            'server_source.switched_success',
                            parameters: {'title': title}
                          )
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          langProvider.translate(
                            'server_source.error_prefix',
                            parameters: {'error': e.toString()}
                          )
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF4F46E5),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            langProvider.translate('server_source.recommended'),
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selected checkmark
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

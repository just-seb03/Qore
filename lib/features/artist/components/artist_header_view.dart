/// File: artist_header_view.dart
/// Description: Large interactive artist header component featuring circular avatar,
/// atmospheric halo glow, floating pencil edit badge, and centered artist name.
///
/// Components / Classes / Functions:
/// - ArtistHeaderView: Top header view presenting the artist avatar and title.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';

/// Large interactive header featuring circular avatar, atmospheric halo glow,
/// floating pencil edit badge, and centered artist name directly below.
class ArtistHeaderView extends StatelessWidget {
  /// Name of the artist to display.
  final String artistName;

  /// Callback invoked when the user taps the edit photo badge.
  final VoidCallback onEditTap;

  const ArtistHeaderView({
    super.key,
    required this.artistName,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Avatar with Atmospheric Halo & Floating Edit Pencil Badge
          Stack(
            alignment: Alignment.center,
            children: [
              // Ambient soft halo
              Container(
                width: 200.0,
                height: 200.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 22.0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: MaterialArtistAvatar(
                      radius: 66.0,
                      artistName: artistName,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      iconColor: AppColors.onSurfaceVariant,
                    ),
                  ),

                  // Sleek Elevated Edit Button
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEditTap,
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 8.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 19.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),

          // Artist Name Typography directly below avatar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              artistName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 27.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

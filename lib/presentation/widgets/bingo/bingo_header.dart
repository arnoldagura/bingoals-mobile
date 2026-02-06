import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';

/// BINGO header row with letters B I N G O
class BingoHeader extends StatelessWidget {
  const BingoHeader({super.key});

  static const List<String> letters = ['B', 'I', 'N', 'G', 'O'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bingoHeader,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: letters.map((letter) => _buildLetterCell(letter)).toList(),
      ),
    );
  }

  Widget _buildLetterCell(String letter) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            letter,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.bingoHeaderText,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LedPreviewCard extends StatelessWidget {
  final String petrol;
  final String diesel;

  const LedPreviewCard({
    super.key,
    required this.petrol,
    required this.diesel,
  });

  @override
  Widget build(BuildContext context) {
    final cleanPetrol = petrol.isEmpty ? '0.00' : petrol;
    final cleanDiesel = diesel.isEmpty ? '0.00' : diesel;
    final displayText = 'PETROL : $cleanPetrol   DIESEL : $cleanDiesel';

    return Card(
      elevation: 4,
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFF9900), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_rounded, color: Color(0xFFFF9900), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'P10 LED DISPLAY PREVIEW',
                      style: TextStyle(
                        color: Color(0xFFFF9900),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  '64×16 MATRIX',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  displayText,
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFFFF9900),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82, // كبرنا النافبار شوي عشان تاخذ الصور راحتها
      decoration: BoxDecoration(
        color: Colors.black87,
        // تم تصحيح اسم صورة الخلفية بناءً على ملفاتك المرفوعة
        image: const DecorationImage(
          image: AssetImage('assets/images/ui/bottom_navbar_bg.png'),
          fit: BoxFit.cover,
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFF856024), width: 2), // الإطار النحاسي
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, 'assets/images/icons/inventory.png', 'المخزن'),
          _buildNavItem(1, 'assets/images/icons/chat.png', 'الشات'),
          _buildNavItem(2, 'assets/images/icons/map.png', 'الخريطة'),
          _buildNavItem(3, 'assets/images/icons/crime.png', 'الجرائم'),
          _buildNavItem(4, 'assets/images/icons/news.png', 'الأخبار'),
          _buildNavItem(5, 'assets/images/icons/profile.png', 'الزعيم'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String imagePath, String label) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: const Color(0xFFC5A059).withOpacity(0.6),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
                  : [],
              border: isSelected ? Border.all(color: const Color(0xFFC5A059), width: 1.5) : null,
            ),
            child: Opacity(
              // هنا خففنا التظليل! صارت الأيقونة واضحة حتى لو مو محددة
              opacity: isSelected ? 1.0 : 0.75,
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  // هنا كبرنا حجم الصور
                  width: isSelected ? 48 : 44,
                  height: isSelected ? 48 : 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, color: Colors.red, size: 28);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Changa',
              fontSize: 12, // كبرنا الخط نتفة عشان يتناسب مع حجم الأيقونة
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              // فتحنا لون النص للأيقونات الغير محددة عشان ينقري بسهولة
              color: isSelected ? const Color(0xFFE2C275) : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
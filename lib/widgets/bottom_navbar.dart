import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // ارتفاع النافبار
      decoration: BoxDecoration(
        color: Colors.black87, // لون الخلفية (بيتغير للصورة لاحقاً)
        // إذا عندك صورة خشب للنافبار، شيل الـ // من هنا:
         image: const DecorationImage(
           image: AssetImage('assets/images/ui/bottom_navbar_bg.png'),
           fit: BoxFit.cover,
         ),
        border: const Border(
          top: BorderSide(color: Color(0xFF856024), width: 2), // خط نحاسي يفصل النافبار عن الشاشة
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(0, -5), // ظل خفيف للأعلى
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.inventory, 'المخزن'),
          _buildNavItem(1, Icons.phone, 'الشات'),
          _buildNavItem(2, Icons.map, 'الخريطة'),
          _buildNavItem(3, Icons.local_police, 'الجرائم'),
          _buildNavItem(4, Icons.newspaper, 'الأخبار'),
          _buildNavItem(5, Icons.person, 'الزعيم'),
        ],
      ),
    );
  }

  // دالة لبناء كل زر في النافبار
  Widget _buildNavItem(int index, IconData iconData, String label) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque, // عشان مساحة الضغط تصير أكبر وأسهل للاعب
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // شكل الأيقونة
          AnimatedContainer(
            duration: const Duration(milliseconds: 300), // حركة ناعمة عند التبديل
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFFC5A059).withOpacity(0.2) : Colors.transparent,
              border: isSelected ? Border.all(color: const Color(0xFFC5A059), width: 1.5) : null,
            ),
            // إذا بغيت تستخدم صورك بدل الأيقونات، استبدل الـ Icon بـ Image.asset
            child: Icon(
              iconData,
              color: isSelected ? const Color(0xFFE2C275) : Colors.grey[500],
              size: isSelected ? 26 : 22, // تكبر الأيقونة شوي إذا كانت محددة
            ),
          ),
          const SizedBox(height: 4),
          // اسم القسم
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo', // تأكد إن الخط شغال
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFFE2C275) : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
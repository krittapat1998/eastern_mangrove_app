import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final inputPath =
      '/Users/krittapatseangsomjai/WebApp/Code Fultter/EasternMangroveCommunities/logo2.png';
  final outputDir =
      '/Users/krittapatseangsomjai/WebApp/Code Fultter/EasternMangroveCommunities/logo_sizes';

  // สร้าง output folder
  final dir = Directory(outputDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  // ขนาดที่ต้องการ (ชื่อไฟล์ → ขนาด)
  final sizes = {
    'icon_512x512.png': 512, // Google Play Store
    'icon_1024x1024.png': 1024, // App Store Connect
    'icon_192x192.png': 192, // Android adaptive icon
    'icon_144x144.png': 144, // Android hdpi
    'icon_96x96.png': 96, // Android mdpi
    'icon_72x72.png': 72, // Android ldpi
    'icon_48x48.png': 48, // Notification icon
    'icon_32x32.png': 32, // Favicon
  };

  // อ่านไฟล์ต้นฉบับ
  print('📂 กำลังอ่านไฟล์: $inputPath');
  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('❌ ไม่พบไฟล์: $inputPath');
    exit(1);
  }

  final originalBytes = inputFile.readAsBytesSync();
  final originalImage = img.decodeImage(originalBytes);

  if (originalImage == null) {
    print('❌ ไม่สามารถอ่านรูปภาพได้');
    exit(1);
  }

  print('✅ ภาพต้นฉบับ: ${originalImage.width}x${originalImage.height}px');
  print('📁 บันทึกไฟล์ที่: $outputDir\n');

  // resize แต่ละขนาด
  for (final entry in sizes.entries) {
    final fileName = entry.key;
    final size = entry.value;

    final resized = img.copyResize(
      originalImage,
      width: size,
      height: size,
      interpolation: img.Interpolation.cubic,
    );

    final outputPath = '$outputDir/$fileName';
    File(outputPath).writeAsBytesSync(img.encodePng(resized));
    print('✅ สร้างแล้ว: $fileName (${size}x${size}px)');
  }

  print('\n🎉 เสร็จสิ้น! ไฟล์ทั้งหมดอยู่ที่: $outputDir');
}

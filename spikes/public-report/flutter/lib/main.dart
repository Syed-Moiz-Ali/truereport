import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

void main() {
  const semantics = bool.fromEnvironment('SEMANTICS', defaultValue: false);
  if (semantics) {
    WidgetsFlutterBinding.ensureInitialized();
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const ReportApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    html.document.body?.setAttribute('data-report-ready', 'true');
  });
}

class ReportApp extends StatelessWidget {
  const ReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vehicle inspection report',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3B4A)),
        scaffoldBackgroundColor: const Color(0xFFF7FAFA),
        fontFamily: 'Arial',
      ),
      home: const ReportPage(),
    );
  }
}

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  static const List<List<String>> _rows = [
    [
      '1',
      'هوية المركبة والاستلام',
      'Vehicle identity and intake',
      'لا توجد مشكلة ملحوظة',
      'No issue observed',
    ],
    [
      '2',
      'الهيكل الخارجي والطلاء',
      'Exterior body panels and paint',
      'يوصى بالانتباه',
      'Attention recommended',
    ],
    [
      '3',
      'الزجاج والمرايا والإضاءة',
      'Glass, mirrors, lights and wipers',
      'تم اكتشاف عيب',
      'Defect found',
    ],
    [
      '4',
      'الإطارات والعجلات والفرامل',
      'Tyres, wheels and brakes',
      'لم يتم الفحص',
      'Not checked',
    ],
    [
      '5',
      'المقصورة وسلامة الركاب',
      'Interior and occupant safety',
      'لا ينطبق',
      'Not applicable',
    ],
    [
      '6',
      'المحرك والأنظمة الميكانيكية',
      'Engine and visible mechanical systems',
      'تعذر التحقق',
      'Could not verify',
    ],
    [
      '7',
      'ناقل الحركة ونظام الدفع',
      'Transmission and drivetrain',
      'يوصى بالانتباه',
      'Attention recommended',
    ],
    [
      '8',
      'التوجيه والتعليق',
      'Steering and suspension',
      'لا توجد مشكلة ملحوظة',
      'No issue observed',
    ],
    [
      '9',
      'الأنظمة الكهربائية والتكييف',
      'Electrical systems and air conditioning',
      'تم اكتشاف عيب',
      'Defect found',
    ],
    [
      '10',
      'أسفل الهيكل والعادم',
      'Underbody and exhaust',
      'لا توجد مشكلة ملحوظة',
      'No issue observed',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const _Header(),
                  const SizedBox(height: 16),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ملخص الفحص / Inspection summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'تم فحص المركبة في ورشة شريك في دبي. يغطي هذا التقرير الحالة الظاهرة وقت الفحص وبضمن النطاق المحدد فقط. '
                          'لا يمثل هذا التقرير ضماناً بأن المركبة خالية من العيوب، وليس شهادة فحص رسمية.',
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'The vehicle was inspected at a partner workshop in Dubai. This report records the visible condition at the time of inspection within the defined scope. '
                          'It is not a warranty or an official inspection certificate.',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'تغطية الفحص / Inspection coverage',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '113 من 120 فحصاً منطبقاً. هذه نسبة تغطية وليست درجة حالة المركبة.',
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          '113 of 120 applicable checks were completed. This is coverage, not a condition score.',
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final row in _rows) _CheckRow(row: row),
                  const SizedBox(height: 20),
                  const Text(
                    'معرض الأدلة / Evidence gallery',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.35,
                    children: [
                      for (var i = 1; i <= 20; i++)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.asset(
                                'assets/photos/photo-${i.toString().padLeft(2, '0')}.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'صورة دليل $i / Evidence $i',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'هذا التقرير يسجل حالة المركبة وقت الفحص. وهو ليس ضماناً وليس شهادة فحص رسمية. / '
                    'This report records the vehicle at the time of inspection. It is not a warranty or an official inspection certificate.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4D6670)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'تقرير فحص مركبة',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B3B4A),
            ),
          ),
          Text(
            'Vehicle inspection report',
            style: TextStyle(fontSize: 16, color: Color(0xFF4D6670)),
          ),
          SizedBox(height: 12),
          Text('TR-2026-0001 · v1', textDirection: TextDirection.ltr),
          Text('2026-11-03 14:30 GST', textDirection: TextDirection.ltr),
          Text('ورشة دبي للفحص الفني — Dubai Technical Inspection Workshop'),
          Text('تويوتا لاند كروزر 2022 — Toyota Land Cruiser 2022'),
          Text('VIN WUAZZZGY4NA901440', textDirection: TextDirection.ltr),
          Text('82,902 km', textDirection: TextDirection.ltr),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD5E3E6)),
      ),
      child: child,
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.row});
  final List<String> row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0EAEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${row[0]}. ${row[1]}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            row[2],
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4D6670)),
          ),
          const SizedBox(height: 4),
          Text('${row[3]} / ${row[4]}'),
        ],
      ),
    );
  }
}

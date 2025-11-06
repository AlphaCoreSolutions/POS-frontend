import 'package:visionpos/language_changing/constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I reset my password?',
      'answer':
          'Contact Alphacore Solutions To Change Password \n                        +962 7 7611 0639'
    },
    {
      'question': 'How do I contact support?',
      'answer':
          'Contact Us Through Our Email info@visioncit.com \n    Or Contact Us Through Phone  +962 7 7611 0639'
    },
    {
      'question': 'Is there a mobile app?',
      'answer':
          'For eligibility inquiries, kindly reach out to us through our listed contact information.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translation(context).support,
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Color(0xFF36454F),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
          final padding = isMobile
              ? 16.0
              : isTablet
                  ? 24.0
                  : 32.0;
          final titleFontSize = isMobile ? 18.0 : 20.0;
          final subtitleFontSize = isMobile ? 16.0 : 18.0;
          final buttonFontSize = isMobile ? 14.0 : 16.0;
          final iconSize = isMobile ? 20.0 : 24.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: translation(context).search,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      Text('FAQs',
                          style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ...faqs.map((faq) => Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: ExpansionTile(
                              title: Text(faq['question']!,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: subtitleFontSize)),
                              children: [
                                Padding(
                                    padding: EdgeInsets.all(padding),
                                    child: Text(faq['answer']!,
                                        style: TextStyle(
                                            fontSize: subtitleFontSize)))
                              ],
                            ),
                          )),
                      SizedBox(height: 20),
                      Text('More ${translation(context).help}?',
                          style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.email,
                          color: Color(0xFFE2725B),
                          size: iconSize,
                        ),
                        label: Text(
                          translation(context).email,
                          style: TextStyle(
                              color: Colors.black87, fontSize: buttonFontSize),
                        ),
                        onPressed: () {
                          // Open email app
                        },
                      ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: Icon(
                          Icons.phone,
                          color: Color(0xFFE2725B),
                          size: iconSize,
                        ),
                        label: Text(
                          translation(context).contactUs,
                          style: TextStyle(
                              color: Colors.black87, fontSize: buttonFontSize),
                        ),
                        onPressed: () async {
                          const phoneNumber = '+962776110639';
                          final Uri phoneUri =
                              Uri(scheme: 'tel', path: phoneNumber);
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Could not launch phone dialer')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.system,
    home: SupportPage(),
  ));
}

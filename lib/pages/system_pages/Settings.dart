import 'package:fixed_pos/L10n/app_localizations.dart';
import 'package:fixed_pos/main.dart';
import 'package:fixed_pos/language_changing/constants.dart';
import 'package:fixed_pos/language_changing/languages.dart';
import 'package:fixed_pos/models/promoCodes_model.dart';
import 'package:fixed_pos/models/taxes_model.dart';
import 'package:fixed_pos/pages/essential_pages/api_handler.dart';
import 'package:fixed_pos/utils/session_manager.dart';
import 'package:fixed_pos/components/api_settings_dialog.dart';
import 'package:fixed_pos/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedLanguage = 'en';
  final ApiHandler _apiHandler = ApiHandler();
  List<Promocodes> _promoCodes = [];
  Taxes? taxes;
  bool isLoading = false;
  TextEditingController inHouseController = TextEditingController();
  TextEditingController takeOutController = TextEditingController();
  double inHouseTax = 0.0;
  double takeOutTax = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPromoCodes();
    _loadTaxes();
  }

  @override
  void dispose() {
    inHouseController.dispose();
    takeOutController.dispose();
    super.dispose();
  }

  void _loadTaxes() async {
    setState(() {
      isLoading = true;
    });
    try {
      taxes = await _apiHandler.getTaxes();
    } catch (e) {
      print('Error loading taxes: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateTaxes() async {
    bool success = await _apiHandler.updateTaxes(inHouseTax, takeOutTax);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Taxes updated successfully' : 'Failed to update taxes',
        ),
      ),
    );
  }

  void _changeLanguage(Language? language) async {
    if (language != null) {
      setState(() {
        selectedLanguage = language.languageCode;
      });
      Locale _locale = await setLocale(language.languageCode);
      Main.setLocale(context, _locale);
    }
  }

  final List<Language> languages = [
    Language("English", "en", Icons.language),
    Language("Spanish", "es", Icons.translate),
    Language("German", "de", Icons.g_translate),
  ];

  Future<void> _loadPromoCodes() async {
    try {
      List<Promocodes> promoCodes = await _apiHandler.fetchPromoCodes();
      setState(() {
        _promoCodes = promoCodes;
      });
    } catch (e) {
      // Handle error here
      print(e);
    }
  }

  Future<void> _showAddPromoCodeDialog() async {
    final TextEditingController _promoCodeController = TextEditingController();
    final TextEditingController _discountPercentageController =
        TextEditingController(); // New controller for percentage
    final orgId = await SessionManager.getOrganizationId();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Add Promo Code',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF36454F),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _promoCodeController,
                decoration: InputDecoration(
                  hintText: 'Enter promo code',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB87333)),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _discountPercentageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter discount percentage',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB87333)),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF36454F)),
              ),
            ),
            TextButton(
              onPressed: () async {
                String promoCode = _promoCodeController.text;
                String discountText = _discountPercentageController.text;
                double discountPercentage = 0.0;

                if (promoCode.isNotEmpty && discountText.isNotEmpty) {
                  try {
                    discountPercentage = double.parse(discountText);
                    if (discountPercentage < 0 || discountPercentage > 100) {
                      throw Exception('Invalid percentage value');
                    }

                    Promocodes newPromoCode = Promocodes(
                      PromoCode: promoCode,
                      OrganizationId: orgId!.toInt(),
                      Percentage: discountPercentage,
                      id: 0,
                    );

                    await _apiHandler.postPromoCode(newPromoCode);
                    _loadPromoCodes();
                    Navigator.of(context).pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Invalid discount percentage'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in both fields')),
                  );
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Color(0xFFB87333),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.language),
        backgroundColor: Color(0xFF36454F),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.language,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: languages.length,
                      itemBuilder: (context, index) {
                        final language = languages[index];
                        return GestureDetector(
                          onTap: () => _changeLanguage(language),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: selectedLanguage == language.languageCode
                                  ? Colors.white38
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedLanguage == language.languageCode
                                    ? Color(0xFFB87333)
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  language.icon,
                                  color:
                                      selectedLanguage == language.languageCode
                                      ? Color(0xFF8B5C42)
                                      : Colors.grey,
                                  size: 26,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  language.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Spacer(),
                                AnimatedSwitcher(
                                  duration: Duration(milliseconds: 200),
                                  child:
                                      selectedLanguage == language.languageCode
                                      ? Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF8B5C42),
                                        )
                                      : SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 30),

                    // API Configuration Section
                    Text(
                      "API Configuration",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.settings_ethernet,
                          color: Color(0xFF8B5C42),
                        ),
                        title: Text('API Server Configuration'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Environment: ${ApiConfig.instance.environment}',
                            ),
                            Text(
                              'URL: ${ApiConfig.instance.baseUrl}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          showApiSettingsDialog(context);
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Promo Codes Settings",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    FloatingActionButton.extended(
                      onPressed: _showAddPromoCodeDialog,
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text(
                        "Add Promo",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Color(0xFFB87333),
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    SizedBox(height: 16),
                    ListView.builder(
                      itemCount: _promoCodes.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            leading: const Icon(
                              Icons.local_offer,
                              color: Color(0xFFB87333),
                            ),
                            title: Text(
                              _promoCodes[index].PromoCode,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: _promoCodes[index].PromoCode,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Promo code copied to clipboard',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        title: const Text(
                                          'Delete Promo Code',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF36454F),
                                          ),
                                        ),
                                        content: const Text(
                                          'Are you sure you want to delete this promo code?',
                                          style: TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Color(0xFF36454F),
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Color(0xFFB87333),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                      ),
                                    );

                                    if (confirm == true) {
                                      final deleted = await _apiHandler
                                          .deletePromoCode(
                                            _promoCodes[index].id!,
                                          );
                                      if (deleted) {
                                        setState(() {
                                          _promoCodes.removeAt(index);
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Promo code deleted'),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to delete promo code',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Taxes Settings",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          ' Tax Rate (%)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                inHouseTax = double.tryParse(value) ?? 0.0;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter tax rate',
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFB87333),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            style: TextStyle(
                              color: Color(0xFF36454F),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateTaxes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFB87333),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                      ),
                      child: Text(
                        'Update Taxes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

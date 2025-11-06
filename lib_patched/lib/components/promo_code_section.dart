import 'package:flutter/material.dart';
import 'package:visionpos/L10n/app_localizations.dart';
import 'package:visionpos/models/promocodes_model.dart';

class PromoCodeSection extends StatelessWidget {
  final TextEditingController promoCodeController;
  final LayerLink layerLink;
  final Function(String) onFindPromoCode;
  final Function() onValidatePromoCode;
  final Promocodes? selectedPromoCode;
  final Function() onRemovePromoCode;

  const PromoCodeSection({
    super.key,
    required this.promoCodeController,
    required this.layerLink,
    required this.onFindPromoCode,
    required this.onValidatePromoCode,
    this.selectedPromoCode,
    required this.onRemovePromoCode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.01,
      ),
      child: Row(
        children: [
          Expanded(
            child: CompositedTransformTarget(
              link: layerLink,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double textFieldWidth = constraints.maxWidth * 0.8;
                  double textSize = MediaQuery.of(context).size.width * 0.013;
                  double paddingHorizontal =
                      MediaQuery.of(context).size.width * 0.02;
                  double paddingVertical =
                      MediaQuery.of(context).size.height * 0.015;

                  return SizedBox(
                    width: textFieldWidth,
                    child: TextField(
                      controller: promoCodeController,
                      style: TextStyle(fontSize: textSize),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.discount,
                        labelStyle: TextStyle(fontSize: textSize),
                        border: const OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: paddingHorizontal,
                          vertical: paddingVertical,
                        ),
                      ),
                      onChanged: onFindPromoCode,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onValidatePromoCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB87333),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}

// lib/utils/product_name_translator.dart

/// Temporary translation helper for converting English product names to Arabic.
///
/// **IMPORTANT:** This is a temporary solution!
/// The recommended approach is to store Arabic names directly in the database.
///
/// Usage:
/// ```dart
/// import 'package:visionpos/utils/product_name_translator.dart';
///
/// final arabicName = ProductNameTranslator.toArabic(product.productName);
/// ```
class ProductNameTranslator {
  /// Map of English to Arabic product names.
  /// Add all your products here.
  static const Map<String, String> translations = {
    // Shawarma / Wraps
    'Chicken Shawarma': 'شاورما دجاج',
    'Beef Shawarma': 'شاورما لحم',
    'Mixed Shawarma': 'شاورما مشكل',
    'Shawarma Plate': 'صحن شاورما',

    // Falafel
    'Falafel': 'فلافل',
    'Falafel Sandwich': 'ساندويتش فلافل',
    'Falafel Plate': 'صحن فلافل',

    // Burgers
    'Chicken Burger': 'برجر دجاج',
    'Beef Burger': 'برجر لحم',
    'Cheese Burger': 'برجر بالجبنة',
    'Double Burger': 'برجر مزدوج',

    // Grilled Items
    'Grilled Chicken': 'دجاج مشوي',
    'Grilled Meat': 'لحم مشوي',
    'Mixed Grill': 'مشاوي مشكلة',
    'Kabab': 'كباب',
    'Tikka': 'تكة',
    'Kofta': 'كفتة',

    // Sides
    'French Fries': 'بطاطس مقلية',
    'Onion Rings': 'حلقات البصل',
    'Hummus': 'حمص',
    'Moutabal': 'متبل',
    'Baba Ganoush': 'بابا غنوج',
    'Vine Leaves': 'ورق عنب',
    'Pickles': 'مخللات',

    // Salads
    'Fattoush Salad': 'سلطة فتوش',
    'Tabouleh': 'تبولة',
    'Greek Salad': 'سلطة يونانية',
    'Caesar Salad': 'سلطة سيزر',
    'Garden Salad': 'سلطة خضراء',

    // Pizza
    'Margherita Pizza': 'بيتزا مارجريتا',
    'Pepperoni Pizza': 'بيتزا بيبروني',
    'Vegetarian Pizza': 'بيتزا نباتية',
    'Chicken Pizza': 'بيتزا دجاج',
    'Meat Lovers Pizza': 'بيتزا اللحوم',

    // Pasta
    'Spaghetti': 'سباغيتي',
    'Penne': 'بيني',
    'Fettuccine': 'فيتوتشيني',
    'Lasagna': 'لازانيا',

    // Sandwiches
    'Club Sandwich': 'ساندويتش كلوب',
    'Chicken Sandwich': 'ساندويتش دجاج',
    'Tuna Sandwich': 'ساندويتش تونة',
    'Cheese Sandwich': 'ساندويتش جبنة',

    // Breakfast
    'Omelette': 'عجة',
    'Scrambled Eggs': 'بيض مخفوق',
    'Fried Eggs': 'بيض مقلي',
    'Pancakes': 'بان كيك',
    'French Toast': 'توست فرنسي',

    // Soups
    'Lentil Soup': 'شوربة عدس',
    'Chicken Soup': 'شوربة دجاج',
    'Vegetable Soup': 'شوربة خضار',
    'Tomato Soup': 'شوربة طماطم',

    // Desserts
    'Baklava': 'بقلاوة',
    'Kunafa': 'كنافة',
    'Um Ali': 'أم علي',
    'Ice Cream': 'آيس كريم',
    'Chocolate Cake': 'كيك شوكولاتة',
    'Cheesecake': 'تشيز كيك',

    // Drinks - Cold
    'Water': 'ماء',
    'Sparkling Water': 'ماء غازي',
    'Orange Juice': 'عصير برتقال',
    'Apple Juice': 'عصير تفاح',
    'Mango Juice': 'عصير مانجو',
    'Lemon Mint': 'ليمون نعناع',
    'Lemonade': 'ليموناضة',
    'Cola': 'كولا',
    'Pepsi': 'بيبسي',
    'Sprite': 'سبرايت',
    'Fanta': 'فانتا',
    '7Up': 'سفن اب',

    // Drinks - Hot
    'Arabic Coffee': 'قهوة عربية',
    'Turkish Coffee': 'قهوة تركية',
    'Espresso': 'إسبريسو',
    'Cappuccino': 'كابتشينو',
    'Latte': 'لاتيه',
    'Americano': 'أمريكانو',
    'Mocha': 'موكا',
    'Hot Chocolate': 'شوكولاتة ساخنة',
    'Tea': 'شاي',
    'Green Tea': 'شاي أخضر',
    'Mint Tea': 'شاي نعناع',
    'Herbal Tea': 'شاي أعشاب',

    // Snacks
    'Chips': 'شيبس',
    'Popcorn': 'فشار',
    'Nachos': 'ناتشوز',
    'Chicken Wings': 'أجنحة دجاج',
    'Chicken Nuggets': 'ناجتس دجاج',
    'Mozzarella Sticks': 'أصابع موتزاريلا',

    // Lebanese/Arabic Dishes
    'Kibbeh': 'كبة',
    'Sambousek': 'سمبوسك',
    'Manakish': 'مناقيش',
    'Zaatar Manakish': 'مناقيش زعتر',
    'Cheese Manakish': 'مناقيش جبنة',
    'Labneh': 'لبنة',
    'Fatteh': 'فتة',
  };

  /// Convert English product name to Arabic.
  /// Returns the original name if no translation is found.
  static String toArabic(String englishName) {
    // Try exact match first
    if (translations.containsKey(englishName)) {
      return translations[englishName]!;
    }

    // Try case-insensitive match
    final lowerName = englishName.toLowerCase();
    for (final entry in translations.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }

    // Check if it's already in Arabic
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(englishName)) {
      return englishName; // Already Arabic
    }

    // No translation found - return original with warning
    print('⚠️ No Arabic translation for: "$englishName"');
    print('   Add it to ProductNameTranslator.translations map');
    return englishName;
  }

  /// Check if a product name has an Arabic translation.
  static bool hasTranslation(String englishName) {
    return translations.containsKey(englishName) ||
        RegExp(r'[\u0600-\u06FF]').hasMatch(englishName);
  }

  /// Get all English product names that have translations.
  static List<String> getAllEnglishNames() {
    return translations.keys.toList()..sort();
  }

  /// Get all Arabic product names.
  static List<String> getAllArabicNames() {
    return translations.values.toList()..sort();
  }

  /// Batch translate multiple product names.
  static Map<String, String> translateBatch(List<String> englishNames) {
    return {
      for (final name in englishNames) name: toArabic(name),
    };
  }
}

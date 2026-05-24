class PortionParser {
  /// Malzeme stringini miktar ve birim/isim olarak ayırır.
  /// Örn: "2 su bardağı süt" -> { amount: 2.0, text: "su bardağı süt" }
  static Map<String, dynamic> parseIngredient(String ingredient) {
    final regex = RegExp(r'^(\d+(?:[.,]\d+)?|\d+\/\d+)?\s*(.*)');
    final match = regex.firstMatch(ingredient.trim());
    
    if (match != null) {
      final String numStr = match.group(1) ?? '';
      final String rest = match.group(2) ?? ingredient;
      
      double amount = 0;
      if (numStr.isNotEmpty) {
        if (numStr.contains('/')) {
           final parts = numStr.split('/');
           if (parts.length == 2) {
             amount = (double.tryParse(parts[0]) ?? 0) / (double.tryParse(parts[1]) ?? 1);
           }
        } else {
           amount = double.tryParse(numStr.replaceAll(',', '.')) ?? 0;
        }
      }
      return {'amount': amount, 'text': rest};
    }
    return {'amount': 0.0, 'text': ingredient};
  }

  /// Mevcut porsiyon sayısından hedeflenen porsiyon sayısına malzemeyi çarpar.
  static String scaleIngredient(String ingredient, int baseServing, int targetServing) {
    if (baseServing <= 0) return ingredient;
    final parsed = parseIngredient(ingredient);
    final double baseAmount = parsed['amount'] as double;
    final String text = parsed['text'] as String;

    if (baseAmount <= 0) return ingredient; // Sayı bulunamadıysa metni direkt döndür.

    final double newAmount = (baseAmount / baseServing) * targetServing;
    
    final String formattedAmount = newAmount == newAmount.toInt() 
        ? newAmount.toInt().toString() 
        : newAmount.toStringAsFixed(1);
        
    return '$formattedAmount $text';
  }

  /// Groq tarafından üretilen Markdown formatındaki tarifi çözümler.
  /// ingredients, instructions, title vb. alanları döndürür.
  static Map<String, dynamic> parseMarkdownRecipe(String markdown) {
    final List<String> ingredients = [];
    final List<String> instructions = [];
    String? title;
    String? prepTime;
    String? calories;
    String? description;
    String? zeroWasteTip;

    final lines = markdown.split('\n');
    String currentSection = '';

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final lower = trimmed.toLowerCase();
      
      bool isHeader = false;
      String contentAfterHeader = '';
      
      if (lower.contains('tarif adı') || lower.contains('recipe name') || lower.contains('tarif adi')) {
        currentSection = 'title';
        isHeader = true;
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex != -1 && colonIndex < trimmed.length - 1) {
          contentAfterHeader = trimmed.substring(colonIndex + 1).trim();
        }
      } else if (lower.contains('özet bilgiler') || lower.contains('quick info') || lower.contains('ozet bilgiler')) {
        currentSection = 'info';
        isHeader = true;
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex != -1 && colonIndex < trimmed.length - 1) {
          contentAfterHeader = trimmed.substring(colonIndex + 1).trim();
        }
      } else if (lower.contains('malzemeler') || lower.contains('ingredients')) {
        currentSection = 'ingredients';
        isHeader = true;
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex != -1 && colonIndex < trimmed.length - 1) {
          contentAfterHeader = trimmed.substring(colonIndex + 1).trim();
        }
      } else if (lower.contains('hazırlanışı') || lower.contains('directions') || lower.contains('instructions') || lower.contains('hazirlanisi')) {
        currentSection = 'instructions';
        isHeader = true;
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex != -1 && colonIndex < trimmed.length - 1) {
          contentAfterHeader = trimmed.substring(colonIndex + 1).trim();
        }
      } else if (lower.contains('sıfır atık') || lower.contains('zero waste') || lower.contains('sifir atik')) {
        currentSection = 'tip';
        isHeader = true;
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex != -1 && colonIndex < trimmed.length - 1) {
          contentAfterHeader = trimmed.substring(colonIndex + 1).trim();
        }
      }

      if (isHeader) {
        if (contentAfterHeader.isNotEmpty) {
          final cleanContent = contentAfterHeader
              .replaceAll(RegExp(r'^#+\s*'), '')
              .replaceAll(RegExp(r'^\*+\s*'), '')
              .replaceAll(RegExp(r'\*+$'), '')
              .trim();
          if (cleanContent.isNotEmpty) {
            if (currentSection == 'title') {
              title = cleanContent;
            } else if (currentSection == 'tip') {
              zeroWasteTip = cleanContent;
            } else if (currentSection == 'ingredients') {
              ingredients.add(cleanContent);
            } else if (currentSection == 'instructions') {
              instructions.add(cleanContent);
            } else if (currentSection == 'info') {
              if (cleanContent.contains(':')) {
                final parts = cleanContent.split(':');
                final key = parts[0].toLowerCase();
                final val = parts.sublist(1).join(':').trim();
                if (key.contains('hazırlık') || key.contains('prep') || key.contains('süre')) {
                  prepTime = val;
                } else if (key.contains('kalori') || key.contains('calor') || key.contains('kcal')) {
                  calories = val;
                }
              }
            }
          }
        }
        continue;
      }

      if (currentSection == 'title') {
        final cleanTitle = trimmed
            .replaceAll(RegExp(r'^#+\s*'), '')
            .replaceAll(RegExp(r'^\*+\s*'), '')
            .replaceAll(RegExp(r'\*+$'), '')
            .trim();
        if (cleanTitle.isNotEmpty && title == null) {
          title = cleanTitle;
        }
      } else if (currentSection == 'info') {
        if (trimmed.contains(':')) {
          final parts = trimmed.split(':');
          final key = parts[0].toLowerCase();
          final val = parts.sublist(1).join(':').trim();
          if (key.contains('hazırlık') || key.contains('prep') || key.contains('süre')) {
            prepTime = val;
          } else if (key.contains('kalori') || key.contains('calor') || key.contains('kcal')) {
            calories = val;
          }
        }
      } else if (currentSection == 'ingredients') {
        final clean = trimmed
            .replaceFirst(RegExp(r'^[-*•]\s*'), '')
            .trim();
        if (clean.isNotEmpty) {
          ingredients.add(clean);
        }
      } else if (currentSection == 'instructions') {
        final clean = trimmed
            .replaceFirst(RegExp(r'^\d+\.\s*'), '')
            .replaceFirst(RegExp(r'^[-*•]\s*'), '')
            .trim();
        if (clean.isNotEmpty) {
          instructions.add(clean);
        }
      } else if (currentSection == 'tip') {
        final clean = trimmed.replaceFirst(RegExp(r'^[-*•]\s*'), '').trim();
        if (clean.isNotEmpty) {
          if (zeroWasteTip == null) {
            zeroWasteTip = clean;
          } else {
            zeroWasteTip += '\n$clean';
          }
        }
      }
    }

    if (zeroWasteTip != null && zeroWasteTip.isNotEmpty) {
      description = zeroWasteTip;
    }

    return {
      'title': title,
      if (ingredients.isNotEmpty) 'ingredients': ingredients,
      if (instructions.isNotEmpty) 'instructions': instructions,
      'prepTime': prepTime,
      'calories': calories,
      'description': description,
    };
  }
}

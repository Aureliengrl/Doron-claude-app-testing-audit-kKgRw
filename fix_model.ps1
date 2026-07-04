$path = "lib\pages\new_pages\onboarding_advanced\onboarding_advanced_model.dart"
$content = Get-Content -Path $path -Raw -Encoding UTF8

$oldCode = @"
    if (type == 'dual_text') {
      final fields = stepData['fields'] as List;
      // Vérifier que tous les champs requis sont remplis
      for (var fieldData in fields) {
        final field = fieldData['field'] as String;
        final required = fieldData['required'] as bool? ?? false;
        final value = answers[field];

        if (required && (value == null || value.toString().trim().isEmpty)) {
          return false;
        }
      }
      return true;
    }
"@

$newCode = @"
    if (type == 'dual_text') {
      final fields = stepData['fields'] as List;
      // Vérifier que tous les champs requis sont remplis
      for (var fieldData in fields) {
        final field = fieldData['field'] as String;
        final required = fieldData['required'] as bool? ?? false;
        final value = answers[field];

        if (required && (value == null || value.toString().trim().isEmpty)) {
          return false;
        }

        if (field == 'personIdentifier') {
           final handleVal = value?.toString().trim();
           if (handleVal != null && handleVal.isNotEmpty) {
              if (answers['isHandleValid'] != true) {
                 return false;
              }
           }
        }
      }
      return true;
    }
"@

$content = $content.Replace($oldCode, $newCode)

Set-Content -Path $path -Value $content -Encoding UTF8

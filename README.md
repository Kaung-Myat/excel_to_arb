# Excel to ARB Generator

An open-source tool for converting Excel files into ARB (Application Resource Bundle) files for app localization.

## Installation
1. Add the `excel` dependency to your `pubspec.yaml`:
    ```yaml
    dev_dependencies:
      excel: ^4.0.6
    ```

2. Prepare your Excel file:
   - Name must follow pattern: **app_*.xlsx** (e.g., `app_my.xlsx`)
   - Structure your spreadsheet with these columns:
   
     | Key     | Value       | Description (optional) |
     |---------|-------------|------------------------|
     | hello   | မင်္ဂလာပါ  | Greeting text         |
     | goodbye | နုတ်ဆက်ပါတယ် | Farewell text         |

   Example files available in: `resources/l10n/`

## Configuration
Modify these paths in `main.dart`:
```dart
void main() {
  const sourceDir = 'resources/l10n'; // Directory containing Excel files
  const targetDir = 'config/l10n';    // Output directory for ARB files
  
  // rest of code
}
```

## Usage
Finally Run the generator with:

> `dart run main.dart`




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
   
     | Key     | Value       | Description (optional) | Placeholder (name:type) |
     |---------|-------------|------------------------|------------------------|
     | hello   | မင်္ဂလာပါ  | Greeting text         | name:String , age: Int |
     | goodbye | နုတ်ဆက်ပါတယ် | Farewell text         | name:String , age: Int |

   Example files available in: `resources/l10n/`


## Usage
Finally Run the generator with:

> `dart convert_excel_to_arb.dart <source directory> <target directory>`




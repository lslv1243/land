# LAND

Tool for generating localization files to be used in Dart applications.

- Supports complex ICU messages
- Works on non Flutter apps

---

## Using instead of `flutter gen-l10n`


### 1. Update configuration
Instead of specifying the output localization file, only specify the folder
#### **l10n.yaml**
```yaml
# remove
output-localization-file: l10n.dart
# add
output-directory: lib/.gen/l10n/
```

### 2. Rename the configuration file
`l10n.yaml` -> `land.yaml`

### 3. Remove generate flag
#### **pubspec.yaml**
```yaml
# remove this inside flutter:
generate: true
```

### 4. Ignore the generated files
#### **.gitignore**
```
# Generated files
/lib/.gen/
```

### 5. Add land as dependency
#### **pubspec.yaml**
```yaml
# add to dev_dependencies:
land: any
```

### 6. Generate the files
```
flutter pub run land
```

### 7. Profit 🚀

---

## Configuration example:

### 1. Create configuration file
#### **land.yaml**
```yaml
arb-dir: l10n
template-arb-file: l10n_en.arb
output-directory: lib/.gen/l10n/
output-class: L10N
```

### 2. Create localization files
Create a folder named `l10n` in the root of the application (outside lib) and add your languages files there, for example:

#### **l10n/l10n_en.arb**
```json
{
    "helloWorld": "Hello World!",
    "@helloWorld": {}
}
```
#### **l10n/l10n_pt.arb**
```json
{
    "helloWorld": "Olá mundo!"
}
```
### 3. Ignore the generated files
Update your `.gitignore` to ignore the generated files.
#### **.gitignore**
```
# Generated files
/lib/.gen/
```

### 4. Run `land`
After running land all the files should be generated to be used. If it is a Flutter project it will contain the glue to use in a Flutter application. More details about Flutter localization at: https://docs.flutter.dev/development/accessibility-and-localization/internationalization.

---

NOTE: I highly recommend [downloading the tool](https://github.com/lslv1243/land.git), building it, making it available globally and use it this way instead of using `flutter pub run`.
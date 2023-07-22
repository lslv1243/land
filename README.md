# LAND

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/lslv1243)

Tool for generating localization files to be used in Dart applications.

- Supports complex ICU messages
- Works on non Flutter apps

---

## Global Installation

You can install `land` globally on your system which allows you to use it from anywhere.

```bash
dart pub global activate land
```

Ensure that the Dart SDK/bin is included in your PATH. If it's not, you'll need to add it. The exact method depends on your operating system. 

On Linux or macOS, you typically add it to your shell profile (e.g., `~/.bashrc`, `~/.bash_profile`, or `~/.zshrc`). 

On Windows, you add it via the System Properties.

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

### 5. Install land globally
Instead of adding `land` as a dev_dependency, we will install it globally
```bash
dart pub global activate land
```

### 6. Generate the files
With `land` installed globally, you can generate the localization files from any directory in your terminal
```bash
land
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
With `land` installed globally, you can generate the localization files from any directory in your terminal. More details about Flutter localization at: https://docs.flutter.dev/development/accessibility-and-localization/internationalization.
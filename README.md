# LAND

Tool for generating localization files to be used in Dart applications.

- Supports complex ICU messages
- Works on non Flutter apps (WIP)

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

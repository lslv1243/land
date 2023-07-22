# LAND

[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/lslv1243)

LAND is a powerful tool for generating localization files to be used in Dart applications, including Flutter apps. It supports complex ICU messages, works effectively even on non-Flutter applications, and offers multi-project support to simplify localization tasks in large codebases.

- [Requirements](#requirements)
- [Installation](#installation)
- [Using LAND](#using-land)
- [Multi-Project Support](#multi-project-support)
- [Configuration Example](#configuration-example)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Requirements

- Dart version 2.16.1 or later.

## Installation

Install LAND globally on your system to use it from anywhere:

```bash
dart pub global activate land
```

Ensure the Dart SDK/bin is included in your PATH. If not, you will need to add it. The method varies depending on your operating system.

On Linux or macOS, add it to your shell profile (e.g., `~/.bashrc`, `~/.bash_profile`, or `~/.zshrc`). On Windows, add it via the System Properties.

---

## Using LAND

LAND can be used as an alternative to `flutter gen-l10n`. Here are the steps to follow:

1. Update your localization configuration file to specify only the output folder, not the output localization file.
2. Rename your configuration file from `l10n.yaml` to `land.yaml`.
3. Remove the `generate: true` flag from your `pubspec.yaml` file.
4. Add `/lib/.gen/` to your `.gitignore` file to ignore the generated files.
5. Install LAND globally using the installation instructions above.
6. Run `land` to generate the localization files.

After these steps, you should have a robust localization system set up for your Dart application.

---

## Multi-Project Support

One of the standout features of LAND is its support for multi-project localization. If you run LAND in a directory that isn't a Dart or Flutter project, it automatically searches for Dart or Flutter projects one level down from the current directory. This means you can generate localization files for all projects within a directory by running a single `land` command. This functionality is especially beneficial in monorepo setups or when managing multiple related projects.

To use this feature, simply navigate to the parent directory of your projects and run:

```bash
land
```

Or specify the parent directory using the `--path` argument like:

```bash
land --path <parent-directory>
```

LAND takes care of the rest, generating localization files for each Dart or Flutter project in the directory.

---

## Configuration Example

Create a configuration file named `land.yaml` and place it in the root directory of your project:

```yaml
arb-dir: l10n
template-arb-file: l10n_en.arb
output-directory: lib/.gen/l10n/
output-class: L10N
```

---

## Usage

Create a folder named `l10n` in the root directory of your application (outside `lib`), and add your language files there. Here are a couple of examples:

#### l10n/l10n_en.arb

```json
{
    "helloWorld": "Hello World!",
    "@helloWorld": {}
}
```

#### l10n/l10n_pt.arb

```json
{
    "helloWorld": "Olá mundo!"
}
```

After running `land`, all the localization files will be generated and ready for use.

---

## Troubleshooting

If you encounter any issues while using LAND, please open an issue on our [GitHub repository](https://github.com/lslv1243/land).

---

## Contributing

We welcome contributions! If you'd like to contribute, feel free to open a pull request.

---

## License

This project is licensed under the [BSD-3-Clause License](LICENSE).

---

Thanks for using LAND!

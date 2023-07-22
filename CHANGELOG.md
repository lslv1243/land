## 0.0.4

In this version, we've updated the package configuration to allow for global installation. This means you can now install LAND once on your system and use it across multiple projects, instead of having to install it as a dependency for each individual project.

With this change, users can now use the `dart pub global activate land` command to install LAND globally. Once installed globally, users can run `land` from any location in their system without having to add it as a dev_dependency in the `pubspec.yaml` file for each project.

This improvement simplifies the usage of LAND, making it easier to use across multiple projects and reducing the steps needed to setup localization in a new project.

Remember to ensure your PATH includes the Dart SDK/bin to use the globally installed `land`. The way to add it to PATH depends on your operating system.

## 0.0.3

- Add non migration configuration example to README

## 0.0.2

- Only generating Flutter glue if project has flutter as dependency

## 0.0.1

- Initial version.

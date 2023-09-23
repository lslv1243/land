## 0.0.7

This version introduces support for a proxy class, designed for cases where you need to change the active locale without altering the underlying instance reference. The proxy class acts as a reference handler, enabling you to seamlessly switch between different locales within your application.

### Proxy Class for Locale Management
The proxy class is particularly useful when you want to change the active locale without affecting the underlying instance. It serves as a reference manager, allowing you to switch between different locales dynamically.

To configure the generation of the proxy class, update your `land.yaml` configuration file by adding a `proxy` object. This object can optionally contain a `loader` property set to either `true` or `false`.

Example `land.yaml` for the proxy class:
```yaml
proxy: {}
```

Example `land.yaml` for the proxy class with loader:
```yaml
proxy:
  loader: true
```

Here's what the generated proxy class looks like:
```dart
class ProxyL10N implements L10N {
  @override
  Locale get locale => proxy.locale;

  L10N proxy;

  ProxyL10N(this.proxy);

  @override
  String get notification_dontLoseDailyPrizesStreak_title =>
      proxy.notification_dontLoseDailyPrizesStreak_title;
}
```

And for the proxy class with loader code:
```dart
void load(Locale locale) {
  proxy = L10N.locales[locale]!;
}

factory ProxyL10N.loading(Locale locale) {
  final proxy = L10N.locales[locale]!;
  return ProxyL10N(proxy);
}
```

The introduction of the proxy class with loader code provides you with greater flexibility in managing localization within your Dart and Flutter projects. It allows you to switch locales seamlessly while maintaining the same instance reference, making it a true "proxy" for locale management.

## 0.0.6

- Update README

## 0.0.5

This version introduces several enhancements to improve user experience and expand the functionality of the LAND tool.

- Enhanced Error Messaging: The error messages have been improved to provide more clarity.

- Project Path Specification: Users can now specify the path of the Dart or Flutter project they're working on by using the new `--path` argument. This allows for more flexibility, particularly in situations where the LAND tool is not being run in the project's root directory. The command would be like: `land --path <directory>`

- Multi-Project Support: If the LAND tool is run in a directory that isn't a Dart or Flutter project, it will now search for Dart or Flutter projects one level down from the current directory. This enhancement allows for bulk localization file generation across multiple projects by running a single command in a parent directory. This can be particularly useful in monorepo setups or when managing multiple related projects.

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

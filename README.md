# Qt Static CMake

## Minimum working example

You can find a minimum working example here : https://github.com/OlivierLDff/QQuickStaticHelloWorld

## Introduction

This project aim is to provide 2 CMake macro that replicate QMake functionality to generate `Q_IMPORT_PLUGIN` macros when linking with a static version of Qt.

When linking with static Qt, dynamic plugin are not load on demand and must be explicitly *loaded* during link time. The first macro `qt_generate_plugin_import` create a file named  `YourApp_plugin_import.cpp` that will look like this:

```c++
// File Generated via CMake script during build time.
// The purpose of this file is to force the static load of qml plugin during static build
// Please rerun CMake to update this file.
// File will be overwrite at each CMake run.

#include <QtPlugin>

// Qt5Gui
Q_IMPORT_PLUGIN(QGifPlugin);
Q_IMPORT_PLUGIN(QICNSPlugin);
Q_IMPORT_PLUGIN(QICOPlugin);
Q_IMPORT_PLUGIN(QIOSIntegrationPlugin);
Q_IMPORT_PLUGIN(QJpegPlugin);
Q_IMPORT_PLUGIN(QMacHeifPlugin);
Q_IMPORT_PLUGIN(QMacJp2Plugin);
Q_IMPORT_PLUGIN(QMinimalIntegrationPlugin);
Q_IMPORT_PLUGIN(QOffscreenIntegrationPlugin);
Q_IMPORT_PLUGIN(QTgaPlugin);
Q_IMPORT_PLUGIN(QTiffPlugin);
Q_IMPORT_PLUGIN(QTuioTouchPlugin);
Q_IMPORT_PLUGIN(QWbmpPlugin);
Q_IMPORT_PLUGIN(QWebpPlugin);

// Qt5Network
Q_IMPORT_PLUGIN(QGenericEnginePlugin);

// Qt5Qml
Q_IMPORT_PLUGIN(QDebugMessageServiceFactory);
Q_IMPORT_PLUGIN(QLocalClientConnectionFactory);
Q_IMPORT_PLUGIN(QQmlDebugServerFactory);
Q_IMPORT_PLUGIN(QQmlDebuggerServiceFactory);
Q_IMPORT_PLUGIN(QQmlInspectorServiceFactory);
Q_IMPORT_PLUGIN(QQmlNativeDebugConnectorFactory);
Q_IMPORT_PLUGIN(QQmlNativeDebugServiceFactory);
Q_IMPORT_PLUGIN(QQmlPreviewServiceFactory);
Q_IMPORT_PLUGIN(QQmlProfilerServiceFactory);
Q_IMPORT_PLUGIN(QQuickProfilerAdapterFactory);
Q_IMPORT_PLUGIN(QTcpServerConnectionFactory);

// Qt5Svg
Q_IMPORT_PLUGIN(QSvgIconPlugin);
Q_IMPORT_PLUGIN(QSvgPlugin);
```

Generated  `Q_IMPORT_PLUGIN` are dependent on which Qt module you are using. You should register module with `qt5_use_modules` macro.

The second macro `qt_generate_qml_plugin_import` will work the same way but will import qml plugins and generate `YourApp_qml_plugin_import.cpp` that will look like this:

```c++
// File Generated via CMake script during build time.
// The purpose of this file is to force the static load of qml plugin during static build
// Please rerun CMake to update this file.
// File will be overwrite at each CMake run.

#include <QtPlugin>

Q_IMPORT_PLUGIN(QtQuick2Plugin);
Q_IMPORT_PLUGIN(QtQuickLayoutsPlugin);
Q_IMPORT_PLUGIN(QtQuickControls2Plugin);
Q_IMPORT_PLUGIN(QtQuickTemplates2Plugin);
Q_IMPORT_PLUGIN(QtQuick2WindowPlugin);
Q_IMPORT_PLUGIN(QtQuickControls2MaterialStylePlugin);
Q_IMPORT_PLUGIN(QmlSettingsPlugin);
Q_IMPORT_PLUGIN(QtQuickControls2FusionStylePlugin);
Q_IMPORT_PLUGIN(QtQuickControls2UniversalStylePlugin);
Q_IMPORT_PLUGIN(QtQuickControls2ImagineStylePlugin);
Q_IMPORT_PLUGIN(QtGraphicalEffectsPlugin);
Q_IMPORT_PLUGIN(QtGraphicalEffectsPrivatePlugin);
```

This macro use the qt tool `qmlimportscanner` present in QtSdk/bin folder. It will scan your qml folder and import only required plugins.

## How to use

```cmake
qt_generate_plugin_import(YourApp
  OUTPUT "YourApp_plugin_import.cpp"
  OUTPUT_DIR "/path/to/output"
  VERBOSE)
  
qt_generate_qml_plugin_import(YourApp
  QML_DIR "/path/to/qtsdk"
  QML_SRC "/path/to/yourApp/qml"
  OUTPUT "YourApp_qml_plugin_import.cpp"
  OUTPUT_DIR "/path/to/output"
  VERBOSE)
```

The only required argument is **QML_SRC** that is your qml source folder.

* **QML_DIR** will be default to the sdk qml folder.
* **OUTPUT** will be  `${TARGET}_qml_plugin_import.cpp` or `${TARGET}_plugin_import.cpp`.
* **OUTPUT_DIR** will be default to **PROJECT_BINARY_DIR**.
* **VERBOSE** allow to output debug information.

`qt_generate_qml_plugin_import` also add `-u _qt_registerPlatformPlugin` linker flag to your **TARGET** in order to force load of the platform plugin at build time.

## Related links

* [Qt Static Linking doc](https://doc.qt.io/QtForDeviceCreation/qtee-static-linking.html)

## Contact

* Olivier Le Doeuff: olivier.ldff@gmail.com

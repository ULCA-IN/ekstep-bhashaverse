# Bhashaverse

A Speech to Speech Application build using Flutter which leverages the Indian Languages AI/ML models offered by Government of India under the ambitious project called [Bhashini](www.bhashini.gov.in).

## Getting Started
Follow the below steps to successfully run this Flutter application:

- Create a new Flutter project using command

```shell-script
 	flutter create --org com.xxxx <<folder_name>> --project-name <<project_name>>
```

- Download the `assets` and `lib` folder and paste them in the project root

## Edit `pubspec.yaml` file
Add following dependencies/properties in _pubspec.yaml_ file:

* Project Name:
```yaml
name: bhashaverse
```

* Dependencies:
```yaml
  cupertino_icons: ^1.0.2
  get: ^4.6.5
  dio: ^4.0.6
  permission_handler: ^10.2.0
  path_provider: ^2.0.12
  connectivity_plus: ^3.0.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  freezed: ^2.3.2
  freezed_annotation: ^2.2.0
  json_serializable: ^6.5.4
  flutter_svg: ^1.1.6
  google_fonts: ^3.0.1
  avatar_glow: ^2.0.2
  lottie: ^2.1.0
  share_plus: ^6.3.0
  audio_waveforms: ^1.0.0
  socket_io_client: ^2.0.1
  mic_stream: ^0.6.4
  record: ^4.4.4
  auto_size_text: ^3.0.0
```

* Dev Dependencies:
```yaml
  build_runner: ^2.3.3
  flutter_launcher_icons: ^0.11.0
```

* App icon:
```yaml
flutter_icons:
  android: "launcher_icon"
  ios: true
  remove_alpha_ios: true
  image_path: "assets/images/img_app_logo_full.png"
  web:
    generate: true
    image_path: "assets/images/img_app_logo_full.png"
  windows:
    generate: true
    image_path: "assets/images/img_app_logo_full.png"
    icon_size: 48 # min:48, max:256, default: 48
  macos:
    generate: true
    image_path: "assets/images/img_app_logo_full.png"
```

* Assets path:
```yaml
  assets:
    - assets/google_fonts/
    - assets/images/
    - assets/images/app_language_img/
    - assets/images/common_icon/
    - assets/images/onboarding_image/
    - assets/images/bottom_bar_icons/
    - assets/animation/lottie_animation/
```

- Enter the terminal and execute following commands:

    - flutter clean
    - flutter pub get
    - flutter pub run build_runner build --delete-conflicting-outputs
    - flutter pub run flutter_launcher_icons:main
    
------------

### Steps for Android

- Set minimum SDK version to 21 or higher in `android/app/build.gradle`

- Set target SDK version and compile SDK version to 33 or higher in `android/app/build.gradle`

- Open the `android/app/src/main/AndroidManifest.xml` file and add following permissions:

```xml
     <uses-permission android:name="android.permission.INTERNET"/>
     <uses-permission android:name="android.permission.RECORD_AUDIO" />
     <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
     <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
     <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### Steps for iOS

- Open `Info.plist` and add following permission:

```xml
     <key>NSMicrophoneUsageDescription</key>
     <string>App need Microphone permission to enable Speech translation</string>
```
- Open `ios/Podfile`  and update post_install code as shown below this:


```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_ios_build_settings(target)
          target.build_configurations.each do |config|
             config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [          '$(inherited)',
            ## dart: PermissionGroup.microphone
            'PERMISSION_MICROPHONE=1',
          ]
          end
     end
   end
```

- Enter the following commands in terminal:

    - cd ios
    - pod update

------------

- Run the project on emulator/device/web etc.

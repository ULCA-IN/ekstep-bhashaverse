# Bhashaverse

A Speech to Speech Application build using Flutter which leverages the Indian Languages AI/ML models offered by Government of Indian under the ambitious project called [Bhashini](www.bhashini.gov.in).

## Getting Started
Follow the below steps to successfully run this Flutter application:

- Create a new Flutter project using command

```shell-script
 	flutter create --org com.xxxx <<folder_name>> --project-name <<project_name>>
```

- Download the `assets` and `lib` folder and paste them in the project root

- Copy dependency, dev_dependencies, flutter_icons, and assets path from `pubspec.yaml` file and replace with your own

- Enter the terminal and execute following commands:

    - flutter clean
    - flutter pub get
    - flutter pub run build_runner build --delete-conflicting-outputs
    - flutter pub run flutter_launcher_icons:main

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

- Open Xcode and add -lc++ flag in `Runner > Build Settings > Other Linker Flags`

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

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.solodevlab.solara"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.solodevlab.solara"
        // 🔴 minSdk = 31 (Android 12) に固定。
        // 理由: Solara のテスト範囲は A101FC エミュレーター (Android 12) 以上のみ。
        // それより古い端末ではテスト未実施のため、Play Store 配信を制限。
        // 市場カバー率は ~75% (2026-05 時点)、占い系アプリの主流ユーザー層を網羅。
        // 動作環境は scta-android.html / how_solara_works.md と整合。
        minSdk = 31
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // 🔴 R8 minify + リソース shrink を release build で有効化
            // (launch_checklist Phase 2 残)。各 Flutter プラグインの
            // consumer-rules.pro が AAR から自動取り込みされるが、
            // proguard-rules.pro で防御的に keep を追加。
            // optimize 版は Log.w 呼び出しまで no-op 化する場合があるため
            // proguard-android.txt (非 optimize) を使用。
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

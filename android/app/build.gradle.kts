import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de release do Android — fora do git, em keys/ (ver README).
// O arquivo guarda o caminho do keystore e as senhas; o keystore em si fica
// ao lado. Sem o arquivo, o build cai na chave de debug, para o
// `flutter run --release` continuar funcionando em quem não tem a chave.
val releaseProps = Properties().apply {
    val arquivo = rootProject.file("../keys/android-release.properties")
    if (arquivo.exists()) arquivo.inputStream().use { load(it) }
}

android {
    namespace = "br.com.kanada.zywny.musicas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // O identificador definitivo do app (D03): é o que o Firebase Console
        // e o OAuth do Google registram para o Android.
        applicationId = "br.com.kanada.zywny.musicas"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 26) // AAudio (libzywny_audio)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Só as ABIs para as quais o projeto compila as nativas (libverovio.so
        // e libzywny_audio.so, em jniLibs/ — `just native-android` e
        // `just native-audio-android`). Sem este filtro, um celular de 32
        // bits instalaria um app que quebra ao abrir a partitura. As .so do
        // motor do Flutter saem do `flutter build --target-platform` (a
        // receita `build-appbundle`), que é quem tira o armeabi-v7a.
        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    packaging {
        jniLibs {
            // Sem isto, plugins que trazem .so de 32 bits (o jni e o
            // datastore) deixam uma pasta armeabi-v7a no pacote — e o
            // Play geraria um APK de 32 bits sem a engine e sem o código
            // Dart: o app instalaria e não abriria. As ABIs de verdade
            // (arm64-v8a e x86_64) vêm do `--target-platform` da receita
            // `build-appbundle`.
            excludes += "**/armeabi-v7a/**"
        }
    }

    signingConfigs {
        // A "upload key" do Google Play: assina o AAB que sobe para a loja.
        // O Google reassina com a "app signing key" dele (Assinatura de apps
        // do Google Play). Trocar a upload key depois exige pedido ao Google.
        if (releaseProps.isNotEmpty()) {
            create("upload") {
                storeFile = rootProject.file("../keys/${releaseProps.getProperty("storeFile")}")
                storePassword = releaseProps.getProperty("storePassword")
                keyAlias = releaseProps.getProperty("keyAlias")
                keyPassword = releaseProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Sem a chave de release em keys/, cai na de debug (comportamento
            // antigo, para o build local não quebrar).
            signingConfig = signingConfigs.findByName("upload")
                ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

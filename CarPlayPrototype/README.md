# Araç Bilgi Paneli — iOS Live Activity prototipi

Bu dosyalar SwiftUI + ActivityKit + WidgetKit için **başlangıç kaynak kodudur**, derlenmiş bir uygulama değildir.

## Kapsam
- iPhone uygulamasında "3°C ile test başlat" düğmesi.
- Live Activity içinde örnek 3°C ve "Donma riski" gösterimi.
- Kullanıcı düğmesiyle Live Activity'yi durdurma.
- Gerçek hava, GPS, yol adı ve hız limiti bağlantısı **yoktur**.
- CarPlay Dashboard görünürlüğü **henüz gerçek cihazda doğrulanmadı**.

## Xcode kurulumu
1. Xcode'da iOS App (SwiftUI) projesi oluştur, deployment target'ı ActivityKit için uygun iOS sürümüne ayarla.
2. `App/DriveApp.swift`, `App/DriveActivityManager.swift` ve `Shared/DriveActivityAttributes.swift` dosyalarını uygulama target'ına ekle.
3. Widget Extension (Include Live Activity) oluştur. `Widget/DriveLiveActivityWidget.swift` ile `Shared/DriveActivityAttributes.swift` dosyalarını widget target'ına ekle. Xcode'un oluşturduğu alternatif `@main` widget bundle dosyasını kaldır veya birleştir.
4. App target Info.plist içine `NSSupportsLiveActivities = YES` (Boolean) ekle.
5. Signing & Capabilities altında geçerli Apple Developer takımıyla imzala.
6. Önce iPhone'da Live Activity'yi test et; sonra CarPlay Dashboard'da uygunluk ve görünürlüğü doğrula.

## Önemli
GitHub Codespaces Linux üzerinde Xcode derlemesi yapamaz. Bu klasör tek başına TestFlight'a gönderilemez. macOS/Xcode tabanlı build, imzalama ve App Store Connect yapılandırması gerekir. Ücretli servis başlatılmadı.

Apple'ın Live Activity yaşam döngüsü ve güncelleme sınırları nedeniyle hız limiti ve anlık yol bilgisinin burada sürekli gösterileceği varsayılmamalı.

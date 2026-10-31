# CarPlay araç bilgi paneli — proje hedefi

## Kullanıcı hedefi
iPhone ve iPad üzerinden, yerel bilgisayar kullanmadan geliştirme. Araçta Yandex Navigasyon haritası görünür kalırken CarPlay Dashboard üzerinde küçük bir bilgi alanı.

## İlk prototip
- Konuma göre dış sıcaklık
- 4 °C altında donma riski uyarısı (yolun buzlu olduğunu kesin söylemez)
- Uygunsa saat, tarih ve konum
- Harita ve navigasyon ön planda kalmalı
- İlk deney için ActivityKit/Live Activities ve CarPlay Dashboard gösterimi uygunluk testi

## Sonraki aşama
- Yol adı ve hız limiti. Yandex NaviKit veri erişimi, lisans, Türkiye kapsamı ve başka navigasyon uygulamasıyla birlikte çalışma doğrulanmadan özellik vaat edilmeyecek.
- Telefon, Mesajlar, Apple Music, YouTube Music ve Maps kısayollarında CarPlay'in mevcut erişimini kullan; özel kısayol eklemeyi varsayma.

## Teknik kısıtlar
- GitHub Codespaces (Linux) tek başına iOS uygulamasını derleyip CarPlay'e yükleyemez; macOS/Xcode tabanlı build ve Apple imzalama süreci gerekir.
- Live Activity'nin CarPlay Dashboard'da görünürlüğü, düzeni, güncelleme sıklığı ve konum erişimi Apple dokümantasyonu ve gerçek cihazda doğrulanmalı.
- Yandex navigasyon ekranının yanına serbestçe overlay koyulabileceği varsayılmamalı.
- Mevcut Python dashboard yalnızca geliştirme ortamı smoke testidir, nihai uygulama değildir.

## Sonraki somut adım
1. Apple'ın güncel Live Activities/CarPlay dokümanlarına göre uygulanabilirliği teyit et.
2. iOS Swift/ActivityKit minimal proje iskeleti oluştur.
3. Mac gerektirmeyen uzaktan derleme/imzalama yolu belirle; kullanıcı onayı olmadan ücretli hizmet başlatma.
4. CarPlay gerçek ekranında prototipi test et.

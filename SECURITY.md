# Güvenlik Politikası

Bu depo yönetici yetkisi, parola işlemleri ve cihaz kaydı gibi hassas akışlar içerir. Güvenlik etkisi olan bir bulgu tespit ederseniz bunu herkese açık issue olarak paylaşmayın.

## Desteklenen Sürümler

| Sürüm | Durum |
| --- | --- |
| `main` veya varsayılan dal | Aktif geliştirme |
| Etiketsiz yerel kopyalar | En iyi gayret desteği |

## Güvenlik Açığı Bildirimi

1. Parola, kurum kodu, cihaz seri bilgisi veya yerel ağ ayrıntısı içeren ekran görüntülerini olduğu gibi paylaşmayın.
2. GitHub deposunda "Report a vulnerability" özelliği açıksa onu kullanın.
3. Bu özellik kapalıysa repo sahibiyle GitHub üzerinden doğrudan iletişime geçin ve ilk mesajda yalnızca kısa bir özet, etki ve tekrar adımlarını paylaşın.
4. Gerekli logları paylaşmadan önce hassas verileri maskeleyin.

## Bildirime Eklenmesi Faydalı Bilgiler

- Etkilenen betik veya `.desktop` başlatıcı
- Kullanılan komut veya tıklanan akış
- Pardus/ETAP23 sürümü
- Beklenen davranış ve gerçekleşen davranış
- Güvenlik etkisi: yetki yükseltme, parola sızması, kalıcı yanlış ayar, veri silinmesi gibi

## Kapsam Örnekleri

Aşağıdaki konular güvenlik bildirimi olarak değerlendirilmelidir:

- Kayıtlı veya varsayılan yönetici parolasının beklenmedik şekilde ifşa olması
- `sudo` akışlarında yetki atlama veya yanlış kullanıcıya işlem uygulanması
- Hassas dosya izinlerinin yanlış ayarlanması
- Kurulum sırasında istenmeyen paket/komut çalışması

# Katkı Rehberi

Bu depo ETAP23/Pardus cihazları için kurulum ve bakım betikleri içerir. Katkı verirken ana hedef, gerçek kurulum kullanımında hata riskini düşük tutmak ve değişikliklerin izlenebilir olmasını sağlamaktır.

## Temel İlkeler

- Küçük ve odaklı değişiklikler gönderin.
- Yeni parametre, varsayılan değer veya iş akışı ekliyorsanız ilgili dokümanı da aynı PR içinde güncelleyin.
- Var olan terminal çıktılarını ve Türkçe kullanıcı mesajlarını gereksiz yere değiştirmeyin.
- Gizli bilgi, parola, kurum verisi veya cihaz kimliği içeren örnekleri repoya eklemeyin.

## Geliştirme Beklentileri

- Shell betiklerinde Bash kullanımı korunmalıdır.
- Mümkün olduğunca ASCII karakter kullanın; dosya zaten Unicode kullanıyorsa mevcut stili bozmayın.
- Yeni komutlar eklerken hata davranışını düşünün: `set -euo pipefail` ve mevcut `fail`/`log` desenleri ile uyumlu kalın.
- Grafik akışta (`zenity`) ve terminal akışta aynı davranışın korunmasına dikkat edin.

## Yerel Kontrol Listesi

PR açmadan önce en az şu kontrolleri çalıştırın:

```bash
bash -n ./setup_etap23.sh
bash -n ./setup_etap23_launcher.sh
bash -n ./ahenk_kaldir.sh
```

`shellcheck` kuruluysa şu kontrolü de ekleyin:

```bash
shellcheck -x ./setup_etap23.sh ./setup_etap23_launcher.sh ./ahenk_kaldir.sh
```

Manuel olarak doğrulanması beklenen başlıklar:

- Ana kurulum akışında etkileşimli seçimler
- `--non-interactive` modu
- Dokunmatik sürücü bakım kipleri
- ETA Kayıt onarım akışı
- `.desktop` başlatıcılarının aynı klasörde doğru scripti bulması

## Pull Request İçeriği

PR açarken şu bilgileri ekleyin:

- Değişikliğin amacı
- Etkilenen script veya başlatıcı
- Test ettiğiniz komutlar
- Varsa geri dönüş/rollback notu
- Varsa ekran görüntüsü veya terminal çıktı özeti

Büyük davranış değişikliklerinde önce issue açmak daha uygundur.

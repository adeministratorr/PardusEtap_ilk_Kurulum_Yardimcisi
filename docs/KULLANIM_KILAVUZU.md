# Kullanım Kılavuzu

Bu kılavuz, depodaki ETAP23/Pardus kurulum ve bakım araçlarını hem son kullanıcı hem de teknik sorumlu gözüyle uçtan uca anlatır.

Bu araçlar, Selçuklu Mesleki ve Teknik Anadolu Lisesi ([seltem.meb.k12.tr](https://seltem.meb.k12.tr)) GençTek Özgür Yazılım Ekibi tarafından, danışman öğretmenleri [Adem YÜCE](https://ademyuce.tr) rehberliğinde, her kurulumda ayarları tek tek tekrar yapmamak ve yapılması gereken adımları atlamamak için hazırlandı.

## 1. Amaç

Bu repo şu senaryoları hızlandırmak için hazırlandı:

- ETAP23/Pardus cihazlarda ilk kurulumun tekrar edilebilir şekilde yapılması
- Dokunmatik sürücü kurulum, güncelleme, kontrol ve geri yükleme işlemleri
- ETA Kayıt ve Ahenk tarafında bozulan kayıt akışlarının temizlenmesi
- Wine/winetricks tabanlı bileşenlerin standart bir sırayla hazırlanması
- Öğretmenler ya da Yeğitek Okul Sorumluları için terminal ve grafik arayüzlü iki farklı çalışma yöntemi sunulması

## 2. Repo İçeriği

| Dosya | Görev |
| --- | --- |
| `setup_etap23.sh` | Ana kurulum ve bakım betiği |
| `setup_etap23_launcher.sh` | Grafik/terminal başlatıcı ve parola yönetimi |
| `ahenk_kaldir.sh` | ETA Kayıt/Ahenk temizliği için sarmalayıcı |
| `wine_araci.sh` | Bağımsız Wine kurulum ve bakım sarmalayıcısı |
| `ETAP23 Ilk Kurulum.desktop` | Ana kurulum başlatıcısı |
| `ETAP Wine Araci.desktop` | Wine aracı başlatıcısı |
| `ETA Dokunmatik Surucu Araci.desktop` | Dokunmatik sürücü bakım başlatıcısı |
| `ETA Kayit Duzelt Sifirla.desktop` | ETA Kayıt onarım başlatıcısı |
| `e-ag-client_2.9.3_amd64.deb` | Yerelden kurulan e-ag istemci paketi |

## 3. Gereksinimler

Aşağıdaki koşullar sağlanmış olmalıdır:

- Pardus/ETAP23 tabanlı bir sistem
- `sudo` veya doğrudan root yetkisi
- Paket kurulumu için internet erişimi
- Grafik arayüz istiyorsanız `zenity`
- `e-ag-client_2.9.3_amd64.deb` dosyası ile scriptlerin aynı klasörde bulunması

## 4. Önemli Uyarı ve Güvenlik Notları

- Betikler sistem ayarı değiştirir, paket kurar, kullanıcı silebilir ve parola değiştirebilir.
- `setup_etap23_launcher.sh`, girilen son sudo parolasını ve GUI'de açıkça yazılan son `etapadmin` parolasını `~/.config/etap23-ilk-kurulum/launcher.conf` dosyasında hatırlayabilir.
- Bu dosya yerel sistemde hassas veri barındırır; paylaşmadan önce temizleyin.
- ETA Kayıt otomasyonu uygulamanın erişilebilirlik katmanına bağlıdır. Alanlar görünmezse otomasyon durabilir ve işlemi elle tamamlamanız gerekebilir.

## 5. Hızlı Başlangıç

### 5.1 Terminalden standart kurulum

```bash
sudo ./setup_etap23.sh
```

Bu modda betik adım adım soru sorar. Enter tuşu ile varsayılan seçenek korunur.

### 5.2 Grafik arayüz ile kurulum

1. `ETAP23 Ilk Kurulum.desktop` dosyasını çift tıklayın.
2. `zenity` kuruluysa önce seçim listesi, sonra ayar formu açılır.
3. Gerekli seçimleri tamamlayın.
4. Başlatıcı yetki alıp `setup_etap23.sh` betiğini uygun argümanlarla çalıştırır.

### 5.3 Etkileşimsiz kurulum

```bash
sudo ./setup_etap23.sh --non-interactive --board-name etap-tahta-01
```

Bu mod otomasyon veya aynı ayarları tekrar uygulamak için uygundur.

## 6. Dosyaları Nasıl Konumlandırmalısınız?

En güvenli yapı, tüm dosyaları aynı klasörde tutmaktır:

```text
Pardus/
├── ETAP23 Ilk Kurulum.desktop
├── ETAP Wine Araci.desktop
├── ETA Dokunmatik Surucu Araci.desktop
├── ETA Kayit Duzelt Sifirla.desktop
├── ahenk_kaldir.sh
├── e-ag-client_2.9.3_amd64.deb
├── setup_etap23.sh
├── setup_etap23_launcher.sh
└── wine_araci.sh
```

`.desktop` dosyaları, kendi bulundukları klasöre göre ilgili scripti arar. Dosyaları ayırırsanız başlatıcı scripti bulamayabilir.

## 7. Grafik Arayüz Akışlarının Anlamı

### 7.1 ETAP23 İlk Kurulum

Bu başlatıcı şu seçenekleri yönetir:

- Tahta adını değiştirme
- `ogrenci` kullanıcısını silme
- `ogretmen` kullanıcısını silme
- `e-ag-client` kurma
- `eta-qr-login` kurma
- `eta-touchdrv` kurma veya güncelleme
- Wine ve winetricks kurma
- İsteğe bağlı `dxvk` ve `vkd3d` kurulumu
- Ekran koruyucu/DPMS kapatma
- Boşta kapanma ayarı
- Saatli kapanma ayarı
- `etapadmin` parolasını değiştirme
- Kurulum sonunda ETA Kayıt uygulamasını açma

### 7.2 ETAP Wine Aracı

Bu başlatıcı şu işlemleri yönetir:

- Wine ve winetricks kurma/güncelleme
- İsteğe bağlı Vulkan bileşenleri ile kurulum yapma
- Wine durumunu kontrol etme
- Wine sürümlerini gösterme
- `winecfg` açma
- Wine prefix klasörünü yeniden oluşturma
- Wine paketlerini kaldırma
- Gerekirse prefix klasörleriyle birlikte temizleme

### 7.3 ETA Dokunmatik Sürücü Aracı

Grafik araçta dört işlem vardır:

- Yeni dokunmatik sürücüyü yükle veya güncelle
- Tüm sistemi değil yalnızca dokunmatik sürücüsünü güncelle
- Dokunmatik sürücüsünü kontrol et
- Eski dokunmatik sürücüsünü geri yükle

### 7.4 ETA Kayıt düzelt/sıfırla

Bu akış `ahenk_kaldir.sh --gui` üzerinden şu işlemleri yönetir:

- `eta-register` paketini kurma veya güncelleme
- `ahenk` paketini temizleme
- Varsa `/etc/ahenk/ahenk.db` dosyasını temizleme
- Gerekirse `ahenk` paketini tekrar kurma

## 8. Terminalden Kullanım

### 8.1 En sık kullanılan komutlar

```bash
sudo ./setup_etap23.sh
sudo ./setup_etap23.sh --non-interactive --board-name etap-tahta-01
sudo ./setup_etap23.sh --touchdrv-upgrade
sudo ./setup_etap23.sh --touchdrv-only-upgrade
sudo ./setup_etap23.sh --touchdrv-check
sudo ./setup_etap23.sh --touchdrv-rollback
sudo ./setup_etap23.sh --wine-install
sudo ./setup_etap23.sh --wine-check
sudo ./setup_etap23.sh --winecfg
sudo ./setup_etap23.sh --eta-kayit-repair
sudo ./setup_etap23.sh --eta-kayit-repair-reinstall-ahenk
sudo ./wine_araci.sh --install
sudo ./wine_araci.sh --install-vulkan
sudo ./wine_araci.sh --check
sudo ./wine_araci.sh --version
sudo ./wine_araci.sh --winecfg
sudo ./wine_araci.sh --rebuild-prefix --wine-user etapadmin
sudo ./wine_araci.sh --remove-purge-prefixes
sudo ./ahenk_kaldir.sh
sudo ./ahenk_kaldir.sh --reinstall-ahenk
./ahenk_kaldir.sh --gui
```

### 8.2 Genel seçenekler

| Parametre | Açıklama |
| --- | --- |
| `--interactive` | Etkileşimli modu zorlar |
| `--non-interactive` | Soru sormadan ilerler |
| `--pause-on-error` | Hata durumunda pencereyi hemen kapatmaz |
| `--skip-apt-update` | `apt-get update` adımını atlar |
| `-h`, `--help` | Yardım ekranını gösterir |

### 8.3 Dokunmatik sürücü ve ETA Kayıt kipleri

| Parametre | Açıklama |
| --- | --- |
| `--touchdrv-upgrade` | Dokunmatik sürücüyü kurar/günceller, doğrular, gerekirse geri döner |
| `--touchdrv-only-upgrade` | Sadece `eta-touchdrv` için `--only-upgrade` yapar |
| `--touchdrv-check` | Kurulu sürümü ve servis durumunu raporlar |
| `--touchdrv-rollback` | `eta-touchdrv=0.3.5` sürümüne geri döner |
| `--eta-kayit-repair` | ETA Kayıt/Ahenk temizliği yapar |
| `--eta-kayit-repair-reinstall-ahenk` | Temizlikten sonra `ahenk` paketini tekrar kurar |

### 8.4 Ana kurulum seçenekleri

| Parametre | Açıklama |
| --- | --- |
| `--board-name AD` | Tahta adı/hostname |
| `--change-hostname` | Hostname değiştir |
| `--skip-hostname` | Hostname değiştirme |
| `--remove-ogrenci` / `--keep-ogrenci` | `ogrenci` kullanıcısını sil veya koru |
| `--remove-ogretmen` / `--keep-ogretmen` | `ogretmen` kullanıcısını sil veya koru |
| `--install-eag-client` / `--skip-eag-client` | Yerel `e-ag-client` paketini kur veya atla |
| `--install-eta-qr-login` / `--skip-eta-qr-login` | `eta-qr-login` adımını aç/kapat |
| `--install-eta-touchdrv` / `--skip-eta-touchdrv` | Dokunmatik sürücü adımını aç/kapat |
| `--install-wine` / `--skip-wine` | Wine ve winetricks adımını aç/kapat |
| `--disable-screensaver` / `--keep-screensaver` | Ekran koruyucu ve DPMS ayarını değiştir veya koru |
| `--change-etapadmin-password` / `--skip-etapadmin-password` | `etapadmin` parolasını değiştir veya atla |
| `--open-eta-kayit` / `--skip-eta-kayit` | Kurulum sonunda ETA Kayıt uygulamasını aç veya atla |

### 8.5 ETA Kayıt seçenekleri

| Parametre | Açıklama |
| --- | --- |
| `--eta-kayit-kurum-kodu KOD` | Kurum kodunu ayarlar |
| `--eta-kayit-sinif SINIF` | Sınıf bilgisini ayarlar |

Sınıf boş bırakılırsa tahta adı kullanılır.

### 8.6 Wine seçenekleri

Ana betikteki Wine kipleri:

| Parametre | Açıklama |
| --- | --- |
| `--wine-install` | Yalnızca Wine ve winetricks kur/güncelle |
| `--wine-check` | Wine komutları, başlatıcılar ve prefix durumunu kontrol et |
| `--wine-version` | Wine ve winetricks sürümlerini göster |
| `--winecfg` | Aktif grafik oturumundaki kullanıcı için `winecfg` aç |
| `--wine-remove` | Wine paketlerini ve ETAP başlatıcılarını kaldır |
| `--wine-remove-purge-prefixes` | Wine paketlerini kaldır ve prefix klasörlerini de sil |
| `--wine-rebuild-prefix` | Seçilen kullanıcı için Wine prefix klasörünü yeniden oluştur |

Bağımsız `wine_araci.sh` seçenekleri:

| Parametre | Açıklama |
| --- | --- |
| `--gui` | Grafik arayüzlü Wine aracını açar |
| `--install` | Wine ve winetricks kurar veya günceller |
| `--install-vulkan` | Kuruluma `dxvk` ve `vkd3d` ekler |
| `--check` | Wine durumunu kontrol eder |
| `--version` | Wine ve winetricks sürümlerini gösterir |
| `--winecfg` | `winecfg` açar |
| `--rebuild-prefix` | Wine prefix klasörünü yeniden oluşturur |
| `--remove` | Wine paketlerini kaldırır |
| `--remove-purge-prefixes` | Wine paketlerini ve prefix klasörlerini siler |
| `--wine-user KULLANICI` | Hedef kullanıcıyı seçer |
| `--wine-prefix-name AD` | Prefix klasör adını belirtir |
| `--wine-windows-version S` | Windows sürümünü belirtir |
| `--enable-vulkan` / `--disable-vulkan` | Vulkan bileşenlerini açar/kapatır |

Not: `dxvk` ve `vkd3d` Vulkan gerektirir. Eski Intel iGPU sistemlerde sorun çıkarsa kapalı kullanın.

### 8.7 Güç yönetimi seçenekleri

| Parametre | Açıklama |
| --- | --- |
| `--enable-idle-shutdown` / `--disable-idle-shutdown` | Boşta kapatma ayarını açar/kapatır |
| `--idle-shutdown-minutes DAKIKA` | Boşta kapanma süresi |
| `--enable-scheduled-shutdown` / `--disable-scheduled-shutdown` | Günlük kapanma ayarını açar/kapatır |
| `--scheduled-shutdown SAAT:DAKIKA` | Günlük kapanma saati |

## 9. Varsayılan Davranışlar

Betik ilk çalışmada genellikle şu adımları açık getirir:

- Hostname isteme ve değiştirme
- `ogrenci` kullanıcısını silme
- `ogretmen` kullanıcısını silme
- Yerel `e-ag-client_2.9.3_amd64.deb` kurma
- `eta-qr-login` kurma
- `eta-touchdrv` kurma veya güncelleme
- Wine, winetricks ve `mono-complete` önkoşullarını kurma
- Ekran koruyucu, ekran karartma ve DPMS kapatma
- 90 dakika boşta kalınca kapatma
- Her gün 17:20'de kapatma
- `etapadmin` parolasını değiştirme
- Varsa kurulum sonunda ETA Kayıt uygulamasını açma

## 10. Varsayılan Değerler

| Değişken | Varsayılan |
| --- | --- |
| `ETAPADMIN_PASSWORD` | Boş; boş kalırsa `etapadmin` parola adımı atlanır |
| `BOOTSTRAP_SUDO_PASSWORD` | `etap+pardus!` |
| `ETA_KAYIT_KURUM_KODU` | `216183` |
| `ETA_KAYIT_SINIF` | Boş ise tahta adı |
| `ETA_KAYIT_PACKAGE` | `eta-register` |
| `ETA_TOUCHDRV_TARGET_VERSION` | `0.4.0` |
| `ETA_TOUCHDRV_FALLBACK_VERSION` | `0.3.5` |
| `WINE_WINDOWS_VERSION` | `win10` |
| `WINE_PREFIX_NAME` | `.wine-etap` |
| `IDLE_SHUTDOWN_MINUTES` | `90` |
| `SCHEDULED_SHUTDOWN_TIME` | `17:20` |

Varsayılan winetricks listesi:

```text
renderer=gl allfonts corefonts liberation d3dx9 riched20 gdiplus msxml6 mingw vb6run vcrun6sp6 vcrun2012 vcrun2013 vcrun2022 mfc42
```

## 11. Ortam Değişkenleriyle Özelleştirme

Betik CLI parametrelerine ek olarak ortam değişkenlerini de destekler. Örnek:

```bash
sudo BOARD_NAME=etap-tahta-01 \
  ETAPADMIN_PASSWORD='guclu-bir-parola' \
  ETA_KAYIT_KURUM_KODU=216183 \
  ./setup_etap23.sh --non-interactive
```

`ETAPADMIN_PASSWORD` verilmezse veya boş bırakılırsa `etapadmin` parola değiştirme adımı atlanır. Boş GUI alanları önce yerelde kayıtlı `etapadmin` parolasını, sonra çalışma anında sağlanan `ETAPADMIN_PASSWORD_DEFAULT` değerini dener. Bu değerler ekranda gösterilmez; yalnızca GUI'de açıkça yazılan yeni parola yerelde saklanır.

Sık kullanılan ortam değişkenleri:

- `BOARD_NAME`
- `EAG_DEB`
- `ETAPADMIN_USER`
- `ETAPADMIN_PASSWORD`
- `ETA_KAYIT_KURUM_KODU`
- `ETA_KAYIT_SINIF`
- `ETA_TOUCHDRV_TARGET_VERSION`
- `ETA_TOUCHDRV_FALLBACK_VERSION`
- `WINE_PREFIX_NAME`
- `WINE_WINDOWS_VERSION`
- `WINETRICKS_PACKAGES`
- `ENABLE_WINE_VULKAN_TRANSLATORS`
- `IDLE_SHUTDOWN_MINUTES`
- `SCHEDULED_SHUTDOWN_TIME`

## 12. Sık Senaryolar

### 12.1 Yeni cihaz kurmak

```bash
sudo ./setup_etap23.sh
```

Etkileşimli sihirbaz, öğretmenler ve Yeğitek Okul Sorumluları için en güvenli seçenektir.

### 12.2 Aynı ayarları birden fazla cihazda tekrarlamak

```bash
sudo ./setup_etap23.sh \
  --non-interactive \
  --board-name etap-lab-01 \
  --eta-kayit-kurum-kodu 216183 \
  --eta-kayit-sinif 9-A
```

### 12.3 Sadece dokunmatik sürücüyü güncellemek

```bash
sudo ./setup_etap23.sh --touchdrv-only-upgrade
```

Bu komut tüm sistemi güncellemez; yalnızca mevcut `eta-touchdrv` kurulumunu güncellemeye çalışır.

### 12.4 Dokunmatik tamamen bozulduysa

Şu sırayla ilerleyin:

1. `sudo ./setup_etap23.sh --touchdrv-check`
2. `sudo ./setup_etap23.sh --touchdrv-upgrade`
3. Gerekirse `sudo ./setup_etap23.sh --touchdrv-rollback`

### 12.5 Yalnızca Wine bakımını çalıştırmak

```bash
sudo ./wine_araci.sh --check
sudo ./wine_araci.sh --install-vulkan
```

Bu akış, ana kurulumun geri kalan adımlarına girmeden yalnızca Wine tarafını yönetmek için uygundur.

### 12.6 ETA Kayıt açılmıyor veya kayıt tekrarlanıyorsa

```bash
sudo ./ahenk_kaldir.sh
```

Gerekirse:

```bash
sudo ./ahenk_kaldir.sh --reinstall-ahenk
```

## 13. Doğrulama Komutları

Dokunmatik sürücüyü elle kontrol etmek için:

```bash
apt-cache policy eta-touchdrv
systemctl status eta-touchdrv
```

Wine tarafını elle doğrulamak için:

```bash
wine --version
winetricks --version
```

Tüm sistemi güncellemek isterseniz:

```bash
sudo apt update
sudo apt upgrade
```

## 14. Sorun Giderme

### Sorun: `.desktop` dosyası tıklanıyor ama script bulunamıyor

Kontrol edin:

- `.desktop` ile ilgili `.sh` dosyası aynı klasörde mi?
- Scriptlerin çalıştırma izni var mı?

Gerekirse:

```bash
chmod +x ./*.sh ./*.desktop
```

### Sorun: Grafik arayüz yerine terminal açılıyor

Muhtemel nedenler:

- `zenity` kurulu değil
- `DISPLAY` ortamı yok
- Grafik oturum dışında çalışılıyor

Bu durumda başlatıcı terminal sihirbazına geri düşer.

### Sorun: `--touchdrv-only-upgrade` paket bulamıyor

Bu kip yalnızca zaten kurulu `eta-touchdrv` paketini günceller. Paket hiç kurulu değilse tam kurulum veya `--touchdrv-upgrade` kullanın.

### Sorun: ETA Kayıt otomasyonu tamamlanmıyor

Sebep genellikle uygulama arayüzündeki alanların erişilebilirlik katmanında farklı görünmesidir. Bu durumda:

- Uygulamayı betiğin açtığı noktadan elle tamamlayın
- Kurum kodu ve sınıf bilgisini tekrar kontrol edin
- Terminalde kalan otomasyon çıktılarını not alın

### Sorun: Wine veya winetricks adımları hata veriyor

Betik pencereyi hemen kapatmasın istiyorsanız:

```bash
sudo ./setup_etap23.sh --pause-on-error
```

Yalnızca Wine bakım akışını denemek isterseniz:

```bash
sudo ./wine_araci.sh --gui
```

## 15. GitHub Üzerinde Repo Yönetimi

Bu repoya GitHub tarafında hazırlanan dosyalar:

- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/pull_request_template.md`
- `.github/workflows/shell-lint.yml`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `SUPPORT.md`

Önerilen iş akışları:

1. Değişiklikten önce issue açın veya mevcut issue'yu bağlayın.
2. Script değişikliğinde `bash -n` ve mümkünse `shellcheck` çalıştırın.
3. Davranış değiştiyse `README` ve bu kılavuzu birlikte güncelleyin.
4. PR açarken değişikliğin kurulum akışına etkisini ve geri dönüş planını yazın.

## 16. Dokümantasyon Bakımı

Şu durumlarda `README` ve kılavuz birlikte güncellenmelidir:

- Yeni CLI parametresi eklendiğinde
- Varsayılan değer değiştiğinde
- Yeni `.desktop` dosyası veya GUI akışı geldiğinde
- Yeni paket, servis ya da geri dönüş mekanizması eklendiğinde

# Pardus ETAP23 Kurulum ve Bakım Araçları

Bu depo, ETAP23/Pardus cihazlarda ilk kurulum, dokunmatik sürücü bakımı, dokunmatik kalibrasyon, Wine işlemleri ve ETA Kayıt/Ahenk onarımı için kullanılan Bash betiklerini ve masaüstü başlatıcılarını içerir.

Bu araçlar, Selçuklu Mesleki ve Teknik Anadolu Lisesi ([seltem.meb.k12.tr](https://seltem.meb.k12.tr)) GençTek Özgür Yazılım Ekibi tarafından, danışman öğretmenleri [Adem YÜCE](https://ademyuce.tr) rehberliğinde, her kurulumda ayarları tek tek tekrar yapmamak ve yapılması gereken adımları atlamamak için hazırlandı.

## Özet

Projede şu temel yetenekler bulunur:

- Etkileşimli ilk kurulum sihirbazı
- `zenity` destekli grafik başlatıcı
- Dokunmatik sürücü kurma, güncelleme, kontrol ve geri yükleme akışları
- Ayrı dokunmatik kalibrasyon aracı
- ETA Kayıt ve Ahenk temizleme/onarma akışları
- Wine ve winetricks ön hazırlığı
- Bağımsız Wine kurulum/bakım aracı
- Boşta kapanma ve saatli kapanma ayarları

## Repo İçeriği

| Dosya | Açıklama |
| --- | --- |
| `setup_etap23.sh` | Ana kurulum ve bakım betiği |
| `setup_etap23_launcher.sh` | Grafik/terminal başlatıcı |
| `ahenk_kaldir.sh` | ETA Kayıt onarımı için sarmalayıcı |
| `dokunmatik_kalibrasyon.sh` | Dokunmatik kalibrasyon sarmalayıcısı |
| `wine_araci.sh` | Wine kurulum ve bakım sarmalayıcısı |
| `ETAP23 Ilk Kurulum.desktop` | Ana kurulum kısayolu |
| `ETAP Wine Araci.desktop` | Bağımsız Wine aracı kısayolu |
| `ETA Dokunmatik Surucu Araci.desktop` | Dokunmatik sürücü bakım kısayolu |
| `ETA Dokunmatik Kalibrasyon Araci.desktop` | Dokunmatik kalibrasyon kısayolu |
| `ETA Kayit Duzelt Sifirla.desktop` | ETA Kayıt temizleme kısayolu |
| `e-ag-client_2.9.3_amd64.deb` | Yerel kurulan e-ag istemci paketi |

## Hızlı Başlangıç

Tüm dosyaları aynı klasörde tutun ve ana kurulumu şu şekilde başlatın:

```bash
sudo ./setup_etap23.sh
```

Grafik akışı tercih ediyorsanız `ETAP23 Ilk Kurulum.desktop` dosyasını çift tıklayın. `zenity` yoksa başlatıcı terminal moduna geri düşer. İlk ekrandaki checkbox listesinden `Tumunu Sec` ve `Tumunu Kaldir` butonlarıyla tüm adımları tek seferde işaretleyebilir veya temizleyebilirsiniz.
İlk kurulum GUI'sindeki `Mevcut Yonetici Parolasi` alanı `sudo` yetkisini otomatik alabilmek için kullanılabilir. Boş bırakırsanız başlatıcı önce kayıtlı parolayı, yoksa varsayılan `etap+pardus!` değerini dener. `etapadmin` alanları boş bırakılırsa başlatıcı önce yerelde kayıtlı `etapadmin` parolasını, sonra ortamdan verilen `ETAPADMIN_PASSWORD_DEFAULT` değerini dener; ikisi de yoksa parola adımını uyarı vererek atlar. GUI, `etapadmin` parolasını ekranda göstermez. Metin kutusuna yeni parola yazılırsa bu değer yerelde saklanır.

Yalnızca Wine ile ilgili işlemler için `ETAP Wine Araci.desktop` kısayolunu veya `./wine_araci.sh --gui` komutunu kullanabilirsiniz.
Dokunmatik hizasi kaymissa `ETA Dokunmatik Kalibrasyon Araci.desktop` kisayolunu veya `./dokunmatik_kalibrasyon.sh --gui` komutunu kullanabilirsiniz.

## Sık Kullanılan Komutlar

```bash
sudo ./setup_etap23.sh --non-interactive --board-name etap-tahta-01
sudo ./setup_etap23.sh --touchdrv-upgrade
sudo ./setup_etap23.sh --touchdrv-only-upgrade
sudo ./setup_etap23.sh --touchdrv-check
sudo ./setup_etap23.sh --touchdrv-rollback
sudo ./setup_etap23.sh --touch-calibration-start
sudo ./setup_etap23.sh --touch-calibration-status
sudo ./dokunmatik_kalibrasyon.sh --reset
sudo ./setup_etap23.sh --wine-install
sudo ./setup_etap23.sh --wine-check
sudo ./setup_etap23.sh --winecfg
sudo ./setup_etap23.sh --eta-kayit-repair
sudo ./wine_araci.sh --install-vulkan
sudo ./wine_araci.sh --rebuild-prefix --wine-user etapadmin
sudo ./ahenk_kaldir.sh --reinstall-ahenk
```

- `--touchdrv-check` ve grafik dokunmatik araci, kontrol sonunda kurulu surumu, `systemctl status eta-touchdrv` icindeki servis durumunu ve oneriyi ayri bir ozet olarak gosterir.
- `dokunmatik_kalibrasyon.sh` ve `ETA Dokunmatik Kalibrasyon Araci.desktop`, kalibrasyonu surucu guncellemesinden ayri bir arac olarak acar; kaydedilen matris sonraki X11 oturumlarinda otomatik uygulanir.
- `--eta-kayit-repair` ve `ahenk_kaldir.sh`, `apt purge ahenk` adimi `/usr/share/ahenk` veya `/etc/ahenk` gibi bosalmayan kalinti klasorler yuzunden hata verirse bu klasorleri temizleyip purge islemini otomatik tekrar dener; purge basarili olsa bile kalinti klasorleri sonda tekrar temizler.
- Betik baslarken `depo.etap.org.tr/deneysel` girdilerini gecici olarak pasife alir; cikarken bunlari yedekten yeniden etkinlestirir.
- `apt-get update` sirasinda deneysel depo yine sorun cikarirsa betik yedekli geri kazanım yolunu da kullanir.
- Boşta kapanma artık grafik oturumunda çalışan bir izleyici ile izlenir; root tarafta yalnızca kapatma kararı verilir. Bu yüzden ETAP/Cinnamon oturumunda daha kararlı çalışır.

## Wine Aracı

Bağımsız Wine aracı, `setup_etap23.sh` içindeki merkezi Wine kiplerini tek başına kullanmanızı sağlar.

```bash
./wine_araci.sh --gui
sudo ./wine_araci.sh --install
sudo ./wine_araci.sh --install-vulkan
sudo ./wine_araci.sh --check
sudo ./wine_araci.sh --version
sudo ./wine_araci.sh --winecfg
sudo ./wine_araci.sh --remove
sudo ./wine_araci.sh --remove-purge-prefixes
```

- `--gui` grafik arayüzü açar; `zenity` yoksa terminal menüsü gösterilir.
- Grafik modda `Wine durumunu kontrol et` ve `Wine sürümlerini göster` seçenekleri sonucu ayrı bir pencereye yazar; pencere kapanınca Wine aracı menüsü tekrar açılır.
- `--install` yalnızca Wine ve winetricks kurulum/güncelleme akışlarını çalıştırır.
- `--install-vulkan` aynı kuruluma `dxvk` ve `vkd3d` adımlarını ekler.
- Kurulum, Wine temel font paketlerini (`fonts-wine`, `fonts-liberation2`, `fonts-dejavu-core`) de yükler ve prefix içinde font taramasını yeniler.
- Wine ile kurulan uygulamaların Linux `.desktop` kısayolları ile Wine profilindeki `Desktop` ve `Start Menu` `.lnk` kısayolları kullanıcının gerçek masaüstüne de senkronlanır. Senkron işi `/usr/local/libexec/etap-wine-sync-shortcuts` ile yapılır.
- Mevcut kullanıcıların Wine prefix'i kurulum sırasında hazırlanır; yeni oluşturulan kullanıcılar için ise ilk grafik oturumunda `/etc/xdg/autostart/etap-wine-session-bootstrap.desktop` üzerinden otomatik hazırlanır.
- `--rebuild-prefix` seçilen kullanıcının Wine prefix klasörünü yeniden oluşturur.
- `--remove-purge-prefixes` Wine paketlerine ek olarak prefix klasörlerini de siler. `--wine-user` verilmezse uygun kullanıcılar taranır.

## Dokümantasyon

- Ayrıntılı kullanım kılavuzu: [docs/KULLANIM_KILAVUZU.md](docs/KULLANIM_KILAVUZU.md)
- Katkı kuralları: [CONTRIBUTING.md](CONTRIBUTING.md)
- Güvenlik bildirimi: [SECURITY.md](SECURITY.md)
- Destek akışı: [SUPPORT.md](SUPPORT.md)

## GitHub İçin Eklenen Dosyalar

Bu repo GitHub kullanımına hazır hale getirmek için aşağıdaki dosyalar eklendi:

- `.gitignore`
- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/pull_request_template.md`
- `.github/workflows/shell-lint.yml`
- `CONTRIBUTING.md`
- `SECURITY.md`
- `SUPPORT.md`

## Önemli Notlar

- `dxvk` ve `vkd3d` Vulkan gerektirir; eski cihazlarda sorun çıkarsa kapalı bırakın.
- Bağımsız Wine aracı ve ana kurulumdaki Wine bakım kipleri aynı merkezi kod yolunu kullanır. Tek bir ortak Wine prefix yerine her kullanıcı için ayrı prefix oluşturulur; bu yaklaşım izin ve kayıt defteri çakışmalarını önler.
- Masaüstüne kopyalanan Wine kısayolları `etap-wine-*.desktop` dosya adıyla yönetilir; görünen uygulama adı Wine'ın `.desktop` veya `.lnk` kısayol adından gelir.
- `wine_araci.sh` ve `ahenk_kaldir.sh`, root degilken otomatik olarak `setup_etap23_launcher.sh` uzerinden calisir; boylece kayitli/parola denenmesi ve ortak repo yonetimi tum araclarda ayni olur.
- `dokunmatik_kalibrasyon.sh` da ayni ortak baslatici uzerinden calisir; bu sayede kalibrasyon araci da ayni sudo ve hata raporu akisini kullanir.
- Başlatıcı, hatırlanan sudo parolasını ve GUI'de açıkça girilen `etapadmin` parolasını kullanıcı profilinde saklayabilir.
- `ETA Kayıt` otomasyonu uygulamanın gerçek arayüzüne bağlıdır; otomasyon tamamlanamazsa işlemi elle bitirebilirsiniz.
- Dokunmatik kalibrasyon araci su an X11 oturumunu hedefler; Wayland oturumunda durumu gosterir ama kalibrasyonu baslatmaz.
- Boşta kapanma seçeneği açıkken kurulum, mevcut grafik oturum için izleyiciyi hemen başlatmayı da dener; sonraki oturumlarda `/etc/xdg/autostart/etap-idle-session-monitor.desktop` üzerinden otomatik devreye girer.
- Bu klasör şu anda bir Git deposu değilse, GitHub'a göndermeden önce `git init` ile repo oluşturmanız ve uzak depo bağlamanız gerekir.

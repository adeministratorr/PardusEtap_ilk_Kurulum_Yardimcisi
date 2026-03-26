# Pardus ETAP23 Kurulum ve Bakım Araçları

Bu depo, ETAP23/Pardus cihazlarda ilk kurulum, dokunmatik sürücü bakımı, dokunmatik kalibrasyon, servis sağlığı kontrolü, USB onarımı, çözünürlük profilleri, Wine işlemleri, ETA Kayıt/Ahenk onarımı ve sik gelen destek sorulari icin kullanilan Bash betiklerini ve masaustu baslaticilarini icerir.

Bu araçlar, Selçuklu Mesleki ve Teknik Anadolu Lisesi ([seltem.meb.k12.tr](https://seltem.meb.k12.tr)) GençTek Özgür Yazılım Ekibi tarafından, danışman öğretmenleri [Adem YÜCE](https://ademyuce.tr) rehberliğinde, her kurulumda ayarları tek tek tekrar yapmamak ve yapılması gereken adımları atlamamak için hazırlandı.

## Özet

Projede şu temel yetenekler bulunur:

- Etkileşimli ilk kurulum sihirbazı
- `zenity` destekli grafik başlatıcı
- İlk kurulum içinde isteğe bağlı sistem paket güncellemesi
- Dokunmatik sürücü kurma, güncelleme, kontrol ve geri yükleme akışları
- Ayrı dokunmatik kalibrasyon aracı
- Servis sağlık paneli ve temel servis/timer yeniden başlatma akışları
- USB depolama raporu ve dosya sistemi onarım aracı
- 4K, FHD ve yerel çözünürlük profilleri
- Ayrı log ve rapor görüntüleme aracı
- Yazici, dosya paylasim ve surucu/paket sorunlari icin ayri SSS/destek araci
- ETA Kayıt ve Ahenk temizleme/onarma akışları
- Wine ve winetricks ön hazırlığı
- Bağımsız Wine kurulum/bakım aracı
- EXE/MSI çalıştırma, kısayol senkronu ve Wine teşhis raporu
- Boşta kapanma ve saatli kapanma ayarları

## Repo İçeriği

| Dosya | Açıklama |
| --- | --- |
| `setup_etap23.sh` | Ana kurulum ve bakım betiği |
| `setup_etap23_launcher.sh` | Grafik/terminal başlatıcı |
| `ahenk_kaldir.sh` | ETA Kayıt onarımı için sarmalayıcı |
| `dokunmatik_kalibrasyon.sh` | Dokunmatik kalibrasyon sarmalayıcısı |
| `servis_saglik_paneli.sh` | Servis sağlık paneli sarmalayıcısı |
| `usb_onarim_araci.sh` | USB rapor/onarma sarmalayıcısı |
| `cozunurluk_profilleri.sh` | Çözünürlük profilleri sarmalayıcısı |
| `log_rapor_araci.sh` | Rapor ve günlük görüntüleme aracı |
| `sss_destek_araci.sh` | Yazici, dosya paylasim ve paket/surucu destek araci |
| `wine_araci.sh` | Wine kurulum ve bakım sarmalayıcısı |
| `ETAP23 Ilk Kurulum.desktop` | Ana kurulum kısayolu |
| `ETAP Wine Araci.desktop` | Bağımsız Wine aracı kısayolu |
| `ETA Dokunmatik Surucu Araci.desktop` | Dokunmatik sürücü bakım kısayolu |
| `ETA Dokunmatik Kalibrasyon Araci.desktop` | Dokunmatik kalibrasyon kısayolu |
| `ETA Kayit Duzelt Sifirla.desktop` | ETA Kayıt temizleme kısayolu |
| `ETAP Servis Saglik Paneli.desktop` | Servis sağlık paneli kısayolu |
| `ETA USB Onarim Araci.desktop` | USB onarım aracı kısayolu |
| `ETAP Cozunurluk Profilleri.desktop` | Çözünürlük profilleri kısayolu |
| `ETAP Log ve Rapor Araci.desktop` | Rapor ve günlük görüntüleyici kısayolu |
| `ETAP SSS ve Destek Araci.desktop` | Yazici/paylasim/surucu sorun giderme kisayolu |
| `e-ag-client_2.9.4.0_amd64.deb` | Yerel kurulan e-ag istemci paketi |

## E-Ag Istemci

Bu repoda ETAP/Pardus 23 tarafi icin Bayram KARAHAN tarafindan yayinlanan `e-ag-client_2.9.4.0_amd64.deb` paketi kullanilir. Paket metadatasinda `Package: e-ag-client`, `Version: 2.9.4.0`, `Maintainer: Bayram KARAHAN` ve `Description: e-ag Istemci Uygulamasi` bilgileri yer alir.

Referanslar:

- Bayram KARAHAN'in blog yazisi: [Ag Kontrol Yazilimi](https://bayramkarahan.blogspot.com/2019/07/ag-kontrol-yazlm.html)
- Istemci repo adresi: [bayramkarahan/e-ag-client](https://github.com/bayramkarahan/e-ag-client)
- Bu repoda kullanilan istemci paketi: [e-ag-client_2.9.4.0_amd64.deb](https://github.com/bayramkarahan/e-ag-client/raw/refs/heads/master/e-ag-client_2.9.4.0_amd64.deb)
- Pardus Uygulamalari katalog girdisi: [E-Ag Uygulamasi (sunucu)](https://apps.pardus.org.tr/app/e-ag)
- Sunucu repo adresi: [bayramkarahan/e-ag](https://github.com/bayramkarahan/e-ag)

Not: Bu repo yalnizca `e-ag-client` istemci paketini kurar. Pardus Uygulamalari sayfasindaki `E-Ag Uygulamasi` ve `bayramkarahan/e-ag` deposu sunucu tarafini temsil eder; `e-ag` sunucu paketi bu kurulum akisinda kullanilmaz.

Blog yazisinda anlatilan temel kullanim senaryolari:

- agdaki acik bilgisayarlarda toplu Linux komutu calistirma
- dosya kopyalama ve geri toplama
- mesaj gonderme, ekran kilitleme ve kapatma
- ekran erisimi, video yayini ve kamera yayini

Kurulum ve kullanim:

- ilk kurulum GUI'sinde `e-ag-client (Ag Kontrol istemci) paketini kur` secenegini isaretleyin
- veya terminalden `sudo ./setup_etap23.sh --install-eag-client` calistirin
- kurulumdan sonra uygulamayi menuden veya terminalden `e-ag-client-gui` komutuyla acin
- oturum acilisinda istemci tepsi uygulamasi gerekirse `e-ag-client-tray` ile otomatik baslar
- ayni yerel agdaki cihazlari secip Bayram KARAHAN'in blogunda anlatilan toplu yonetim islemlerini uygulayin

## E-Ag Sunucu

Sunucu paketi bu repo tarafindan otomatik kurulmaz. Merkezi yonetim yapacak cihazda ayri olarak manuel kurulmalidir. Paket metadatasinda `Package: e-ag`, `Version: 2.9.4.0`, `Maintainer: Bayram KARAHAN` ve `Description: e-ag Uzaktan Yonetim ve Goruntuleme Sunucusu` bilgileri yer alir.

Referanslar:

- Pardus Uygulamalari katalog girdisi: [E-Ag Uygulamasi](https://apps.pardus.org.tr/app/e-ag)
- Sunucu repo adresi: [bayramkarahan/e-ag](https://github.com/bayramkarahan/e-ag)
- Dogrudan sunucu paketi: [e-ag_2.9.4.0_amd64.deb](https://github.com/bayramkarahan/e-ag/raw/refs/heads/master/e-ag_2.9.4.0_amd64.deb)

Manuel kurulum:

```bash
curl -L -o e-ag_2.9.4.0_amd64.deb https://github.com/bayramkarahan/e-ag/raw/refs/heads/master/e-ag_2.9.4.0_amd64.deb
sudo apt install ./e-ag_2.9.4.0_amd64.deb
```

Alternatif olarak `sudo dpkg -i ./e-ag_2.9.4.0_amd64.deb` ve ardindan `sudo apt-get install -f -y` kullanilabilir.

Kurulumdan sonra:

- uygulamayi menuden veya `pkexec /usr/bin/e-ag` ile acin
- `ssh.service`, `e-ag-networkprofil.service`, `e-ag-x11vnclogin.service` ve `e-ag-x11vncdesktop.service` birimlerinin durumunu kontrol edin
- paket kurulumunun `gdm3` tarafinda Wayland'i kapatabildigini ve `xrdp` gunluklerini yeniden hazirladigini not edin

## Hızlı Başlangıç

Tüm dosyaları aynı klasörde tutun ve ana kurulumu şu şekilde başlatın:

```bash
sudo ./setup_etap23.sh
```

Grafik akışı tercih ediyorsanız `ETAP23 Ilk Kurulum.desktop` dosyasını çift tıklayın. `zenity` yoksa başlatıcı terminal moduna geri düşer. İlk ekrandaki checkbox listesinden `Tumunu Sec` ve `Tumunu Kaldir` butonlarıyla tüm adımları tek seferde işaretleyebilir veya temizleyebilirsiniz.
İlk kurulum listesinde ayrıca varsayılan olarak seçili `Kurulu sistem paketlerini guncelle (apt update + apt upgrade)` ve varsayılan olarak seçili olmayan `Dokunmatik surucusunu guncellemeyi engelle (paket guncellemede de)` seçenekleri bulunur. `Kurulu sistem paketlerini guncelle` listenin en sonunda yer alır; `Wine ve winetricks kur` seçeneği de varsayılan olarak işaretlidir.
İlk kurulum GUI'sindeki `Mevcut Yonetici Parolasi` alanı `sudo` yetkisini otomatik alabilmek için kullanılabilir. Boş bırakırsanız başlatıcı önce kayıtlı parolayı, yoksa varsayılan `etap+pardus!` değerini dener. `etapadmin` alanları boş bırakılırsa başlatıcı önce yerelde kayıtlı `etapadmin` parolasını, sonra ortamdan verilen `ETAPADMIN_PASSWORD_DEFAULT` değerini dener; ikisi de yoksa parola adımını uyarı vererek atlar. GUI, `etapadmin` parolasını ekranda göstermez. Metin kutusuna yeni parola yazılırsa bu değer yerelde saklanır.
Kurulum sonunda ETA Kayit acilacaksa betik once `eta-register` paketini kurar veya gunceller, sonra uygulamayi baslatir.

Yalnızca Wine ile ilgili işlemler için `ETAP Wine Araci.desktop` kısayolunu veya `./wine_araci.sh --gui` komutunu kullanabilirsiniz.
Dokunmatik hizasi kaymissa `ETA Dokunmatik Kalibrasyon Araci.desktop` kisayolunu veya `./dokunmatik_kalibrasyon.sh --gui` komutunu kullanabilirsiniz.
Servis durumlarina bakmak icin `ETAP Servis Saglik Paneli.desktop` veya `./servis_saglik_paneli.sh --gui`, USB denetimi icin `ETA USB Onarim Araci.desktop` veya `./usb_onarim_araci.sh --gui`, ekran profilleri icin `ETAP Cozunurluk Profilleri.desktop` veya `./cozunurluk_profilleri.sh --gui` kullanabilirsiniz.
Kaydedilen rapor ve gunlukleri acmak icin `ETAP Log ve Rapor Araci.desktop` veya `./log_rapor_araci.sh --gui` kullanabilirsiniz.
Yazici kurulumu, dosya paylasimi ve surucu/paket kontrolleri icin `ETAP SSS ve Destek Araci.desktop` veya `./sss_destek_araci.sh --gui` kullanabilirsiniz.

## Sık Kullanılan Komutlar

```bash
sudo ./setup_etap23.sh --non-interactive --board-name etap-tahta-01
sudo ./setup_etap23.sh --upgrade-packages
sudo ./setup_etap23.sh --install-eag-client
sudo ./setup_etap23.sh --touchdrv-upgrade
sudo ./setup_etap23.sh --touchdrv-only-upgrade
sudo ./setup_etap23.sh --touchdrv-check
sudo ./setup_etap23.sh --touchdrv-rollback
sudo ./setup_etap23.sh --touch-calibration-start
sudo ./setup_etap23.sh --touch-calibration-status
sudo ./setup_etap23.sh --service-health-check
sudo ./setup_etap23.sh --service-health-restart NetworkManager.service
sudo ./setup_etap23.sh --usb-report
sudo ./setup_etap23.sh --usb-repair /dev/sdb
sudo ./setup_etap23.sh --resolution-status
sudo ./setup_etap23.sh --resolution-profile 4k
sudo ./dokunmatik_kalibrasyon.sh --reset
sudo ./setup_etap23.sh --wine-install
sudo ./setup_etap23.sh --wine-check
sudo ./setup_etap23.sh --wine-diag
sudo ./setup_etap23.sh --winecfg
sudo ./setup_etap23.sh --wine-run-exe "/yol/ornek-uygulama.exe"
sudo ./setup_etap23.sh --wine-run-msi "/yol/ornek-kurulum.msi"
sudo ./setup_etap23.sh --wine-sync-shortcuts
sudo ./setup_etap23.sh --eta-kayit-preflight
sudo ./setup_etap23.sh --eta-kayit-repair
sudo ./setup_etap23.sh --eta-kayit-repair-full-upgrade
sudo ./wine_araci.sh --install-vulkan
sudo ./wine_araci.sh --diag
sudo ./wine_araci.sh --run-exe "/yol/ornek-uygulama.exe"
sudo ./wine_araci.sh --run-msi "/yol/ornek-kurulum.msi"
sudo ./wine_araci.sh --sync-shortcuts
sudo ./ahenk_kaldir.sh --preflight
./servis_saglik_paneli.sh --gui
./usb_onarim_araci.sh --gui
./cozunurluk_profilleri.sh --gui
./log_rapor_araci.sh --latest-report
./log_rapor_araci.sh --gui
./sss_destek_araci.sh --gui
./sss_destek_araci.sh --printer-report
./sss_destek_araci.sh --file-share-report
./sss_destek_araci.sh --driver-check kyodialog
./sss_destek_araci.sh --printer-guides
./sss_destek_araci.sh --kyocera-guide
./sss_destek_araci.sh --kyocera-local-status
./sss_destek_araci.sh --kyocera-local-prepare
sudo ./sss_destek_araci.sh --kyocera-local-install
sudo ./wine_araci.sh --rebuild-prefix --wine-user etapadmin
sudo ./ahenk_kaldir.sh --reinstall-ahenk
sudo ./ahenk_kaldir.sh --full-upgrade
```

- `--touchdrv-check` ve grafik dokunmatik araci, kontrol sonunda kurulu surumu, `systemctl status eta-touchdrv` icindeki servis durumunu ve oneriyi ayri bir ozet olarak gosterir.
- `--touchdrv-check`, `--touch-calibration-status`, `--wine-check`, `--wine-diag`, `--eta-kayit-preflight`, `--service-health-check`, `--usb-report` ve `--resolution-status` kipleri varsayilan olarak betiklerin bulundugu klasore `rapor-*.log` olarak kaydeder. Klasor yazilabilir degilse `/tmp/etap23-reports` kullanilir. Farkli bir hedef icin `--report-file DOSYA` kullanabilirsiniz.
- Olusan raporlarin basina tahta adi, MAC adresi ve IP adresi de eklenir.
- `--install-eag-client` secenegi artik varsayilan olarak yerel `e-ag-client_2.9.4.0_amd64.deb` paketini kullanir.
- `--eta-kayit-preflight` ve `ahenk_kaldir.sh --preflight`, ETA Kayit oncesi paket, runtime, aktif yonetici oturumu, temel ag, USB depolama aygitlari ve Ahenk kayit izlerini raporlar.
- `--service-health-check`, ETAP tarafinda kritik servis ve timer birimlerinin durumunu tek raporda toplar; `--service-health-restart BIRIM` desteklenen birimi yeniden baslatir.
- `--usb-report`, bagli USB depolama aygitlarini ve onarimda kullanilacak hedefleri listeler; `--usb-repair /dev/sdX`, bagli aygit icin ayri baglanan bolumleri kapatip `fsck -a` dener.
- `--resolution-status`, aktif X11 oturumunda bagli ekran cikislarini ve 4K/FHD uygunlugunu raporlar; `--resolution-profile 4k|fhd|native` secilen cikisa profili uygular.
- `log_rapor_araci.sh`, betik klasorundeki `rapor-*.log` dosyalarini, eski `reports/` altindaki raporlari, diger `.log` dosyalarini ve bulunursa Wine bootstrap gunlugunu tek yerden acar.
- `sss_destek_araci.sh`, CUPS durumu, dosya paylasim istemcileri, belirli paketlerin kurulum durumu ve ETAP rehberindeki `12.3 Yazicilar` alt basliklarinin ozetini tek arac altinda toplar.
- Kyocera icin ornek yerel bundle bu calisma alaninda `private/kyocera/fs-1120mfp/` altina indirildi; `--kyocera-local-status`, `--kyocera-local-prepare` ve `--kyocera-local-install` kipleri bu dizini kullanir.
- İlk kurulum ekranindaki `Kurulu sistem paketlerini guncelle` secenegi, önce `apt-get update`, sonra `apt-get upgrade -y` calistirir.
- `Dokunmatik surucusunu guncellemeyi engelle` secenegi aciksa, genel paket guncellemesinde de `eta-touchdrv` gecici hold ile atlanir.
- İlk kurulum sonunda ETA Kayit acilacaksa betik acilistan hemen once `eta-register` paketini kurar veya gunceller; guncelleme basarisiz olsa bile paket zaten kuruluysa mevcut surum ile devam eder.
- Wine bootstrap adimlari sabit bir zaman asimi olmadan calisir; yavas cihazlarda kurulum uzun sure aynı adımda kalabilir.
- `dokunmatik_kalibrasyon.sh` ve `ETA Dokunmatik Kalibrasyon Araci.desktop`, kalibrasyonu surucu guncellemesinden ayri bir arac olarak acar; kaydedilen matris sonraki X11 oturumlarinda otomatik uygulanir.
- `--eta-kayit-repair` ve `ahenk_kaldir.sh`, `apt purge ahenk` adimi `/usr/share/ahenk` veya `/etc/ahenk` gibi bosalmayan kalinti klasorler yuzunden hata verirse bu klasorleri temizleyip purge islemini otomatik tekrar dener; purge basarili olsa bile kalinti klasorleri sonda tekrar temizler.
- `--eta-kayit-repair-full-upgrade` ve `ahenk_kaldir.sh --full-upgrade`, standart ETA Kayit onarimina ek olarak `ahenk` paketini yeniden kurar ve son care olarak `apt-get dist-upgrade -y` calistirir.
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
sudo ./wine_araci.sh --diag
sudo ./wine_araci.sh --version
sudo ./wine_araci.sh --winecfg
sudo ./wine_araci.sh --run-exe "/yol/ornek-uygulama.exe"
sudo ./wine_araci.sh --run-msi "/yol/ornek-kurulum.msi"
sudo ./wine_araci.sh --sync-shortcuts
sudo ./wine_araci.sh --remove
sudo ./wine_araci.sh --remove-purge-prefixes
```

- `--gui` grafik arayüzü açar; `zenity` yoksa terminal menüsü gösterilir.
- Grafik modda `Wine durumunu kontrol et` ve `Wine sürümlerini göster` seçenekleri sonucu ayrı bir pencereye yazar; pencere kapanınca Wine aracı menüsü tekrar açılır.
- `--diag` aktif oturum, Wine yardımcıları, prefix durumu ve bootstrap günlüğü ile ayrıntılı tanı raporu üretir.
- `--check` ve `--diag` calistiginda rapor dosyasi otomatik kaydedilir; gerekirse `--report-file DOSYA` ile ozel yol verilebilir.
- `--install` yalnızca Wine ve winetricks kurulum/güncelleme akışlarını çalıştırır.
- `--install-vulkan` aynı kuruluma `dxvk` ve `vkd3d` adımlarını ekler.
- `--run-exe` ve `--run-msi`, seçilen kullanıcı için açık grafik oturumunda kurulum/uygulama başlatır.
- `--sync-shortcuts`, Wine profilindeki ve Linux `.desktop` kısayollarını masaüstüne yeniden senkronlar.
- Kurulum, Wine temel font paketlerini (`fonts-wine`, `fonts-liberation2`, `fonts-dejavu-core`) de yükler ve prefix içinde font taramasını yeniler.
- Wine ile kurulan uygulamaların Linux `.desktop` kısayolları ile Wine profilindeki `Desktop` ve `Start Menu` `.lnk` kısayolları kullanıcının gerçek masaüstüne de senkronlanır. Senkron işi `/usr/local/libexec/etap-wine-sync-shortcuts` ile yapılır.
- Mevcut kullanıcıların Wine prefix'i kurulum sırasında hazırlanır; yeni oluşturulan kullanıcılar için ise ilk grafik oturumunda `/etc/xdg/autostart/etap-wine-session-bootstrap.desktop` üzerinden otomatik hazırlanır.
- `--rebuild-prefix` seçilen kullanıcının Wine prefix klasörünü yeniden oluşturur.
- `--remove-purge-prefixes` Wine paketlerine ek olarak prefix klasörlerini de siler. `--wine-user` verilmezse uygun kullanıcılar taranır.

## Dokümantasyon

- Ayrıntılı kullanım kılavuzu: [docs/KULLANIM_KILAVUZU.md](docs/KULLANIM_KILAVUZU.md)
- SSS ve sorun giderme notları: [docs/SSS_SORUN_GIDERME.md](docs/SSS_SORUN_GIDERME.md)
- Yazici rehberi ozeti: [docs/YAZICI_REHBERLERI.md](docs/YAZICI_REHBERLERI.md)
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
- `.github/workflows/spellcheck-lint.yml`
- `.typos.toml`
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

# Kullanım Kılavuzu

Bu kılavuz, depodaki ETAP23/Pardus kurulum ve bakım araçlarını hem son kullanıcı hem de teknik sorumlu gözüyle uçtan uca anlatır.

Bu araçlar, Selçuklu Mesleki ve Teknik Anadolu Lisesi ([seltem.meb.k12.tr](https://seltem.meb.k12.tr)) GençTek Özgür Yazılım Ekibi tarafından, danışman öğretmenleri [Adem YÜCE](https://ademyuce.tr) rehberliğinde, her kurulumda ayarları tek tek tekrar yapmamak ve yapılması gereken adımları atlamamak için hazırlandı.

## 1. Amaç

Bu repo şu senaryoları hızlandırmak için hazırlandı:

- ETAP23/Pardus cihazlarda ilk kurulumun tekrar edilebilir şekilde yapılması
- Dokunmatik sürücü kurulum, güncelleme, kontrol ve geri yükleme işlemleri
- Temel servis ve timer birimlerinin sağlık kontrolü
- USB depolama aygıtlarının raporlanması ve onarımı
- 4K, FHD ve yerel çözünürlük profillerinin hızlı uygulanması
- Ayrı bir araçla kaydedilmiş rapor ve günlükleri görüntüleme
- ETA Kayıt ve Ahenk tarafında bozulan kayıt akışlarının temizlenmesi
- Wine/winetricks tabanlı bileşenlerin standart bir sırayla hazırlanması
- Öğretmenler ya da Yeğitek Okul Sorumluları için terminal ve grafik arayüzlü iki farklı çalışma yöntemi sunulması

## 2. Repo İçeriği

| Dosya | Görev |
| --- | --- |
| `setup_etap23.sh` | Ana kurulum ve bakım betiği |
| `setup_etap23_launcher.sh` | Grafik/terminal başlatıcı ve parola yönetimi |
| `ahenk_kaldir.sh` | ETA Kayıt/Ahenk temizliği için sarmalayıcı |
| `dokunmatik_kalibrasyon.sh` | Dokunmatik kalibrasyon sarmalayıcısı |
| `servis_saglik_paneli.sh` | Servis sağlık paneli sarmalayıcısı |
| `usb_onarim_araci.sh` | USB rapor/onarma sarmalayıcısı |
| `cozunurluk_profilleri.sh` | Çözünürlük profilleri sarmalayıcısı |
| `log_rapor_araci.sh` | Rapor ve günlük görüntüleme aracı |
| `wine_araci.sh` | Bağımsız Wine kurulum ve bakım sarmalayıcısı |
| `ETAP23 Ilk Kurulum.desktop` | Ana kurulum başlatıcısı |
| `ETAP Wine Araci.desktop` | Wine aracı başlatıcısı |
| `ETA Dokunmatik Surucu Araci.desktop` | Dokunmatik sürücü bakım başlatıcısı |
| `ETA Dokunmatik Kalibrasyon Araci.desktop` | Dokunmatik kalibrasyon başlatıcısı |
| `ETA Kayit Duzelt Sifirla.desktop` | ETA Kayıt onarım başlatıcısı |
| `ETAP Servis Saglik Paneli.desktop` | Servis sağlık paneli başlatıcısı |
| `ETA USB Onarim Araci.desktop` | USB onarım aracı başlatıcısı |
| `ETAP Cozunurluk Profilleri.desktop` | Çözünürlük profilleri başlatıcısı |
| `ETAP Log ve Rapor Araci.desktop` | Rapor ve günlük görüntüleyici başlatıcısı |
| `e-ag-client_2.9.4.0_amd64.deb` | Yerelden kurulan e-ag istemci paketi |

### 2.1 e-ag Paketi ve Kaynaklar

Bu repoda ETAP/Pardus 23 icin Bayram KARAHAN tarafindan yayinlanan `e-ag-client_2.9.4.0_amd64.deb` paketi kullanilir.

Paket metadatasi:

- Paket adi: `e-ag-client`
- Surum: `2.9.4.0`
- Bakimci: `Bayram KARAHAN <bayramk@gmail.com>`
- Aciklama: `e-ag Istemci Uygulamasi`

Referanslar:

- Bayram KARAHAN blog yazisi: [Ag Kontrol Yazilimi](https://bayramkarahan.blogspot.com/2019/07/ag-kontrol-yazlm.html)
- Istemci repo adresi: [bayramkarahan/e-ag-client](https://github.com/bayramkarahan/e-ag-client)
- ETAP icin kullanilan istemci paketi: [e-ag-client_2.9.4.0_amd64.deb](https://github.com/bayramkarahan/e-ag-client/raw/refs/heads/master/e-ag-client_2.9.4.0_amd64.deb)
- Pardus Uygulamalari kaydi: [E-Ag Uygulamasi (sunucu)](https://apps.pardus.org.tr/app/e-ag)
- Sunucu repo adresi: [bayramkarahan/e-ag](https://github.com/bayramkarahan/e-ag)

Not: Bu repo yalnizca `e-ag-client` istemci paketini kurar. Pardus Uygulamalari kaydi ve `bayramkarahan/e-ag` deposu sunucu tarafina aittir; `e-ag` sunucu paketi bu kurulum akisinda kullanilmaz.

Blog yazisinda vurgulanan kullanimlar:

- ayni agdaki bilgisayarlarda toplu komut calistirma
- dosya kopyalama ve toplama
- mesaj gonderme, ekran kilitleme ve kapatma
- ekran, video ve kamera yayini

### 2.2 e-ag Sunucu Paketi

`e-ag` sunucu paketi bu repoda otomatik kurulmaz. Bu paket, istemcileri yonetecek merkezi cihaz icin ayri olarak kurulur.

Paket metadatasi:

- Paket adi: `e-ag`
- Surum: `2.9.4.0`
- Bakimci: `Bayram KARAHAN <bayramk@gmail.com>`
- Aciklama: `e-ag Uzaktan Yonetim ve Goruntuleme Sunucusu`
- Homepage: [bayramkarahan/e-ag](https://github.com/bayramkarahan/e-ag)

Kurulum kaynaklari:

- Pardus Uygulamalari: [E-Ag Uygulamasi](https://apps.pardus.org.tr/app/e-ag)
- Repo: [bayramkarahan/e-ag](https://github.com/bayramkarahan/e-ag)
- Paket: [e-ag_2.9.4.0_amd64.deb](https://github.com/bayramkarahan/e-ag/raw/refs/heads/master/e-ag_2.9.4.0_amd64.deb)

Manuel kurulum:

```bash
curl -L -o e-ag_2.9.4.0_amd64.deb https://github.com/bayramkarahan/e-ag/raw/refs/heads/master/e-ag_2.9.4.0_amd64.deb
sudo apt install ./e-ag_2.9.4.0_amd64.deb
```

Gerekirse su yedek yol da kullanilabilir:

```bash
sudo dpkg -i ./e-ag_2.9.4.0_amd64.deb
sudo apt-get install -f -y
```

Paketin kurulum sonrasi beklenen etkileri:

- `/usr/bin/e-ag` ve `e-ag-tray` komutlari gelir
- `e-ag.desktop` ile menu kaydi olusur
- `e-ag-networkprofil.service`, `e-ag-x11vnclogin.service` ve `e-ag-x11vncdesktop.service` etkinlestirilir
- `ssh.service` etkinlestirilir
- `gdm3` icin `WaylandEnable=false` ayari zorlanabilir
- `xrdp` gunlukleri yeniden hazirlanip servis yeniden baslatilabilir

Ilk acilis:

- uygulamayi menuden veya `pkexec /usr/bin/e-ag` ile baslatin
- servis durumlarini `systemctl status e-ag-networkprofil.service e-ag-x11vnclogin.service e-ag-x11vncdesktop.service ssh.service` ile dogrulayin
- bu paketin istemci degil, merkezi yonetim sunucusu oldugunu unutmayin

## 3. Gereksinimler

Aşağıdaki koşullar sağlanmış olmalıdır:

- Pardus/ETAP23 tabanlı bir sistem
- `sudo` veya doğrudan root yetkisi
- Paket kurulumu için internet erişimi
- Grafik arayüz istiyorsanız `zenity`
- `e-ag-client_2.9.4.0_amd64.deb` dosyası ile scriptlerin aynı klasörde bulunması

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

İlk kurulum seçim listesinde `Kurulu sistem paketlerini guncelle (apt update + apt upgrade)` ve varsayılan olarak seçili olmayan `Dokunmatik surucusunu guncellemeyi engelle (paket guncellemede de)` seçenekleri de yer alır.
Kurulum sonunda ETA Kayit acilacaksa betik uygulamayi baslatmadan hemen once `eta-register` paketini kurar veya gunceller.

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
├── ETAP Cozunurluk Profilleri.desktop
├── ETAP Servis Saglik Paneli.desktop
├── ETAP Wine Araci.desktop
├── ETA Dokunmatik Kalibrasyon Araci.desktop
├── ETA Dokunmatik Surucu Araci.desktop
├── ETA Kayit Duzelt Sifirla.desktop
├── ETAP Log ve Rapor Araci.desktop
├── ETA USB Onarim Araci.desktop
├── ahenk_kaldir.sh
├── cozunurluk_profilleri.sh
├── dokunmatik_kalibrasyon.sh
├── e-ag-client_2.9.4.0_amd64.deb
├── log_rapor_araci.sh
├── servis_saglik_paneli.sh
├── setup_etap23.sh
├── setup_etap23_launcher.sh
├── usb_onarim_araci.sh
└── wine_araci.sh
```

`.desktop` dosyaları, kendi bulundukları klasöre göre ilgili scripti arar. Dosyaları ayırırsanız başlatıcı scripti bulamayabilir.

## 7. Grafik Arayüz Akışlarının Anlamı

### 7.1 ETAP23 İlk Kurulum

Bu başlatıcı şu seçenekleri yönetir:

- Tahta adını değiştirme
- `ogrenci` kullanıcısını silme
- `ogretmen` kullanıcısını silme
- `e-ag-client (Ag Kontrol istemci)` paketini kurma
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

- ETA Kayıt öncesi ön kontrol raporu oluşturma
- `eta-register` paketini kurma veya güncelleme
- `ahenk` paketini temizleme
- Varsa `/etc/ahenk/ahenk.db` dosyasını temizleme
- Gerekirse `ahenk` paketini tekrar kurma

### 7.5 ETAP Servis Sağlık Paneli

Bu akış `servis_saglik_paneli.sh --gui` üzerinden şu işlemleri yönetir:

- `eta-touchdrv.service` durumunu raporlama
- `NetworkManager.service` durumunu raporlama
- `cups.service` durumunu raporlama
- `etap-idle-shutdown.timer` durumunu raporlama
- `etap-scheduled-poweroff.timer` durumunu raporlama
- Desteklenen servis ve timer birimlerini tek tek yeniden başlatma

### 7.6 ETA USB Onarım Aracı

Bu akış `usb_onarim_araci.sh --gui` üzerinden şu işlemleri yönetir:

- Bağlı USB depolama aygıtlarını raporlama
- Seçilen USB aygıtı için onarım hedefini gösterme
- Uygun bölümleri ayırıp `fsck -a` ile dosya sistemi onarımı deneme

### 7.7 ETAP Çözünürlük Profilleri

Bu akış `cozunurluk_profilleri.sh --gui` üzerinden şu işlemleri yönetir:

- Bağlı ekran çıkışlarını raporlama
- 4K profilini uygulama
- FHD profilini uygulama
- Yerel (`xrandr --auto`) profili uygulama

### 7.8 ETAP Log ve Rapor Aracı

Bu akış `log_rapor_araci.sh --gui` üzerinden şu işlemleri yönetir:

- En yeni rapor dosyasını açma
- En yeni günlük dosyasını açma
- Kayıtlı rapor ve günlükleri listeden seçerek açma
- Mevcut rapor/günlük envanterini tek pencerede gösterme

## 8. Terminalden Kullanım

### 8.1 En sık kullanılan komutlar

```bash
sudo ./setup_etap23.sh
sudo ./setup_etap23.sh --non-interactive --board-name etap-tahta-01
sudo ./setup_etap23.sh --touchdrv-upgrade
sudo ./setup_etap23.sh --touchdrv-only-upgrade
sudo ./setup_etap23.sh --touchdrv-check
sudo ./setup_etap23.sh --touchdrv-rollback
sudo ./setup_etap23.sh --service-health-check
sudo ./setup_etap23.sh --service-health-restart eta-touchdrv.service
sudo ./setup_etap23.sh --usb-report
sudo ./setup_etap23.sh --usb-repair /dev/sdb
sudo ./setup_etap23.sh --resolution-status
sudo ./setup_etap23.sh --resolution-profile 4k
sudo ./setup_etap23.sh --upgrade-packages
sudo ./setup_etap23.sh --wine-install
sudo ./setup_etap23.sh --wine-check
sudo ./setup_etap23.sh --wine-diag
sudo ./setup_etap23.sh --winecfg
sudo ./setup_etap23.sh --wine-run-exe "/yol/ornek-uygulama.exe"
sudo ./setup_etap23.sh --wine-run-msi "/yol/ornek-kurulum.msi"
sudo ./setup_etap23.sh --wine-sync-shortcuts
sudo ./setup_etap23.sh --eta-kayit-preflight
sudo ./setup_etap23.sh --eta-kayit-repair
sudo ./setup_etap23.sh --eta-kayit-repair-reinstall-ahenk
sudo ./setup_etap23.sh --eta-kayit-repair-full-upgrade
sudo ./wine_araci.sh --install
sudo ./wine_araci.sh --install-vulkan
sudo ./wine_araci.sh --check
sudo ./wine_araci.sh --diag
sudo ./wine_araci.sh --version
sudo ./wine_araci.sh --winecfg
sudo ./wine_araci.sh --run-exe "/yol/ornek-uygulama.exe"
sudo ./wine_araci.sh --run-msi "/yol/ornek-kurulum.msi"
sudo ./wine_araci.sh --sync-shortcuts
sudo ./ahenk_kaldir.sh --preflight
./servis_saglik_paneli.sh --gui
./usb_onarim_araci.sh --gui
./cozunurluk_profilleri.sh --gui
./log_rapor_araci.sh --latest-report
./log_rapor_araci.sh --gui
sudo ./wine_araci.sh --rebuild-prefix --wine-user etapadmin
sudo ./wine_araci.sh --remove-purge-prefixes
sudo ./ahenk_kaldir.sh
sudo ./ahenk_kaldir.sh --reinstall-ahenk
sudo ./ahenk_kaldir.sh --full-upgrade
./ahenk_kaldir.sh --gui
```

### 8.2 Genel seçenekler

| Parametre | Açıklama |
| --- | --- |
| `--interactive` | Etkileşimli modu zorlar |
| `--non-interactive` | Soru sormadan ilerler |
| `--pause-on-error` | Hata durumunda pencereyi hemen kapatmaz |
| `--report-file DOSYA` | Çıktıyı belirtilen rapor dosyasına da yazar |
| `--skip-apt-update` | `apt-get update` adımını atlar |
| `-h`, `--help` | Yardım ekranını gösterir |

### 8.3 Dokunmatik, servis, USB, çözünürlük ve ETA Kayıt kipleri

| Parametre | Açıklama |
| --- | --- |
| `--touchdrv-upgrade` | Dokunmatik sürücüyü kurar/günceller, doğrular, gerekirse geri döner |
| `--touchdrv-only-upgrade` | Sadece `eta-touchdrv` için `--only-upgrade` yapar |
| `--touchdrv-check` | Kurulu sürümü ve servis durumunu raporlar, ayrıca rapor dosyası oluşturur |
| `--touchdrv-rollback` | `eta-touchdrv=0.3.5` sürümüne geri döner |
| `--service-health-check` | Temel servis ve timer durumlarını raporlar, ayrıca rapor dosyası oluşturur |
| `--service-health-restart BIRIM` | Desteklenen servis veya timer birimini yeniden başlatır |
| `--service-health-target BIRIM` | Servis sağlık kipinde hedef birimi ayrıca belirtir |
| `--usb-report` | Bağlı USB depolama aygıtlarını raporlar, ayrıca rapor dosyası oluşturur |
| `--usb-repair AYGIT` | Seçilen USB depolama aygıtını onarmayı dener |
| `--usb-target AYGIT` | USB onarım kipinde hedef aygıtı ayrıca belirtir |
| `--resolution-status` | X11 oturumundaki ekran çıkışlarını ve modları raporlar, ayrıca rapor dosyası oluşturur |
| `--resolution-profile PROFIL` | `4k`, `fhd` veya `native` çözünürlük profilini uygular |
| `--resolution-profile-target CIKIS` | Çözünürlük profili için hedef ekran çıkışını seçer |
| `--eta-kayit-preflight` | ETA Kayıt öncesi ön kontrol ve rapor oluşturur |
| `--eta-kayit-repair` | ETA Kayıt/Ahenk temizliği yapar |
| `--eta-kayit-repair-reinstall-ahenk` | Temizlikten sonra `ahenk` paketini tekrar kurar |
| `--eta-kayit-repair-full-upgrade` | Temizlikten sonra `ahenk` paketini tekrar kurar ve son çare olarak tüm paketleri günceller |

### 8.4 Ana kurulum seçenekleri

| Parametre | Açıklama |
| --- | --- |
| `--board-name AD` | Tahta adı/hostname |
| `--change-hostname` | Hostname değiştir |
| `--skip-hostname` | Hostname değiştirme |
| `--remove-ogrenci` / `--keep-ogrenci` | `ogrenci` kullanıcısını sil veya koru |
| `--remove-ogretmen` / `--keep-ogretmen` | `ogretmen` kullanıcısını sil veya koru |
| `--install-eag-client` / `--skip-eag-client` | Yerel `e-ag-client` istemci paketini kur veya atla |
| `--install-eta-qr-login` / `--skip-eta-qr-login` | `eta-qr-login` adımını aç/kapat |
| `--upgrade-packages` / `--skip-upgrade-packages` | Önce paket listesini yenile, sonra kurulu sistem paketlerini güncelle veya atla |
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
| `--wine-diag` | Wine için ayrıntılı teşhis raporu üret |
| `--wine-version` | Wine ve winetricks sürümlerini göster |
| `--winecfg` | Aktif grafik oturumundaki kullanıcı için `winecfg` aç |
| `--wine-run-exe DOSYA` | Açık grafik oturumundaki kullanıcı için EXE dosyası çalıştır |
| `--wine-run-msi DOSYA` | Açık grafik oturumundaki kullanıcı için MSI paketi çalıştır |
| `--wine-sync-shortcuts` | Seçilen kullanıcı için Wine kısayollarını yeniden senkronla |
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
| `--diag` | Wine için ayrıntılı teşhis raporu üretir |
| `--version` | Wine ve winetricks sürümlerini gösterir |
| `--winecfg` | `winecfg` açar |
| `--run-exe DOSYA` | EXE dosyası çalıştırır |
| `--run-msi DOSYA` | MSI paketi çalıştırır |
| `--sync-shortcuts` | Wine kısayollarını yeniden senkronlar |
| `--rebuild-prefix` | Wine prefix klasörünü yeniden oluşturur |
| `--remove` | Wine paketlerini kaldırır |
| `--remove-purge-prefixes` | Wine paketlerini ve prefix klasörlerini siler |
| `--wine-user KULLANICI` | Hedef kullanıcıyı seçer |
| `--wine-prefix-name AD` | Prefix klasör adını belirtir |
| `--wine-windows-version S` | Windows sürümünü belirtir |
| `--report-file DOSYA` | Çıktıyı belirtilen rapor dosyasına da yazar |
| `--enable-vulkan` / `--disable-vulkan` | Vulkan bileşenlerini açar/kapatır |

Not: `dxvk` ve `vkd3d` Vulkan gerektirir. Eski Intel iGPU sistemlerde sorun çıkarsa kapalı kullanın.
Not: `--touchdrv-check`, `--touch-calibration-status`, `--wine-check`, `--wine-diag`, `--eta-kayit-preflight`, `--service-health-check`, `--usb-report` ve `--resolution-status` kipleri varsayılan olarak betiklerin bulunduğu klasöre `rapor-*.log` olarak kaydeder. Bu klasör yazılabilir değilse `/tmp/etap23-reports` kullanılır. İsterseniz `--report-file DOSYA` ile özel yol verebilirsiniz.
Not: Bu raporların başında tahta adı, MAC adresi ve IP adresi de yer alır.

### 8.7 Güç yönetimi seçenekleri

| Parametre | Açıklama |
| --- | --- |
| `--enable-idle-shutdown` / `--disable-idle-shutdown` | Boşta kapatma ayarını açar/kapatır |
| `--idle-shutdown-minutes DAKIKA` | Boşta kapanma süresi |
| `--enable-scheduled-shutdown` / `--disable-scheduled-shutdown` | Günlük kapanma ayarını açar/kapatır |
| `--scheduled-shutdown SAAT:DAKIKA` | Günlük kapanma saati |

### 8.8 Log ve rapor aracı seçenekleri

| Parametre | Açıklama |
| --- | --- |
| `--gui` | Grafik arayüzlü log ve rapor aracını açar |
| `--list` | Bulunan rapor ve günlük dosyalarını listeler |
| `--pick` | Listeden dosya seçip açar |
| `--latest-report` | En yeni rapor dosyasını açar |
| `--latest-log` | En yeni günlük dosyasını açar |
| `--show DOSYA` | Belirtilen dosyayı açar |

## 9. Varsayılan Davranışlar

Betik ilk çalışmada genellikle şu adımları açık getirir:

- Hostname isteme ve değiştirme
- `ogrenci` kullanıcısını silme
- `ogretmen` kullanıcısını silme
- Yerel `e-ag-client_2.9.4.0_amd64.deb` kurma
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

### 12.2.1 e-ag / Ag Kontrol paketini kurmak ve kullanmak

```bash
sudo ./setup_etap23.sh --install-eag-client
```

Kullanim adimlari:

1. Paketin scriptlerle ayni klasorde oldugunu dogrulayin.
2. `sudo ./setup_etap23.sh --install-eag-client` ile yerel paketi kurun.
3. Kurulumdan sonra uygulamayi menuden veya terminalde `e-ag-client-gui` komutuyla baslatin.
4. Gerekirse oturum acilisinda `e-ag-client-tray` ile tepsi uygulamasinin basladigini kontrol edin.
5. Ayni yerel agdaki makineleri secip komut, dosya, mesaj, ekran veya yayin islemlerini uygulayin.

### 12.2.2 e-ag sunucu paketini manuel kurmak

```bash
curl -L -o e-ag_2.9.4.0_amd64.deb https://github.com/bayramkarahan/e-ag/raw/refs/heads/master/e-ag_2.9.4.0_amd64.deb
sudo apt install ./e-ag_2.9.4.0_amd64.deb
```

Kontrol listesi:

1. Bu kurulumu istemci degil, yonetim yapacak merkezi cihazda uygulayin.
2. Kurulumdan sonra `pkexec /usr/bin/e-ag` ile araci acin.
3. `systemctl status e-ag-networkprofil.service e-ag-x11vnclogin.service e-ag-x11vncdesktop.service ssh.service` ile servisleri kontrol edin.
4. GDM kullaniyorsaniz kurulumun Wayland'i kapatabildigini dikkate alin.
5. Bagimlilik sorunu olursa `sudo dpkg -i ./e-ag_2.9.4.0_amd64.deb` ve `sudo apt-get install -f -y` sirasini kullanin.

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
sudo ./ahenk_kaldir.sh --preflight
sudo ./ahenk_kaldir.sh
```

Gerekirse:

```bash
sudo ./ahenk_kaldir.sh --reinstall-ahenk
```

Önerilen sıra:

1. `sudo ./ahenk_kaldir.sh --preflight`
2. Rapordaki ağ, USB ve oturum uyarılarını giderin.
3. Sorun sürerse `sudo ./ahenk_kaldir.sh`
4. Hâlâ düzelmezse `sudo ./ahenk_kaldir.sh --reinstall-ahenk`

### 12.7 Servis veya timer beklenen durumda değilse

```bash
sudo ./servis_saglik_paneli.sh --check
sudo ./servis_saglik_paneli.sh --restart eta-touchdrv.service
```

Önerilen sıra:

1. Önce raporu alın ve hangi birimin bozuk olduğunu görün.
2. Yalnızca ilgili birimi yeniden başlatın.
3. Sorun sürüyorsa aynı raporu tekrar alıp servis günlüklerine bakın.

### 12.8 USB bellek görünmüyor veya dosya sistemi hatalıysa

```bash
sudo ./usb_onarim_araci.sh --report
sudo ./usb_onarim_araci.sh --repair /dev/sdb
```

Not: Bu akış kök dosya sistemine dokunmaz; yalnızca takılı USB depolama aygıtlarını hedefler.

### 12.9 Ekran çözünürlüğü 4K veya FHD olarak sabitlenmek isteniyorsa

```bash
sudo ./cozunurluk_profilleri.sh --status
sudo ./cozunurluk_profilleri.sh --4k
sudo ./cozunurluk_profilleri.sh --fhd
```

Not: Çözünürlük profilleri aktif X11 oturumu gerektirir. Wayland veya kapalı grafik oturumunda uygulanmaz.

### 12.10 Kaydedilmiş rapor ve günlükleri tek yerden incelemek

```bash
./log_rapor_araci.sh --latest-report
./log_rapor_araci.sh --list
./log_rapor_araci.sh --gui
```

Bu akış özellikle sahada alınan kontrol raporlarını sonradan açmak için uygundur.

## 13. Doğrulama Komutları

Dokunmatik sürücüyü elle kontrol etmek için:

```bash
apt-cache policy eta-touchdrv
systemctl status eta-touchdrv
```

Servis ve timer durumlarını elle doğrulamak için:

```bash
systemctl status NetworkManager.service
systemctl status cups.service
systemctl list-timers etap-idle-shutdown.timer etap-scheduled-poweroff.timer
```

USB aygıtlarını elle doğrulamak için:

```bash
lsblk -o NAME,TRAN,RM,SIZE,MODEL,MOUNTPOINT
sudo fsck -N /dev/sdb1
```

Çözünürlük durumunu elle doğrulamak için:

```bash
xrandr --query
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

### Sorun: Çözünürlük profili uygulanmıyor

Muhtemel nedenler:

- Aktif X11 oturumu yok
- İstenen çözünürlük bağlı ekranda desteklenmiyor
- Hedef ekran çıkışı otomatik seçilemedi

Önce durum raporunu alın:

```bash
sudo ./cozunurluk_profilleri.sh --status
```

### Sorun: USB onarım denemesi başarısız oluyor

Muhtemel nedenler:

- Aygıt doğru hedeflenmedi
- Bölümler başka bir süreç tarafından açık tutuluyor
- Dosya sistemi daha derin elle müdahale gerektiriyor

Önce rapor alın, sonra doğru aygıt yoluyla tekrar deneyin:

```bash
sudo ./usb_onarim_araci.sh --report
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

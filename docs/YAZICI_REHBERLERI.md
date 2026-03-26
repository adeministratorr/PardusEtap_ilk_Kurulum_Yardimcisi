# Yazici Rehberleri

Bu belge, ETAP rehberindeki `12.3. Yazicilar` alt basliklarinin kisa teknik ozetini
ve repo icindeki destek aracina nasil yansitildigini toplar.

Kaynaklar:

- [12.3. Yazicilar](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar)
- [Arayuz ile Surucusu Hazir Yazici Kurulumu](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/b-arayuz-ile-surucusu-hazir-yazici-kurulumu)
- [CUPS Baglantisi ile Surucusu Hazir Yazici Kurulumu](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/c-cups-baglantisi-ile-surucusu-hazir-yazici-kurulumu)
- [Internetten Surucu Indirilmesi Gereken Yazicilarin Kurulumu](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu)
- [Brother marka yazici kurulumu nasil yapilir?](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/c-brother-marka-yazici-kurulumu-nasil-yapilir)
- [Epson marka yazici kurulumu nasil yapilir?](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/d-epson-marka-yazici-kurulumu-nasil-yapilir)
- [HP yazici kurulumu nasil yapilir?](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/e-hp-yazici-kurulumu-nasil-yapilir)
- [Canon yazici kurulumu nasil yapilir?](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/f-canon-yazici-kurulumu-nasil-yapilir)

## 1. Genel Yazici Ekrani

ETAP rehberine gore `Sistem Ayarlari > Yazicilar` ekrani:

- Sisteme bagli yazicilari listeler
- Baglanti turu ve kuyruk durumu gibi temel bilgileri gosterir
- Yazici ekleme, kaldirma ve duzenleme islemleri icin kullanilir

Yazici yonetmeden once:

- `Kilidi Ac...` ile yetkili kullanici parolasi girilmelidir
- `lpadmin` grubu uyeleri yazici yonetebilir

## 2. Surucusu Hazir Yazicilar

### 2.1 Arayuz ile kurulum

ETAP rehberindeki on hazirlik komutlari:

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt install --reinstall printer-driver-* cups* tix groff dc make gcc jbigkit-bin hpijs-ppds
sudo /etc/init.d/cups restart
```

Ardindan sistem yeniden baslatilir.

Kurulum sirasi:

1. `Ayarlar > Yazicilar` ekranini acin.
2. `Kilidi Ac...` ile yetki alin.
3. `Yazici Ekle...` ile listeyi acin.
4. Ag yazicisi listede yoksa IP ile devam edin.
5. Marka listede gorunmuyorsa `CUPS-BRF-Printer` ile ilerleyin.
6. Surucu arama, veri tabanindan marka-model secme veya PPD dosyasi saglama yontemlerinden birini kullanin.

### 2.2 CUPS ile kurulum

ETAP rehberindeki on hazirlik komutlari aynidir.

CUPS yonetimi:

- Tarayicida `http://localhost:631`
- `Administration` menusunden `Add Printer`, `Find New Printers`, `Manage Printers`
- `Local Printers` altinda `CUPS-BRF` secilerek marka-model veya PPD secimine ilerlenebilir

## 3. Internetten Surucu Gereken Yazicilar

ETAP rehberine gore:

1. Arayuz ve CUPS yontemleri calismiyorsa modelin surucusu sistemde hazir olmayabilir.
2. Markanin resmi sitesinden modelinize uygun Linux surucusu indirilmelidir.
3. Marka-ozel alt basliklar izlenmelidir.
4. Sonuc alinamazsa ETAP destek hattina yonlendirme yapilir.

## 4. Brother

Kaynaklar:

- [ETAP Brother sayfasi](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/c-brother-marka-yazici-kurulumu-nasil-yapilir)
- [Pardus belge Brother](https://belge.pardus.org.tr/display/PYMBB/Brother)
- [Brother installer dosyasi](https://belge.pardus.org.tr/download/attachments/117997644/linux-brprinter-installer-2.2.3-1?version=1&modificationDate=1704839652130&api=v2)

Ozet:

- Resmi siteden Debian `.deb` surucusu aranir; yoksa genel Linux surucusu kullanilir.
- Pardus belge uzerindeki `linux-brprinter-installer-2.2.3-1` installer kullanilabilir.

Komut sirasi:

```bash
sudo dpkg --add-architecture i386 && sudo apt update
sudo chmod u+x linux-brprinter-installer-2.2.3-1
sudo ./linux-brprinter-installer-2.2.3-1
```

## 5. Epson

Kaynaklar:

- [ETAP Epson sayfasi](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/d-epson-marka-yazici-kurulumu-nasil-yapilir)
- [Pardus belge Epson](https://belge.pardus.org.tr/display/PYMBB/Epson)

Ilk yol:

```bash
sudo apt-get -f install
sudo dpkg --configure -a
sudo apt update
sudo apt install printer-driver-escpr
```

Alternatif yol:

```bash
sudo apt-get update && sudo apt-get upgrade
wget lsb-compat_9.20161125_amd64.deb
sudo dpkg -i lsb-compat_9.20161125_amd64.deb
```

## 6. HP

Kaynaklar:

- [ETAP HP sayfasi](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/e-hp-yazici-kurulumu-nasil-yapilir)
- [HP kurulum videosu](https://www.youtube.com/watch?v=iNE1IR-0jDc)

Bu sayfada yazili komut akisi yerine video yonlendirmesi bulunur.

## 7. Canon

Kaynaklar:

- [ETAP Canon sayfasi](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/f-canon-yazici-kurulumu-nasil-yapilir)
- [Canon kurulum videosu](https://www.youtube.com/watch?v=qD2JuAcD-aA)

Bu sayfada yazili komut akisi yerine video yonlendirmesi bulunur.

## 8. Kyocera

Kyocera icin ayri yerel bundle ve arac kipleri hazirlandi:

```bash
./sss_destek_araci.sh --kyocera-guide
./sss_destek_araci.sh --kyocera-local-status
./sss_destek_araci.sh --kyocera-local-prepare
sudo ./sss_destek_araci.sh --kyocera-local-install
```

Yerel bundle kok dizini:

```text
private/kyocera/fs-1120mfp/
```

## 9. Aracta Toplu Ozet

Bu rehberlerin hepsi destek aracinda tek ciktida da toplanir:

```bash
./sss_destek_araci.sh --printer-guides
```

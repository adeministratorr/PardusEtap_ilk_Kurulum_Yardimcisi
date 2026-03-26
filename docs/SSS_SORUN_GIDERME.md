# SSS ve Sorun Giderme

Bu belge, ETAP/Pardus sahasinda sik gelen yazici, dosya paylasim ve paket/surucu
sorulari icin hazirlanan hizli basvuru notlarini toplar.

## 1. Yeni Destek Araci

Bu repo icinde artik `sss_destek_araci.sh` ve `ETAP SSS ve Destek Araci.desktop`
dosyalari bulunur.

Temel kullanim:

```bash
./sss_destek_araci.sh --gui
./sss_destek_araci.sh --printer-report
sudo ./sss_destek_araci.sh --printer-restart
./sss_destek_araci.sh --file-share-report
./sss_destek_araci.sh --driver-check kyodialog
./sss_destek_araci.sh --printer-guides
./sss_destek_araci.sh --kyocera-guide
./sss_destek_araci.sh --kyocera-local-status
./sss_destek_araci.sh --kyocera-local-prepare
sudo ./sss_destek_araci.sh --kyocera-local-install
```

Bu arac su basliklarda hizli ozet verir:

- CUPS ve tanimli yazicilar
- SMB/CIFS ve NFS istemci hazirligi
- Paket/surucu icin `dpkg-query` ve `apt-cache policy` ozeti
- ETAP rehberindeki `12.3 Yazicilar` alt basliklarinin toplu ozeti
- ETAP rehberindeki Kyocera kurulum akisinin sade ozeti

## 2. Yazici Kurulumu ve Kontrolu

Yazici tarafinda once su sira ile ilerleyin:

1. `./sss_destek_araci.sh --printer-report`
2. Gerekirse `sudo ./sss_destek_araci.sh --printer-restart`
3. Ardindan `http://localhost:631/admin` uzerinden CUPS kuyrugunu kontrol edin

Elle kontrol icin kullanisli komutlar:

```bash
systemctl status cups.service
lpstat -r
lpstat -t
lpinfo -v
```

Ag yazicisi eklerken en sik kullanilan baglanti bicimleri:

- `socket://YAZICI_IP:9100`
- `ipp://YAZICI_IP/ipp/print`

ETAP rehberindeki toplu yazici ozetini hizlica gormek icin:

```bash
./sss_destek_araci.sh --printer-guides
```

Ayrica ayrintili notlar icin [YAZICI_REHBERLERI.md](YAZICI_REHBERLERI.md)
belgesini kullanabilirsiniz.

## 3. Dosya Paylasma Sorunlari

Dosya paylasiminda once istemci hazirligini kontrol edin:

```bash
./sss_destek_araci.sh --file-share-report
```

Elle dogrulamak isterseniz:

```bash
smbclient -L //SUNUCU -U KULLANICI
gio open smb://SUNUCU/PAYLASIM
```

Aktif bagli paylasimlari gormek icin:

```bash
cat /proc/mounts | grep -E ' cifs | smb3 | nfs | nfs4 '
```

## 4. Paket ve Surucu Kontrolu

Bir paketin kurulu olup olmadigini ve depo adayini hizlica gormek icin:

```bash
./sss_destek_araci.sh --driver-check kyodialog
./sss_destek_araci.sh --driver-check cups
./sss_destek_araci.sh --driver-check cifs-utils
```

Bu cikti, ozellikle bozuk kurulumlarda `sudo apt install --reinstall PAKET`
kararini hizlandirir.

## 5. Kyocera Ornegi

Kyocera kurulumu icin kaynak olarak ETAP rehberindeki su sayfa baz alinmistir:

- [Kyocera yazici kurulumu nasil yapilir?](https://rehber.etap.org.tr/sikca-sorulan-sorular/12-nasil-yapilir/12-3-yazicilar/d-internetten-surucu-indirilmesi-gereken-yazicilarin-kurulumu/b-kyocera-yazici-kurulumu-nasil-yapilir)

Bu rehbere gore ozet akis su sekildedir:

1. `kyoceradocumentsolutions.com.tr` uzerindeki destek/indirme merkezinden modelinizi secin.
2. Modelinize uygun `Linux Universal Driver` ve `Linux Driver` dosyalarini indirin.
3. Universal driver paketini cikartip `Debian/Global/kyodialog_amd64/` dizinine girin.
4. Bu dizinde sirasiyla `sudo apt update`, `sudo apt -f install` ve `sudo dpkg -i kyodialog_*.deb` komutlarini calistirin.
5. Model driver paketini cikartin; `64bit/Global/turkish.tar.gz` arsivini da acin.
6. `turkish` dizininde `sudo ./install` komutunu calistirin.
7. Yazici eklerken `PPD Dosyasini saglayin` secin ve `/usr/share/cups/model/Kyocera/` altindaki uygun `.ppd` dosyasini secin.

Rehberde ornek olarak su dosya/yol adlari gecmektedir:

- `Linux_Universal_Driver.zip`
- `KyoceraLinuxPackages-20220928.tar.gz`
- `LinuxDrv_1.1203_FS-1x2xMFP.zip`
- `/usr/share/cups/model/Kyocera/Kyocera_FS-1120MFPGDI.ppd`

Not: Bu adlar model ve surume gore degisebilir. Kalip aynidir; en sonda her zaman
modelinize uygun `.deb` ve `.ppd` dosyasini secmeniz gerekir.

### 5.1 Yerel bundle entegrasyonu

Bu calisma alaninda ornek bundle su dizine indirildi:

```text
private/kyocera/fs-1120mfp/
```

Hazirlik ve kurulum komutlari:

```bash
./sss_destek_araci.sh --kyocera-local-status
./sss_destek_araci.sh --kyocera-local-prepare
sudo ./sss_destek_araci.sh --kyocera-local-install
```

Bu akista:

1. `Linux_Universal_Driver.zip` ve `LinuxDrv_1.1203_FS-1x2xMFP.zip` yerel bundle altinda aranir.
2. Arac bu dosyalari `work/` dizinine cikartir.
3. `kyodialog_9.4-0_amd64.deb`, `install.sh` ve ilgili `.ppd` dosyalari otomatik tespit edilir.
4. Linux/Pardus cihazda `--kyocera-local-install` cagrisi, bu yerel dosyalari kullanarak kurulumu baslatir.

## 6. Hangi Durumda Hangi Araci Acmali?

- Yazici listede yoksa: `--printer-report`
- Yazici servisi takildiysa: `--printer-restart`
- Agdaki paylasimli klasor acilmiyorsa: `--file-share-report`
- Surucu paketi kurulu mu diye bakilacaksa: `--driver-check PAKET`
- ETAP rehberindeki yazici alt basliklari tek yerde gorulecekse: `--printer-guides`
- Kyocera adimlari unutulduysa: `--kyocera-guide`
- Yerel indirilen Kyocera bundle kullanilacaksa: `--kyocera-local-status` ve `--kyocera-local-prepare`

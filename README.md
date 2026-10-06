# 🌙 Cihanşah (com.teymensel.cihansah)
### Geliştirici: Teymensel
**Platform:** Android (Google Play Store) & PC  
**Oyun Motoru:** Godot 4.7.2  

---

## 📌 Oyun Hakkında & Hikaye Özeti
**Cihanşah**, 19. yüzyıl sonu Osmanlı Payitahtı İstanbul'unda geçen, üçüncü şahıs (3D) bakış açısına sahip, zengin hikayeli bir aksiyon-macera oyunudur.

Kahramanımız **Cihanşah**, dışarıdan bakıldığında **Hilâl-i Ahmer** cemiyeti için fedakarca çalışan bir neferdir; ancak hakikatte **Teşkilât-ı Mahsûsa**'nın en mahir ve adalet timsali gizli operatörüdür. Gayesi sadece devleti korumak değil; padişah dahi olsa haksızlığa karşı durup masumları, yetimleri ve milleti muhafaza etmek, genç dimağlara iyilik ve adalet aşılamaktır.

---

## 🎮 Temel Oynanış ve Yenilikçi Mekanikler

1. **At Binme (Gülbatur & Kırat):**
   - Şehir sokaklarında veya arazide binek atına yaklaşarak tek tuşla binebilir, dörtnala koşturabilir ve istediğiniz an inebilirsiniz.
   - Gerçekçi at nalı sesleri ve dinamik sürüş fiziği.

2. **Altıpatlar (6-Shooter) & Yakın Dövüş:**
   - Ekranda silindirin 6 yuvasını gösteren özel mermi arayüzü (`●●●●●●`).
   - Mermi bittiğinde boş kovan tıkırtısı ve gerçekçi doldurma (reload) animasyonu.
   - Osmanlı tokatı ve kama ile yakın dövüş saldırısı.

3. **Şadırvan & Abdest Alma (Manevi Sıhhat & Can Tazeleme):**
   - Zaptiye oyunundaki gibi güç azaldığında cami avlusundaki tarihi şadırvana veya çeşmeye giderek **Abdest Al** tuşuna basılır.
   - Su sesleri eşliğinde can (HP) ve dayanıklılık (Stamina) %100 dolar.

4. **Kıraathane Satranç & Casus Dimitri Sorgulama Sahnesi:**
   - Çayhanede Odesa tüccarı kılığına girmiş Rus ajanı Dimitri Voronin ile satranç masasına oturulur.
   - Satranç hamleleri eşliğinde gerilim tırmanır.
   - Cihanşah casusun kimliğini deşifre edince Altıpatlar'ını masaya vurur, **5 mermiyi masaya boşaltıp tek bir mermi bırakır** ve namluyu casusun alnına diker!
   - Korkudan titreyen ajan, Padişahın kızı **Mihrimah Sultan**'ın faytonuna kurulacak pusunun şifreli haritasını itiraf eder.

5. **Saltanat Faytonunu Pusuya Karşı Savunma:**
   - Atına binip sur kapısındaki saray arabasına yetişir, pusu kuran suikastçı eşkıyalarla çatışarak masumları kurtarırsınız.

6. **Warband Tarzı Karakter Diyalogları:**
   - Karakter portreleri, unvanları ve çoktan seçmeli tarihi yanıtlar (Eşref Bey, Dimitri vb.).

7. **Dokunmatik Mobil HUD & Klavye Kontrolleri:**
   - Sol el için Sanal Joystick.
   - Sağ el için dairesel Osmanlı altın işlemeli eylem butonları (🎯 Ateş, 🔄 Doldur, ⚔️ Vuruş, 🐎 At, 💧 Abdest, 🗣️ Konuş, 🗺️ Harita).
   - Antik parşömen İstanbul haritası.

---

## ⌨️ Masaüstü / PC Kontrolleri
- **W, A, S, D:** Yürüme / Koşma
- **Shift:** Hızlı Koşma (Depar)
- **Boşluk (Space):** Zıplama
- **Sol Fare Tıkı / Ateş Butonu:** Altıpatlar Ateş
- **R:** Altıpatlar Mermisi Doldur
- **F:** Yakın Dövüş (Osmanlı Tokatı)
- **H:** Binek Atına Bin / İn
- **Q:** Abdest Al (Şadırvan yanında can doldur)
- **E:** Konuş / Etkileşime Geç
- **Sağ Fare Tıkı:** Fare İmlecini Yakala / Serbest Bırak (Kamera çevirme)

---

## 🚀 Projeyi Çalıştırma (Godot Console / Editor)
Godot 4 motoru bilgisayarınızda `C:\Users\blgsy\godot\` klasörüne kurulmuş ve ortam değişkenlerine eklenmiştir.

### Komut Satırından Başlatma:
```powershell
& "C:\Users\blgsy\godot\Godot_v4.7.2-stable_win64_console.exe" --path "c:\Users\blgsy\Documents\cihansah"
```

### Grafik Arayüzlü Editörü Açma:
```powershell
& "C:\Users\blgsy\godot\Godot_v4.7.2-stable_win64.exe" --path "c:\Users\blgsy\Documents\cihansah" -e
```

### Google Play Store İçin Android Çıktısı (APK / AAB):
`export_presets.cfg` dosyası `com.teymensel.cihansah` paket adı ile hazır şekilde yapılandırılmıştır.
Godot Editöründen **Project -> Export -> Android** seçilerek doğrudan APK veya Google Play AAB paketi oluşturulabilir.

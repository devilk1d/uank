# Fitur Aplikasi "uank" — Spesifikasi Lengkap

Dokumen ini merangkum seluruh fitur yang sudah disepakati, dipetakan ke
objek database yang sudah ada (`schema.sql` + `schema_patch_user_id_default.sql`)
dan kode Flutter yang sudah dibuat. Gunakan tiap bagian sebagai prompt
mandiri untuk melanjutkan pengembangan.

> **Cara pakai di Antigravity (atau AI coding agent lain):** paste
> seluruh dokumen ini sekali di awal sesi sebagai konteks proyek, lalu
> untuk tiap fitur yang mau dikerjakan, rujuk nomornya (misal "kerjakan
> fitur 5") atau salin blok **Prompt** yang bersangkutan. Bagian
> *Sudah tersedia* / *Belum ada* di tiap fitur memberi tahu agent apa
> yang boleh dipakai ulang (jangan dibuat ulang) dan apa yang perlu
> dibuat baru — ini penting supaya agent tidak menimpa kode yang sudah
> berjalan.

Status per fitur: ✅ selesai · 🟡 sebagian · ⬜ belum dikerjakan

---

## Struktur Folder Proyek (`lib/`)

Struktur ini **3 lapisan** (bukan 4 — tanpa interface abstrak di
`domain/repositories/`), dipilih karena ini proyek pribadi tanpa
kebutuhan unit test/mock. Widget tidak pernah memanggil Supabase
langsung — selalu lewat repository.

```
lib/
├── main.dart
│
├── core/
│   ├── config/
│   │   ├── supabase_client.dart      # inisialisasi koneksi Supabase, baca .env
│   │   └── auth_repository.dart      # login/signup/logout, auth state stream
│   └── theme/
│       ├── app_colors.dart           # palet warna (aksen hijau, varian dark/light)
│       ├── app_theme.dart            # ThemeData lengkap Material 3
│       ├── app_background.dart       # gradient + glow, pembungkus tiap layar
│       └── glass_card.dart           # widget kaca reusable (BackdropFilter + border)
│
├── domain/
│   └── entities/                     # model data murni (Freezed), 1 file per tabel/view
│       ├── account.dart
│       ├── account_balance.dart      # dari VIEW account_balances
│       ├── category.dart
│       ├── transaction.dart
│       ├── transfer.dart
│       ├── bill.dart
│       ├── bill_payment.dart
│       ├── exchange_rate.dart
│       └── device_token.dart
│
├── data/                             # satu-satunya lapisan yang bicara ke Supabase
│   ├── accounts/account_repository.dart
│   ├── categories/category_repository.dart
│   ├── transactions/transaction_repository.dart
│   ├── transfers/transfer_repository.dart
│   ├── bills/bill_repository.dart
│   ├── exchange_rates/exchange_rate_repository.dart
│   ├── device_tokens/device_token_repository.dart
│   └── reports/                      # ⬜ belum dibuat — lihat fitur 10
│       └── report_repository.dart
│
└── presentation/                     # semua yang berhubungan dengan layar & state
    ├── repository_providers.dart     # bungkus semua Repository jadi Riverpod provider
    ├── auth/
    │   ├── providers/auth_providers.dart
    │   └── screens/                  # ⬜ belum dibuat — lihat fitur 1
    ├── theme/providers/theme_mode_provider.dart
    ├── dashboard/screens/dashboard_screen.dart
    ├── accounts/
    │   ├── providers/account_providers.dart
    │   └── screens/accounts_screen.dart
    ├── categories/
    │   ├── providers/category_providers.dart
    │   └── screens/                  # ⬜ belum dibuat — lihat fitur 4
    ├── transactions/
    │   ├── providers/transaction_providers.dart
    │   └── screens/                  # ⬜ belum dibuat — lihat fitur 5
    ├── transfers/
    │   ├── providers/transfer_providers.dart
    │   └── screens/                  # ⬜ belum dibuat — lihat fitur 6
    ├── exchange_rates/
    │   ├── providers/exchange_rate_providers.dart
    │   └── screens/                  # ⬜ belum dibuat — lihat fitur 7
    ├── bills/
    │   ├── providers/bill_providers.dart
    │   └── screens/bills_screen.dart
    ├── reports/                      # ⬜ belum dibuat — lihat fitur 10
    ├── settings/                     # ⬜ belum dibuat — lihat fitur 11
    └── shell/main_shell.dart         # bottom nav, menyatukan semua screen
```

### Penjelasan tiap folder

**`core/`** — hal yang dipakai bersama oleh seluruh fitur, tidak
spesifik ke satu tabel/domain manapun.
- `config/` — koneksi ke layanan eksternal (Supabase) dan autentikasi.
  Ini beda dari `data/` karena isinya infrastruktur dasar yang
  *digunakan oleh* semua repository, bukan repository untuk satu
  tabel tertentu.
- `theme/` — warna, gaya visual (glassmorphism), dan `ThemeData`.
  Dipisah dari `presentation/` karena tema bukan "layar", tapi bahan
  baku visual yang dipakai lintas layar.

**`domain/entities/`** — bentuk data (model) yang murni Dart, tidak
tahu-menahu soal Supabase. Satu file per tabel/VIEW di database, biar
gampang dicari dan kalau skema tabel berubah, cukup 1 file yang
disentuh. Wajib pakai `abstract class` (ketentuan Freezed 3.x).

**`data/`** — satu-satunya lapisan yang mengandung `supabase.from(...)`
atau `supabase.rpc(...)`. Tiap file bertanggung jawab atas satu tabel
(atau gabungan tabel yang selalu dipakai bersamaan, seperti
`bills` + `bill_payments` di `bill_repository.dart`). Kalau nanti
pindah backend, folder inilah yang berubah — `domain/` dan
`presentation/` tetap utuh.

**`presentation/`** — dibagi per fitur (`accounts/`, `bills/`, dst),
dan tiap fitur punya subfolder:
- `providers/` — jembatan Riverpod (`@riverpod` functions) yang
  di-`watch` oleh widget. Juga berisi fungsi aksi (create, delete,
  payBill) yang memanggil repository lalu `ref.invalidate(...)` supaya
  UI ter-refresh otomatis.
- `screens/` — widget yang dilihat user. Tidak pernah memanggil
  Supabase langsung, hanya `ref.watch`/`ref.read` ke provider.

`repository_providers.dart` sengaja **ditaruh langsung di
`presentation/`** (bukan per-fitur) karena isinya cuma "bungkus semua
Repository jadi provider" tanpa logic tambahan — satu file kecil yang
jadi titik sambung antara `data/` dan seluruh fitur di `presentation/`.

`shell/main_shell.dart` juga di level atas `presentation/` karena
fungsinya menyatukan (bukan milik) fitur tertentu — dia yang mengatur
bottom navigation dan `IndexedStack` antar `DashboardScreen`,
`AccountsScreen`, `BillsScreen`, dst.

---

## 1. Autentikasi ⬜

**Sudah tersedia:** `AuthRepository` (`core/config/auth_repository.dart`) —
signUp, signIn, signOut, authStateChanges, isLoggedIn.

**Belum ada:** UI login/signup, dan pengalihan otomatis (belum login →
layar Login; sudah login → `MainShell`).

**Prompt:**
> Buatkan layar Login dan Signup bergaya glassmorphism hijau (konsisten
> dengan GlassCard dan AppBackground yang sudah ada). Form: email,
> password, tombol submit, link pindah antara mode login/signup. Setelah
> berhasil, arahkan ke MainShell. Buat juga widget `AuthGate` yang
> `ref.watch(authStateProvider)` — kalau belum login tampilkan
> Login/Signup, kalau sudah login tampilkan MainShell — lalu pasang
> AuthGate sebagai `home:` di MaterialApp menggantikan MainShell
> langsung.

---

## 2. Dashboard 🟡

**Sudah tersedia:** `DashboardScreen` — total saldo (dari
`account_balances`), breakdown per tipe akun, 4 tombol aksi cepat
(belum berfungsi), kartu tagihan terdekat (dari `bills`), daftar
aktivitas terbaru (dari `transactions`).

**Belum ada:** navigasi dari tombol aksi cepat, dan total saldo belum
dikonversi ke satu mata uang (saat ini menjumlah `balance` mentah lintas
IDR & MYR tanpa konversi — akan salah kalau kamu punya akun campuran).

**Prompt:**
> Perbaiki `_TotalBalanceSection` di DashboardScreen supaya memakai
> `net_worth_summary` (via provider baru `netWorthProvider` yang
> memanggil VIEW tersebut) alih-alih menjumlah `account_balances`
> mentah, supaya saldo MYR ikut terkonversi ke IDR dengan benar.
> Sambungkan 4 tombol aksi (tambah, transfer, tagihan, konversi) supaya
> masing-masing membuka layar terkait (lihat fitur 3, 5, 6, 7 di bawah).

---

## 3. Manajemen Akun (Sumber Dana) 🟡

**Database:** tabel `accounts`, VIEW `account_balances`.
**Sudah tersedia:** `AccountRepository`, `account_providers.dart`
(list, balances, create, invalidate otomatis), `AccountsScreen` (list
tampilan).

**Belum ada:** form tambah akun, aksi edit/nonaktifkan akun dari UI
(repository `deactivate()` sudah ada, tinggal dipanggil dari tombol).

**Prompt:**
> Buatkan layar "Tambah Akun" (bottom sheet atau halaman penuh, gaya
> glass yang sama) dengan field: nama, tipe (dropdown bank/ewallet/
> cash), mata uang (dropdown IDR/MYR). Panggil `createAccount()` dari
> `account_providers.dart` saat submit. Tambahkan juga tombol
> "nonaktifkan" per akun di `AccountsScreen` yang memanggil
> `AccountRepository.deactivate()`, dengan dialog konfirmasi sebelum
> dieksekusi.

---

## 4. Kategori Transaksi ⬜

**Database:** tabel `categories`.
**Sudah tersedia:** `CategoryRepository`, `category_providers.dart`
(getAll, getByType, create).

**Belum ada:** UI sama sekali — belum ada layar untuk melihat atau
menambah kategori.

**Prompt:**
> Buatkan layar "Kelola Kategori" dengan dua tab (Pemasukan/
> Pengeluaran), masing-masing menampilkan grid kategori
> (`categoriesByTypeProvider`) dengan ikon dan nama, plus tombol tambah
> kategori baru (nama + pilih ikon dari daftar Tabler/Material icon
> tetap). Layar ini akan dipakai sebagai picker saat mengisi kategori
> di form transaksi (fitur 5).

---

## 5. Catat Transaksi (Uang Masuk/Keluar) 🟡

**Database:** tabel `transactions`. Trigger `fill_amount_idr` mengisi
otomatis kolom `amount_idr` berdasarkan kurs terbaru di `exchange_rates`
— **jangan** mengisi `amount_idr` manual dari app.

**Sudah tersedia:** `TransactionRepository`, `transaction_providers.dart`
(getAll, getByAccount, create, delete + auto-invalidate saldo akun).

**Belum ada:** form input transaksi, layar daftar transaksi lengkap
(dengan filter), dan konfirmasi hapus.

**Prompt:**
> Buatkan layar "Tambah Transaksi": toggle Pemasukan/Pengeluaran,
> dropdown akun (dari `accountsProvider`), dropdown kategori (filter
> sesuai tipe yang dipilih, dari `categoriesByTypeProvider`), input
> nominal, input deskripsi (opsional), date picker (default hari ini).
> Submit memanggil `createTransaction()`. Buatkan juga layar
> "Semua Transaksi" — daftar penuh dari `transactionsProvider`,
> dikelompokkan per tanggal, dengan swipe-to-delete yang memanggil
> `deleteTransaction()` setelah konfirmasi.

---

## 6. Transfer Antar Akun ⬜

**Database:** tabel `transfers`. Constraint `different_accounts`
mencegah transfer ke akun yang sama.

**Sudah tersedia:** `TransferRepository`, `transfer_providers.dart`
(getAll, create + auto-invalidate saldo akun).

**Belum ada:** UI sama sekali.

**Prompt:**
> Buatkan layar "Transfer": dropdown akun asal, dropdown akun tujuan
> (exclude akun yang sama dengan asal), input nominal asal. Kalau mata
> uang asal dan tujuan berbeda, tampilkan input kurs manual (atau ambil
> otomatis dari `latestRateProvider` sebagai default yang bisa
> di-edit) dan hitung otomatis nominal tujuan = nominal asal × kurs.
> Kalau mata uang sama, nominal tujuan = nominal asal (kurs = 1).
> Submit memanggil `createTransfer()`.

---

## 7. Konversi Mata Uang (Wise/Flip) ⬜

**Database:** tabel `exchange_rates` (cache kurs, kolom `source`
dibatasi ke 'wise' | 'flip' | 'manual').

**Sudah tersedia:** `ExchangeRateRepository` (getLatestRate, convert),
`exchange_rate_providers.dart`.

**Belum ada — dan ini PENTING dipahami:** app Flutter **tidak pernah**
memanggil API Wise/Flip langsung (supaya API key tidak tertanam di
kode client). Yang perlu dibuat adalah Edge Function di sisi Supabase
yang fetch dari Wise/Flip lalu insert ke `exchange_rates` — app hanya
membaca hasil cache-nya.

**Prompt (bagian server, dikerjakan di Supabase, bukan Flutter):**
> Buatkan Supabase Edge Function `fetch-exchange-rates` yang memanggil
> API publik Wise (`https://api.wise.com/v1/rates`) untuk pasangan
> MYR→IDR dan IDR→MYR, lalu insert hasilnya ke tabel `exchange_rates`
> dengan `source = 'wise'`. Jadwalkan lewat pg_cron setiap beberapa jam
> sekali (kurs tidak perlu real-time untuk kebutuhan pribadi).

**Prompt (bagian app, Flutter):**
> Buatkan layar "Konversi Mata Uang": input nominal, dropdown mata uang
> asal & tujuan, tampilkan hasil dari `convertedAmountProvider` secara
> live saat nominal diketik (gunakan debounce ±400ms). Tampilkan juga
> "kurs terakhir diperbarui: [waktu]" dari `fetchedAt` pada
> `latestRateProvider`, dan pesan jelas kalau kurs belum tersedia di
> cache ("kurs belum tersedia, coba lagi nanti").

---

## 8. Tagihan Bulanan & Reminder 🟡

**Database:** tabel `bills` + `bill_payments`. Function
`generate_monthly_bill_payments()` (buat baris bulan berjalan, dipanggil
cron awal bulan), `mark_overdue_bills()` (tandai telat, dipanggil cron
harian), `bills_due_for_reminder()` (dipanggil dari Edge Function
reminder harian), `pay_bill()` (RPC atomik: insert transaksi + tandai
lunas sekaligus).

**Sudah tersedia:** `BillRepository` (getAll, create,
getCurrentMonthPayments, payBill via RPC), `bill_providers.dart`,
`BillsScreen` (hero card + list, belum ada aksi bayar).

**Belum ada:** form tambah tagihan, tombol "Tandai Lunas" yang memanggil
`payBill()`, indikator status (pending/paid/overdue) per tagihan di UI.

**Prompt:**
> Buatkan layar "Tambah Tagihan": nama, nominal, mata uang, tanggal
> jatuh tempo (dropdown 1-31), dropdown akun default untuk pembayaran,
> reminder H- berapa hari (default 3). Panggil `createBill()`. Di
> `BillsScreen`, gabungkan data `billsProvider` dengan
> `currentMonthBillPaymentsProvider` untuk menampilkan status badge
> (pending/paid/overdue) per tagihan, dan tombol "Tandai Lunas" yang
> membuka dialog konfirmasi nominal + pilih akun, lalu memanggil
> `payBill()` dari `bill_providers.dart`.

---

## 9. Push Notification Reminder Tagihan ⬜

**Database:** tabel `device_tokens`, function `bills_due_for_reminder()`.
**Sudah tersedia:** `DeviceTokenRepository` (registerToken, removeToken).

**Belum ada:** integrasi Firebase Messaging di Flutter, dan Edge
Function pengirim notifikasi di sisi server.

**Prompt (bagian app, Flutter):**
> Integrasikan `firebase_messaging` (sudah ada di pubspec). Saat app
> start dan user sudah login, minta izin notifikasi, ambil FCM token,
> panggil `DeviceTokenRepository.registerToken()` dengan platform
> sesuai (`android`/`ios`/`web`). Dengarkan
> `FirebaseMessaging.onTokenRefresh` untuk re-register kalau token
> berubah. Saat `signOut()` dipanggil di `AuthRepository`, panggil juga
> `removeToken()` untuk device token aktif.

**Prompt (bagian server, Supabase Edge Function):**
> Buatkan Edge Function `send-bill-reminders` yang memanggil RPC
> `bills_due_for_reminder()`, untuk tiap hasil ambil `device_tokens`
> milik `user_id` terkait, lalu kirim push notification via Firebase
> Cloud Messaging (judul: nama tagihan, isi: nominal + berapa hari
> lagi). Jadwalkan via pg_cron setiap hari jam 08:00 waktu lokal.

---

## 10. Laporan / Insight Pengeluaran ⬜

**Database:** VIEW `monthly_expense_by_category` — sudah dibuat tapi
**belum ada repository maupun provider untuk ini di Flutter.**

**Prompt:**
> Buatkan `data/reports/report_repository.dart` dengan method
> `getMonthlyExpenseByCategory({DateTime? month})` yang query VIEW
> `monthly_expense_by_category`. Buatkan provider terkait, lalu layar
> "Laporan" dengan pie chart atau bar chart (pakai `fl_chart` atau
> `syncfusion_flutter_charts` — perlu ditambahkan ke pubspec)
> menampilkan proporsi pengeluaran per kategori bulan berjalan, dengan
> selector untuk pindah bulan.

---

## 11. Pengaturan (Settings) ⬜

**Sudah tersedia:** `AppThemeMode` provider (toggle light/dark, sudah
dipasang tombolnya di Dashboard).

**Belum ada:** layar Settings terpusat.

**Prompt:**
> Buatkan layar "Pengaturan": toggle dark/light mode (pakai
> `appThemeModeProvider` yang sudah ada), tombol "Kelola Kategori"
> (buka fitur 4), tombol "Logout" (panggil `AuthRepository.signOut()`
> lalu `removeToken()` untuk device saat ini), dan info versi aplikasi.
> Tambahkan sebagai tab ke-4 di `MainShell`.

---

## Ringkasan status keseluruhan

| # | Fitur | Database | Repository | Provider | UI |
|---|---|---|---|---|---|
| 1 | Autentikasi | auth.users (bawaan Supabase) | ✅ | 🟡 (auth state ada, belum ada action gate) | ⬜ |
| 2 | Dashboard | account_balances, net_worth_summary | ✅ | ✅ | 🟡 |
| 3 | Akun | accounts, account_balances | ✅ | ✅ | 🟡 |
| 4 | Kategori | categories | ✅ | ✅ | ⬜ |
| 5 | Transaksi | transactions | ✅ | ✅ | ⬜ |
| 6 | Transfer | transfers | ✅ | ✅ | ⬜ |
| 7 | Konversi mata uang | exchange_rates | ✅ | ✅ | ⬜ (+ Edge Function belum ada) |
| 8 | Tagihan | bills, bill_payments | ✅ | ✅ | 🟡 |
| 9 | Push notification | device_tokens | ✅ | — | ⬜ (+ Edge Function belum ada) |
| 10 | Laporan | monthly_expense_by_category | ⬜ | ⬜ | ⬜ |
| 11 | Pengaturan | — | — | ✅ (theme saja) | ⬜ |

**Rekomendasi urutan pengerjaan** (supaya bisa dites end-to-end tiap
tahap, sesuai kebiasaanmu menguji satu per satu): Autentikasi (1) →
Transaksi (5) + Kategori (4) → Akun lengkap (3) → Transfer (6) →
Tagihan lengkap (8) → Laporan (10) → Konversi mata uang (7) → Push
notification (9) → Pengaturan (11).

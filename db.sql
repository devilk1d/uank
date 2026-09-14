-- =========================================================
-- SKEMA DATABASE: APLIKASI MANAJEMEN KEUANGAN
-- Target: Supabase (PostgreSQL)
-- Cara pakai: copy-paste seluruh file ini ke Supabase SQL Editor, lalu Run
-- =========================================================


-- =========================================================
-- 1. EXTENSIONS
-- =========================================================
create extension if not exists "pgcrypto"; -- buat gen_random_uuid()


-- =========================================================
-- 2. TABEL UTAMA
-- =========================================================

-- --- Sumber Uang (akun: bank, e-wallet, cash) ---
create table accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  name text not null,                          -- "Bank Maybank", "TNG Wallet"
  type text not null check (type in ('bank', 'ewallet', 'cash')),
  currency text not null check (currency in ('IDR', 'MYR')),
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- --- Kategori transaksi ---
create table categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  name text not null,
  type text not null check (type in ('income', 'expense')),
  icon text,                                   -- opsional: nama icon buat UI
  created_at timestamptz default now()
);

-- --- Transaksi (uang masuk & keluar, digabung 1 tabel) ---
create table transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  account_id uuid references accounts not null,
  category_id uuid references categories,
  type text not null check (type in ('income', 'expense')),
  amount numeric(15,2) not null check (amount > 0),
  amount_idr numeric(15,2),                    -- setara IDR, diisi otomatis via trigger
  description text,
  transaction_date date not null default current_date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- --- Transfer antar akun (termasuk beda currency) ---
create table transfers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  from_account_id uuid references accounts not null,
  to_account_id uuid references accounts not null,
  amount_from numeric(15,2) not null check (amount_from > 0),
  amount_to numeric(15,2) not null check (amount_to > 0),
  exchange_rate numeric(15,6) not null,
  transfer_date date not null default current_date,
  notes text,
  created_at timestamptz default now(),
  constraint different_accounts check (from_account_id <> to_account_id)
);

-- --- Tagihan bulanan (aturan/template tagihan) ---
create table bills (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  name text not null,                          -- "Listrik", "Internet"
  amount numeric(15,2) not null check (amount > 0),
  currency text not null check (currency in ('IDR', 'MYR')),
  due_day int not null check (due_day between 1 and 31),
  account_id uuid references accounts,
  reminder_days_before int default 3,          -- H-berapa mulai diingatkan
  is_active boolean default true,
  created_at timestamptz default now()
);

-- --- Histori pembayaran tagihan per bulan ---
create table bill_payments (
  id uuid primary key default gen_random_uuid(),
  bill_id uuid references bills not null,
  user_id uuid references auth.users not null,
  period_month date not null,                  -- selalu tanggal 1, misal '2026-09-01'
  amount_paid numeric(15,2),
  paid_date date,
  status text not null default 'pending' check (status in ('pending', 'paid', 'overdue')),
  transaction_id uuid references transactions, -- link ke transaksi expense kalau sudah dibayar
  created_at timestamptz default now(),
  unique (bill_id, period_month)                -- 1 tagihan cuma 1 entry per bulan
);

-- --- Cache kurs mata uang (dari Wise/Flip) ---
create table exchange_rates (
  id uuid primary key default gen_random_uuid(),
  from_currency text not null,
  to_currency text not null,
  rate numeric(15,6) not null,
  source text not null check (source in ('wise', 'flip', 'manual')),
  fetched_at timestamptz default now()
);

-- --- Device token buat push notification (FCM) ---
create table device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  fcm_token text not null unique,
  platform text check (platform in ('android', 'ios', 'web')),
  created_at timestamptz default now()
);


-- =========================================================
-- 3. INDEX (biar query cepat walau data sudah ribuan baris)
-- =========================================================
create index idx_transactions_user_date on transactions (user_id, transaction_date desc);
create index idx_transactions_account on transactions (account_id);
create index idx_transfers_accounts on transfers (from_account_id, to_account_id);
create index idx_bill_payments_period on bill_payments (period_month, status);
create index idx_exchange_rates_lookup on exchange_rates (from_currency, to_currency, fetched_at desc);


-- =========================================================
-- 4. FUNCTION + TRIGGER: auto-update `updated_at`
-- =========================================================
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_accounts_updated_at
  before update on accounts
  for each row execute function set_updated_at();

create trigger trg_transactions_updated_at
  before update on transactions
  for each row execute function set_updated_at();


-- =========================================================
-- 5. FUNCTION + TRIGGER: auto-isi amount_idr saat transaksi dibuat
-- Ini yang bikin dashboard "total kekayaan dalam IDR" gak perlu
-- dihitung manual di frontend tiap kali.
-- =========================================================
create or replace function fill_amount_idr()
returns trigger as $$
declare
  acc_currency text;
  latest_rate numeric;
begin
  select currency into acc_currency from accounts where id = new.account_id;

  if acc_currency = 'IDR' then
    new.amount_idr := new.amount;
  else
    -- ambil kurs terbaru MYR->IDR yang sudah di-cache
    select rate into latest_rate
    from exchange_rates
    where from_currency = acc_currency and to_currency = 'IDR'
    order by fetched_at desc
    limit 1;

    if latest_rate is null then
      -- fallback: kalau belum ada kurs di-cache, biarkan null,
      -- nanti bisa di-backfill lewat job terpisah
      new.amount_idr := null;
    else
      new.amount_idr := new.amount * latest_rate;
    end if;
  end if;

  return new;
end;
$$ language plpgsql;

create trigger trg_fill_amount_idr
  before insert on transactions
  for each row execute function fill_amount_idr();


-- =========================================================
-- 6. VIEW: saldo tiap akun (real-time, tanpa perlu disimpan manual)
-- =========================================================
create view account_balances as
select
  a.id as account_id,
  a.user_id,
  a.name,
  a.type,
  a.currency,
  coalesce(tx.net, 0)
    + coalesce(transfer_in.total, 0)
    - coalesce(transfer_out.total, 0) as balance
from accounts a
left join (
  select account_id,
         sum(case when type = 'income' then amount else -amount end) as net
  from transactions
  group by account_id
) tx on tx.account_id = a.id
left join (
  select to_account_id, sum(amount_to) as total
  from transfers
  group by to_account_id
) transfer_in on transfer_in.to_account_id = a.id
left join (
  select from_account_id, sum(amount_from) as total
  from transfers
  group by from_account_id
) transfer_out on transfer_out.from_account_id = a.id
where a.is_active = true;


-- =========================================================
-- 7. VIEW: ringkasan kekayaan total dalam IDR (buat Dashboard)
-- Kurs MYR->IDR terbaru diambil sekali (bukan per baris) biar efisien,
-- dan tetap benar walau user cuma punya akun IDR (tidak butuh kurs sama sekali).
-- =========================================================
create view net_worth_summary as
with latest_rate as (
  select rate from exchange_rates
  where from_currency = 'MYR' and to_currency = 'IDR'
  order by fetched_at desc limit 1
)
select
  ab.user_id,
  sum(
    case when ab.currency = 'IDR' then ab.balance
         else ab.balance * (select rate from latest_rate)
    end
  ) as total_idr
from account_balances ab
group by ab.user_id;


-- =========================================================
-- 8. VIEW: pengeluaran per kategori bulan berjalan (buat chart/report)
-- =========================================================
create view monthly_expense_by_category as
select
  t.user_id,
  date_trunc('month', t.transaction_date) as month,
  c.name as category_name,
  sum(t.amount_idr) as total_idr
from transactions t
join categories c on c.id = t.category_id
where t.type = 'expense'
group by t.user_id, date_trunc('month', t.transaction_date), c.name;


-- =========================================================
-- 9. FUNCTION: generate bill_payments otomatis tiap bulan
-- Dipanggil oleh Edge Function / pg_cron tiap awal bulan.
-- Tanpa ini, kamu harus insert manual tiap bulan buat tiap tagihan.
-- =========================================================
create or replace function generate_monthly_bill_payments()
returns void as $$
begin
  insert into bill_payments (bill_id, user_id, period_month, status)
  select
    b.id,
    b.user_id,
    date_trunc('month', current_date)::date,
    'pending'
  from bills b
  where b.is_active = true
  on conflict (bill_id, period_month) do nothing;
end;
$$ language plpgsql security definer;


-- =========================================================
-- 10. FUNCTION: tandai bill_payments jadi 'overdue' kalau lewat due_day
-- Dipanggil harian oleh Edge Function / pg_cron.
-- =========================================================
create or replace function mark_overdue_bills()
returns void as $$
begin
  update bill_payments bp
  set status = 'overdue'
  from bills b
  where bp.bill_id = b.id
    and bp.status = 'pending'
    and extract(day from current_date) > b.due_day
    and date_trunc('month', current_date)::date = bp.period_month;
end;
$$ language plpgsql security definer;


-- =========================================================
-- 11. FUNCTION: cari tagihan yang perlu di-reminder hari ini
-- Dipanggil oleh Edge Function harian, hasilnya dipakai buat
-- kirim push notification lewat FCM.
-- =========================================================
create or replace function bills_due_for_reminder()
returns table (
  bill_id uuid,
  user_id uuid,
  bill_name text,
  amount numeric,
  currency text,
  due_day int,
  days_until_due int
) as $$
begin
  return query
  select
    b.id,
    b.user_id,
    b.name,
    b.amount,
    b.currency,
    b.due_day,
    (b.due_day - extract(day from current_date)::int) as days_until_due
  from bills b
  join bill_payments bp on bp.bill_id = b.id
    and bp.period_month = date_trunc('month', current_date)::date
  where b.is_active = true
    and bp.status = 'pending'
    and (b.due_day - extract(day from current_date)::int) between 0 and b.reminder_days_before;
end;
$$ language plpgsql security definer;


-- =========================================================
-- 12. FUNCTION: catat pembayaran tagihan sekaligus bikin transaksi expense
-- Ini yang dipanggil dari app saat user klik "Tandai Sudah Bayar".
-- Menjaga konsistensi: sekali klik, 2 tabel ke-update bareng (atomic).
-- =========================================================
create or replace function pay_bill(
  p_bill_id uuid,
  p_account_id uuid,
  p_amount numeric,
  p_category_id uuid default null
)
returns uuid as $$
declare
  v_user_id uuid;
  v_period date;
  v_tx_id uuid;
begin
  select user_id into v_user_id from bills where id = p_bill_id;
  v_period := date_trunc('month', current_date)::date;

  insert into transactions (user_id, account_id, category_id, type, amount, description, transaction_date)
  values (v_user_id, p_account_id, p_category_id, 'expense', p_amount,
          'Pembayaran tagihan (auto)', current_date)
  returning id into v_tx_id;

  update bill_payments
  set status = 'paid',
      amount_paid = p_amount,
      paid_date = current_date,
      transaction_id = v_tx_id
  where bill_id = p_bill_id and period_month = v_period;

  return v_tx_id;
end;
$$ language plpgsql security definer;


-- =========================================================
-- 13. ROW LEVEL SECURITY (RLS)
-- Wajib diaktifkan supaya user A gak bisa baca/edit data user B,
-- meskipun akses lewat REST API auto-generate Supabase.
-- =========================================================
alter table accounts enable row level security;
alter table categories enable row level security;
alter table transactions enable row level security;
alter table transfers enable row level security;
alter table bills enable row level security;
alter table bill_payments enable row level security;
alter table device_tokens enable row level security;

create policy "Users manage own accounts" on accounts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users manage own categories" on categories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users manage own transactions" on transactions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users manage own transfers" on transfers
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users manage own bills" on bills
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users manage own bill_payments" on bill_payments
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users manage own device_tokens" on device_tokens
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- exchange_rates sengaja TIDAK di-RLS karena data global (bukan milik user tertentu),
-- tapi tetap dibatasi: hanya bisa dibaca, insert cuma lewat Edge Function (service role)
alter table exchange_rates enable row level security;
create policy "Anyone can read exchange rates" on exchange_rates
  for select using (true);


-- =========================================================
-- SELESAI
-- =========================================================
-- Ringkasan apa yang barusan dibuat:
-- - 8 tabel inti
-- - 5 index buat performa query
-- - 2 trigger otomatis (updated_at, amount_idr)
-- - 4 view siap pakai (saldo, net worth, expense per kategori)
-- - 5 function siap dipanggil dari Edge Function / app
-- - RLS di semua tabel biar data user aman

-- =========================================================
-- PATCH: auto-isi user_id dari user yang sedang login
-- Jalankan file ini di Supabase SQL Editor SETELAH schema.sql
-- =========================================================
--
-- Alasan: semua tabel punya kolom `user_id uuid ... not null` TANPA
-- default value. Kalau app tidak mengirim user_id secara eksplisit saat
-- insert (dan repository yang sudah dibuat memang tidak mengirimnya),
-- insert akan gagal dengan error "null value in column user_id".
--
-- Perbaikan ini membuat kolom user_id otomatis terisi dengan
-- auth.uid() (id user yang sedang login lewat Supabase Auth) kalau
-- app tidak mengirim nilainya sendiri. Ini juga sekaligus mengunci:
-- app tidak akan pernah bisa insert data atas nama user lain, karena
-- nilainya diambil dari sesi login saat itu, bukan dari input app.

alter table accounts alter column user_id set default auth.uid();
alter table categories alter column user_id set default auth.uid();
alter table transactions alter column user_id set default auth.uid();
alter table transfers alter column user_id set default auth.uid();
alter table bills alter column user_id set default auth.uid();
alter table bill_payments alter column user_id set default auth.uid();
alter table device_tokens alter column user_id set default auth.uid();
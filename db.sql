-- =========================================================
-- SKEMA DATABASE: APLIKASI MANAJEMEN KEUANGAN (UANK)
-- Target: Supabase (PostgreSQL 15+)
-- Cara pakai: Copy-paste seluruh file ini ke Supabase SQL Editor, lalu Run
-- =========================================================


-- =========================================================
-- 1. EXTENSIONS
-- =========================================================
create extension if not exists "pgcrypto"; -- buat gen_random_uuid()


-- =========================================================
-- 2. TABEL UTAMA
-- =========================================================

-- --- 1. Sumber Uang (Akun: Bank, E-Wallet, Cash) ---
create table if not exists accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  name text not null,                          -- "Bank BCA", "Maybank", "TNG Wallet"
  type text not null check (type in ('bank', 'ewallet', 'cash')),
  currency text not null check (currency in ('IDR', 'MYR')),
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- --- 2. Kategori Transaksi ---
create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  name text not null,
  type text not null check (type in ('income', 'expense')),
  icon text,                                   -- nama icon untuk UI (misal: 'restaurant', 'shopping_bag')
  created_at timestamptz default now()
);

-- --- 3. Transaksi (Uang Masuk & Keluar) ---
create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  account_id uuid references accounts not null,
  category_id uuid references categories,
  type text not null check (type in ('income', 'expense')),
  amount numeric(15,2) not null check (amount > 0),
  amount_idr numeric(15,2),                    -- setara IDR, diisi otomatis via trigger fill_amount_idr
  description text,
  transaction_date date not null default current_date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- --- 4. Transfer Antar Akun (Termasuk Beda Currency / Valas) ---
create table if not exists transfers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
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

-- --- 5. Tagihan Bulanan (Bills) ---
create table if not exists bills (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  name text not null,                          -- "Listrik", "Internet", "Sewa Apartemen"
  amount numeric(15,2) not null check (amount > 0),
  currency text not null check (currency in ('IDR', 'MYR')),
  due_day int not null check (due_day between 1 and 31),
  account_id uuid references accounts,
  reminder_days_before int default 3,          -- H-berapa mulai diingatkan
  is_active boolean default true,
  created_at timestamptz default now()
);

-- --- 6. Histori Pembayaran Tagihan Per Bulan ---
create table if not exists bill_payments (
  id uuid primary key default gen_random_uuid(),
  bill_id uuid references bills not null,
  user_id uuid references auth.users not null default auth.uid(),
  period_month date not null,                  -- selalu tanggal 1, misal '2026-09-01'
  amount_paid numeric(15,2),
  paid_date date,
  status text not null default 'pending' check (status in ('pending', 'paid', 'overdue')),
  transaction_id uuid references transactions, -- link ke transaksi expense jika sudah dibayar
  created_at timestamptz default now(),
  unique (bill_id, period_month)
);

-- --- 7. Target Menabung (Saving Goals) ---
create table if not exists saving_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  account_id uuid references accounts,
  name text not null,
  target_amount numeric(15,2) not null check (target_amount > 0),
  current_amount numeric(15,2) not null default 0 check (current_amount >= 0),
  currency text not null check (currency in ('IDR', 'MYR')),
  target_date date,
  icon text not null default 'savings',
  color text not null default '#CCFF00',
  is_completed boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- --- 8. Cache Kurs Mata Uang (Exchange Rates) ---
create table if not exists exchange_rates (
  id uuid primary key default gen_random_uuid(),
  from_currency text not null,
  to_currency text not null,
  rate numeric(15,6) not null,
  source text not null check (source in ('wise', 'flip', 'manual', 'api')),
  fetched_at timestamptz default now()
);

-- --- 9. Device Token Buat Push Notification (FCM) ---
create table if not exists device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null default auth.uid(),
  fcm_token text not null unique,
  platform text check (platform in ('android', 'ios', 'web')),
  created_at timestamptz default now()
);


-- =========================================================
-- 2.1 SAFE UPGRADES (Untuk Database yang Sudah Berisi Data)
-- Memastikan kolom baru & default terpasang tanpa merusak data
-- =========================================================
alter table accounts add column if not exists is_active boolean default true;
alter table accounts alter column user_id set default auth.uid();

alter table categories alter column user_id set default auth.uid();
alter table transactions alter column user_id set default auth.uid();
alter table transfers alter column user_id set default auth.uid();

alter table bills add column if not exists is_active boolean default true;
alter table bills alter column user_id set default auth.uid();

alter table bill_payments alter column user_id set default auth.uid();
alter table device_tokens alter column user_id set default auth.uid();


-- =========================================================
-- 3. INDEXES (Performa Query & JOIN Maksimal)
-- =========================================================

-- Accounts
create index if not exists idx_accounts_user_id on accounts (user_id);
create index if not exists idx_accounts_user_active on accounts (user_id, is_active);

-- Categories
create index if not exists idx_categories_user_type on categories (user_id, type);

-- Transactions
create index if not exists idx_transactions_user_date on transactions (user_id, transaction_date desc);
create index if not exists idx_transactions_account on transactions (account_id);
create index if not exists idx_transactions_category on transactions (category_id);
create index if not exists idx_transactions_user_type on transactions (user_id, type);

-- Transfers
create index if not exists idx_transfers_user_date on transfers (user_id, transfer_date desc);
create index if not exists idx_transfers_from_account on transfers (from_account_id);
create index if not exists idx_transfers_to_account on transfers (to_account_id);

-- Bills & Payments
create index if not exists idx_bills_user_active on bills (user_id, is_active);
create index if not exists idx_bills_account on bills (account_id);
create index if not exists idx_bill_payments_bill on bill_payments (bill_id);
create index if not exists idx_bill_payments_user on bill_payments (user_id);
create index if not exists idx_bill_payments_period_status on bill_payments (period_month, status);
create index if not exists idx_bill_payments_transaction on bill_payments (transaction_id);

-- Saving Goals
create index if not exists idx_saving_goals_user_completed on saving_goals (user_id, is_completed);
create index if not exists idx_saving_goals_account on saving_goals (account_id);

-- Exchange Rates
create index if not exists idx_exchange_rates_lookup on exchange_rates (from_currency, to_currency, fetched_at desc);


-- =========================================================
-- 4. FUNCTION + TRIGGER: Auto-Update `updated_at`
-- =========================================================
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_accounts_updated_at on accounts;
create trigger trg_accounts_updated_at
  before update on accounts
  for each row execute function set_updated_at();

drop trigger if exists trg_transactions_updated_at on transactions;
create trigger trg_transactions_updated_at
  before update on transactions
  for each row execute function set_updated_at();

drop trigger if exists trg_saving_goals_updated_at on saving_goals;
create trigger trg_saving_goals_updated_at
  before update on saving_goals
  for each row execute function set_updated_at();


-- =========================================================
-- 5. FUNCTION + TRIGGER: Auto-isi amount_idr
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
    -- Ambil kurs terbaru MYR -> IDR dari cache exchange_rates
    select rate into latest_rate
    from exchange_rates
    where from_currency = acc_currency and to_currency = 'IDR'
    order by fetched_at desc
    limit 1;

    if latest_rate is null then
      new.amount_idr := null;
    else
      new.amount_idr := new.amount * latest_rate;
    end if;
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_fill_amount_idr on transactions;
create trigger trg_fill_amount_idr
  before insert or update of amount, account_id on transactions
  for each row execute function fill_amount_idr();


-- =========================================================
-- 6. VIEWS (Dengan security_invoker = true)
-- =========================================================

-- Drop views lama agar tidak ada konflik struktur saat recreate
drop view if exists monthly_expense_by_category cascade;
drop view if exists net_worth_summary cascade;
drop view if exists account_balances cascade;

-- --- 1. Saldo Real-Time Tiap Akun ---
create or replace view account_balances
with (security_invoker = true) as
select
  a.id as account_id,
  a.user_id,
  a.name,
  a.type,
  a.currency,
  coalesce(tx.net, 0)
    + coalesce(transfer_in.total, 0)
    - coalesce(transfer_out.total, 0) as balance,
  a.is_active
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
) transfer_out on transfer_out.from_account_id = a.id;


-- --- 2. Ringkasan Total Kekayaan (Net Worth) dalam IDR ---
create or replace view net_worth_summary
with (security_invoker = true) as
with latest_rate as (
  select rate from exchange_rates
  where from_currency = 'MYR' and to_currency = 'IDR'
  order by fetched_at desc limit 1
)
select
  ab.user_id,
  sum(
    case when ab.currency = 'IDR' then ab.balance
         else ab.balance * coalesce((select rate from latest_rate), 1.0)
    end
  ) as total_idr
from account_balances ab
where ab.is_active = true
group by ab.user_id;


-- --- 3. Pengeluaran Per Kategori Bulan Berjalan ---
create or replace view monthly_expense_by_category
with (security_invoker = true) as
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
-- 7. STORED FUNCTIONS
-- =========================================================

-- --- 1. Generate Tagihan Bulanan Otomatis ---
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


-- --- 2. Tandai Tagihan Overdue ---
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


-- --- 3. Ambil Tagihan yang Perlu Di-Reminder Hari Ini ---
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


-- --- 4. Pembayaran Tagihan Atomik (Pay Bill) ---
create or replace function pay_bill(
  p_bill_id uuid,
  p_account_id uuid,
  p_amount numeric,
  p_category_id uuid default null,
  p_period date default null,
  p_paid_date date default null
)
returns uuid as $$
declare
  v_user_id uuid;
  v_bill_name text;
  v_period date;
  v_paid_date date;
  v_tx_id uuid;
begin
  select user_id, name into v_user_id, v_bill_name from bills where id = p_bill_id;
  
  if p_period is not null then
    v_period := date_trunc('month', p_period)::date;
  else
    v_period := date_trunc('month', current_date)::date;
  end if;

  v_paid_date := coalesce(p_paid_date, current_date);

  insert into transactions (user_id, account_id, category_id, type, amount, description, transaction_date)
  values (v_user_id, p_account_id, p_category_id, 'expense', p_amount,
          'Pembayaran ' || coalesce(v_bill_name, 'Tagihan'), v_paid_date)
  returning id into v_tx_id;

  insert into bill_payments (bill_id, user_id, period_month, amount_paid, paid_date, status, transaction_id)
  values (p_bill_id, v_user_id, v_period, p_amount, v_paid_date, 'paid', v_tx_id)
  on conflict (bill_id, period_month)
  do update set
    status = 'paid',
    amount_paid = p_amount,
    paid_date = v_paid_date,
    transaction_id = v_tx_id;

  return v_tx_id;
end;
$$ language plpgsql security definer;


-- =========================================================
-- 8. ROW LEVEL SECURITY (RLS) BERPERFORMA TINGGI
-- Menggunakan subquery (select auth.uid()) & TO authenticated
-- =========================================================
alter table accounts enable row level security;
alter table categories enable row level security;
alter table transactions enable row level security;
alter table transfers enable row level security;
alter table bills enable row level security;
alter table bill_payments enable row level security;
alter table saving_goals enable row level security;
alter table device_tokens enable row level security;

-- Accounts
drop policy if exists "Users manage own accounts" on accounts;
create policy "Users manage own accounts" on accounts
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Categories
drop policy if exists "Users manage own categories" on categories;
create policy "Users manage own categories" on categories
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Transactions
drop policy if exists "Users manage own transactions" on transactions;
create policy "Users manage own transactions" on transactions
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Transfers
drop policy if exists "Users manage own transfers" on transfers;
create policy "Users manage own transfers" on transfers
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Bills
drop policy if exists "Users manage own bills" on bills;
create policy "Users manage own bills" on bills
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Bill Payments
drop policy if exists "Users manage own bill_payments" on bill_payments;
create policy "Users manage own bill_payments" on bill_payments
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Saving Goals
drop policy if exists "Users manage own saving_goals" on saving_goals;
create policy "Users manage own saving_goals" on saving_goals
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Device Tokens
drop policy if exists "Users manage own device_tokens" on device_tokens;
create policy "Users manage own device_tokens" on device_tokens
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Exchange Rates (Global Public Read)
alter table exchange_rates enable row level security;
drop policy if exists "Anyone can read exchange rates" on exchange_rates;
create policy "Anyone can read exchange rates" on exchange_rates
  for select using (true);
-- ============================================================
-- FISCAL AI - NEW TABLES: Bank Accounts, Friends, Shared Funds
-- Chạy trên Supabase Dashboard → SQL Editor
-- ⚠️ PHẢI chạy TOÀN BỘ file 1 lần (không tách từng đoạn)
-- ============================================================

-- ========== BƯỚC 1: TẠO TẤT CẢ BẢNG TRƯỚC ==========

-- 1. BANK ACCOUNTS
CREATE TABLE IF NOT EXISTS bank_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  bank_name TEXT NOT NULL,
  bank_code TEXT NOT NULL,
  account_number TEXT NOT NULL,
  account_name TEXT NOT NULL,
  is_verified BOOLEAN DEFAULT FALSE,
  wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. FRIENDSHIPS
CREATE TABLE IF NOT EXISTS friendships (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

-- 3. SHARED FUNDS
CREATE TABLE IF NOT EXISTS shared_funds (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  target_amount DOUBLE PRECISION DEFAULT 0,
  current_amount DOUBLE PRECISION DEFAULT 0,
  creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  deadline TIMESTAMPTZ,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. FUND MEMBERS
CREATE TABLE IF NOT EXISTS fund_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fund_id UUID REFERENCES shared_funds(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  contributed_amount DOUBLE PRECISION DEFAULT 0,
  role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(fund_id, user_id)
);

-- 5. FUND TRANSACTIONS
CREATE TABLE IF NOT EXISTS fund_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fund_id UUID REFERENCES shared_funds(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. FUND REMINDERS (lời nhắc góp quỹ)
CREATE TABLE IF NOT EXISTS fund_reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  fund_id UUID REFERENCES shared_funds(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  frequency TEXT NOT NULL CHECK (frequency IN ('weekly', 'monthly')),
  amount DOUBLE PRECISION NOT NULL,
  day_of_week INT,              -- 1-7 (Thứ 2 - CN) cho weekly
  day_of_month INT,             -- 1-28 cho monthly
  is_active BOOLEAN DEFAULT TRUE,
  next_remind_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(fund_id, user_id)
);

-- ========== BƯỚC 2: BẬT RLS ==========

ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_funds ENABLE ROW LEVEL SECURITY;
ALTER TABLE fund_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE fund_transactions ENABLE ROW LEVEL SECURITY;

-- ========== BƯỚC 3: TẠO POLICIES (sau khi TẤT CẢ bảng đã tồn tại) ==========

-- bank_accounts
CREATE POLICY "Users can manage own bank accounts"
  ON bank_accounts FOR ALL
  USING (auth.uid() = user_id);

-- friendships
CREATE POLICY "Users can view own friendships"
  ON friendships FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Users can insert friendships"
  ON friendships FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own friendships"
  ON friendships FOR UPDATE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Users can delete own friendships"
  ON friendships FOR DELETE
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- shared_funds (giờ fund_members đã tồn tại → OK)
CREATE POLICY "Fund members can view funds"
  ON shared_funds FOR SELECT
  USING (
    auth.uid() = creator_id
    OR auth.uid() IN (SELECT user_id FROM fund_members WHERE fund_id = id)
  );
CREATE POLICY "Creator can manage funds"
  ON shared_funds FOR ALL
  USING (auth.uid() = creator_id);

-- fund_members
CREATE POLICY "Members can view fund members"
  ON fund_members FOR SELECT
  USING (
    auth.uid() = user_id
    OR fund_id IN (SELECT id FROM shared_funds WHERE creator_id = auth.uid())
    OR fund_id IN (SELECT fund_id FROM fund_members fm WHERE fm.user_id = auth.uid())
  );
CREATE POLICY "Admin can manage members"
  ON fund_members FOR ALL
  USING (
    fund_id IN (SELECT id FROM shared_funds WHERE creator_id = auth.uid())
    OR auth.uid() = user_id
  );

-- fund_transactions
CREATE POLICY "Members can view fund transactions"
  ON fund_transactions FOR SELECT
  USING (
    fund_id IN (SELECT fund_id FROM fund_members WHERE user_id = auth.uid())
  );
CREATE POLICY "Members can insert fund transactions"
  ON fund_transactions FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND fund_id IN (SELECT fund_id FROM fund_members WHERE user_id = auth.uid())
  );

-- ========== BƯỚC 4: TRIGGER TỰ ĐỘNG CẬP NHẬT SỐ TIỀN ==========

CREATE OR REPLACE FUNCTION update_fund_amount()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE shared_funds
  SET current_amount = (
    SELECT COALESCE(SUM(amount), 0)
    FROM fund_transactions
    WHERE fund_id = NEW.fund_id
  )
  WHERE id = NEW.fund_id;

  UPDATE fund_members
  SET contributed_amount = (
    SELECT COALESCE(SUM(amount), 0)
    FROM fund_transactions
    WHERE fund_id = NEW.fund_id AND user_id = NEW.user_id
  )
  WHERE fund_id = NEW.fund_id AND user_id = NEW.user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_fund_amount
  AFTER INSERT ON fund_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_fund_amount();

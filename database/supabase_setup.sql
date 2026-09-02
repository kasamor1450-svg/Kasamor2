-- =========================================================================
-- Ù…Ø´Ø±ÙˆØ¹ Ø£Ø¨Ù†Ø§Ø¡ Ù…ØµØ·ÙÙ‰ Ø­Ø³Ù† Ø§Ù„Ø²Ø±Ø§Ø¹ÙŠ - Ø§Ù„Ù‚Ø¶Ø§Ø±ÙØŒ ÙƒØ³Ù…ÙˆØ± Ø§Ù„Ø´Ø±Ù‚ÙŠ
-- Ù…Ø®Ø·Ø· Ù‚Ø§Ø¹Ø¯Ø© Ø§Ù„Ø¨ÙŠØ§Ù†Ø§Øª Ø§Ù„Ø¹Ù„Ø§Ø¦Ù‚ÙŠØ© (Relational SQL Schema)
-- Ù…ØªÙˆØ§ÙÙ‚ Ù…Ø¹: PostgreSQL, MySQL, SQLite
-- =========================================================================

-- 1. Ø¬Ø¯ÙˆÙ„ Ù…Ø¹Ù„ÙˆÙ…Ø§Øª Ø§Ù„Ù…Ø²Ø±Ø¹Ø© ÙˆØ§Ù„Ù…Ø´Ø±ÙˆØ¹
CREATE TABLE IF NOT EXISTS farm_info (
    id VARCHAR(50) PRIMARY KEY DEFAULT 'main',
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    total_area_feddan DECIMAL(10, 2) NOT NULL DEFAULT 1450.00,
    season_start DATE NOT NULL,
    season_duration_months INT NOT NULL DEFAULT 6,
    currency VARCHAR(50) NOT NULL DEFAULT 'Ø¬Ù†ÙŠÙ‡ Ø³ÙˆØ¯Ø§Ù†ÙŠ',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù…ÙŠÙ† ÙˆØµÙ„Ø§Ø­ÙŠØ§Øª Ø§Ù„ÙˆØµÙˆÙ„ (Users & RBAC)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'accountant', 'supervisor', 'partner', 'viewer')),
    role_title VARCHAR(150),
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ø´Ø±ÙƒØ§Ø¡ ÙˆÙ‡ÙŠÙƒÙ„ Ø§Ù„Ù…Ù„ÙƒÙŠØ© (Partners & Shares)
CREATE TABLE IF NOT EXISTS partners (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    shares INT NOT NULL DEFAULT 1,
    total_shares INT NOT NULL DEFAULT 13,
    paid_capital DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    role VARCHAR(150),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Ø¬Ø¯ÙˆÙ„ Ø¯ÙØ¹Ø§Øª ÙˆØ¶Ø® Ø±Ø£Ø³ Ø§Ù„Ù…Ø§Ù„ (Capital Injections)
CREATE TABLE IF NOT EXISTS capital_injections (
    id VARCHAR(50) PRIMARY KEY,
    partner_id VARCHAR(50) REFERENCES partners(id) ON DELETE CASCADE,
    partner_name VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    payment_method VARCHAR(100) DEFAULT 'ØªØ­ÙˆÙŠÙ„ Ø¨Ù†ÙƒÙƒ',
    purpose VARCHAR(255),
    logged_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ù†Ù…Ø± ÙˆØ§Ù„Ù…Ù‚Ø·ÙˆØ¹ÙŠØ§Øª (Agricultural Plots)
CREATE TABLE IF NOT EXISTS plots (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    area_feddan DECIMAL(10, 2) NOT NULL,
    crop VARCHAR(100) NOT NULL,
    target_sowing_date DATE,
    prep_feddans DECIMAL(10, 2) DEFAULT 0.00,
    planted_feddans DECIMAL(10, 2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ø¹Ù…Ù„ÙŠØ§Øª Ø§Ù„Ù…ÙŠØ¯Ø§Ù†ÙŠØ© ÙÙŠ Ø§Ù„Ù†Ù…Ø± (Plot Operations)
CREATE TABLE IF NOT EXISTS plot_operations (
    id VARCHAR(50) PRIMARY KEY,
    plot_id VARCHAR(50) REFERENCES plots(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed')),
    driver VARCHAR(100),
    fuel_barrels DECIMAL(6, 2) DEFAULT 0.00,
    created_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Ø¬Ø¯ÙˆÙ„ Ø­Ø±ÙƒØ© ÙˆÙ…Ø®Ø²ÙˆÙ† Ø§Ù„ÙˆÙ‚ÙˆØ¯ (Fuel Transactions)
CREATE TABLE IF NOT EXISTS fuel_transactions (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('purchase', 'issue')),
    quantity DECIMAL(8, 2) NOT NULL,
    unit VARCHAR(50) DEFAULT 'Ø¨Ø±Ù…ÙŠÙ„',
    driver VARCHAR(100) DEFAULT '-',
    plot VARCHAR(100) DEFAULT '-',
    operation_name VARCHAR(255),
    logged_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ø£ØµÙ†Ø§Ù ÙˆØ§Ù„Ù…Ø®Ø²ÙˆÙ† Ø§Ù„Ø¹Ø§Ù… (Inventory Items)
CREATE TABLE IF NOT EXISTS inventory_items (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    purchased_qty DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    used_qty DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    remaining_qty DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    unit VARCHAR(50) NOT NULL,
    unit_price DECIMAL(15, 2) DEFAULT 0.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Ø¬Ø¯ÙˆÙ„ Ø­Ø±ÙƒØ§Øª Ø§Ù„Ù…Ø®Ø²ÙˆÙ† (ØµØ±Ù ÙˆØªÙˆØ±ÙŠØ¯)
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    item_id VARCHAR(50) REFERENCES inventory_items(id),
    item_name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('purchase', 'issue')),
    quantity DECIMAL(12, 2) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    unit_price DECIMAL(15, 2) DEFAULT 0.00,
    total_cost DECIMAL(15, 2) DEFAULT 0.00,
    plot VARCHAR(100),
    crop VARCHAR(100),
    receiver VARCHAR(150),
    logged_by VARCHAR(100),
    notes TEXT,
    sale_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ø­ØµØ§Ø¯ ÙˆØ§Ù„ØªØ´ÙˆÙŠÙ† Ø§Ù„Ù…ÙŠØ¯Ø§Ù†ÙŠ (Harvest Intakes)
CREATE TABLE IF NOT EXISTS harvest_intakes (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    plot VARCHAR(100) NOT NULL,
    crop VARCHAR(100) NOT NULL,
    bags DECIMAL(10, 2) NOT NULL,
    weight_tons DECIMAL(10, 2) NOT NULL,
    storage_location VARCHAR(200) NOT NULL,
    supervisor VARCHAR(100),
    quality_grade VARCHAR(100) DEFAULT 'Ø¯Ø±Ø¬Ø© Ø£ÙˆÙ„Ù‰',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Ø¬Ø¯ÙˆÙ„ Ù…Ø¨ÙŠØ¹Ø§Øª Ø§Ù„Ù…Ø­Ø§ØµÙŠÙ„ ÙˆØ§Ù„ØªØ³ÙˆÙŠÙ‚ (Crop Sales)
CREATE TABLE IF NOT EXISTS crop_sales (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    buyer_name VARCHAR(200) NOT NULL,
    crop VARCHAR(100) NOT NULL,
    bags DECIMAL(10, 2) NOT NULL,
    price_per_bag DECIMAL(15, 2) NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    paid_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    remaining_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    payment_method VARCHAR(100) DEFAULT 'ØªØ­ÙˆÙŠÙ„ Ø¨Ù†ÙƒÙƒ',
    delivery_location VARCHAR(200),
    status VARCHAR(50) DEFAULT 'Ù…ÙƒØªÙ…Ù„Ø© ÙˆÙ…Ø³ØªÙ„Ù…Ø©',
    logged_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. Ø¬Ø¯ÙˆÙ„ Ø£Ø³Ø·ÙˆÙ„ Ø§Ù„Ø¢Ù„ÙŠØ§Øª ÙˆØ§Ù„Ù…Ø¹Ø¯Ø§Øª (Machinery Fleet)
CREATE TABLE IF NOT EXISTS machinery (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    type VARCHAR(100) NOT NULL,
    plate VARCHAR(100),
    driver VARCHAR(100),
    status VARCHAR(100) DEFAULT 'Ø¬Ø§Ù‡Ø² Ù„Ù„Ø¹Ù…Ù„',
    hours_operated DECIMAL(8, 2) DEFAULT 0.00,
    oil_change_due_hours DECIMAL(8, 2) DEFAULT 0.00,
    fuel_tank_capacity DECIMAL(8, 2) DEFAULT 0.00,
    feddan_done DECIMAL(10, 2) DEFAULT 0.00,
    fuel_used_barrels DECIMAL(8, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ø¹Ù…Ø§Ù„Ø© ÙˆØ§Ù„Ù…Ø³ÙŠØ±Ø§Øª (Labor & Payroll)
CREATE TABLE IF NOT EXISTS labor (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    role VARCHAR(150) NOT NULL,
    worker_type VARCHAR(50) DEFAULT 'permanent' CHECK (worker_type IN ('permanent', 'temporary')),
    start_date DATE NOT NULL,
    end_date DATE,
    monthly_salary DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    days_worked INT DEFAULT 0,
    months_worked DECIMAL(6, 2) DEFAULT 0.00,
    deductions_amount DECIMAL(15, 2) DEFAULT 0.00,
    overtime DECIMAL(15, 2) DEFAULT 0.00,
    total_due DECIMAL(15, 2) DEFAULT 0.00,
    total_paid DECIMAL(15, 2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'paid' CHECK (status IN ('paid', 'partial', 'unpaid')),
    task VARCHAR(255),
    plot VARCHAR(100),
    crop VARCHAR(100),
    area_feddan DECIMAL(10, 2) DEFAULT 0.00,
    last_updated_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. Ø¬Ø¯ÙˆÙ„ Ø§Ù„Ù…ØµØ±ÙˆÙØ§Øª ÙˆØ§Ù„Ù‚ÙŠÙˆØ¯ Ø§Ù„Ù…Ø§Ù„ÙŠØ© Ø§Ù„Ù…Ø¹ØªÙ…Ø¯Ø© (Expenses Ledger)
CREATE TABLE IF NOT EXISTS expenses (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    category VARCHAR(100) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    plot VARCHAR(100) DEFAULT 'Ù…Ø´ØªØ±Ùƒ',
    crop VARCHAR(100) DEFAULT 'Ù…Ø´ØªØ±Ùƒ',
    op VARCHAR(255) NOT NULL,
    is_under_review BOOLEAN DEFAULT FALSE,
    created_by VARCHAR(100),
    modified_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 15. Ø¬Ø¯ÙˆÙ„ Ø³Ø¬Ù„ Ø§Ù„ØªØ¯Ù‚ÙŠÙ‚ ÙˆØ§Ù„Ù…Ø±Ø§Ù‚Ø¨Ø© (Audit Logs)
CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(50) PRIMARY KEY,
    timestamp VARCHAR(100) NOT NULL,
    user_id VARCHAR(50) REFERENCES users(id),
    user_name VARCHAR(150),
    user_role VARCHAR(150),
    action_type VARCHAR(100) NOT NULL,
    details TEXT NOT NULL,
    target VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ø§Ù„ÙÙ‡Ø§Ø±Ø³ Ù„ØªØ­Ø³ÙŠÙ† Ø³Ø±Ø¹Ø© Ø§Ù„Ø§Ø³ØªØ¹Ù„Ø§Ù… ÙˆØ§Ù„ØªÙ‚Ø§Ø±ÙŠØ± Ø§Ù„Ù…Ø§Ù„ÙŠØ©
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_plot ON expenses(plot);
CREATE INDEX IF NOT EXISTS idx_inventory_tx_date ON inventory_transactions(date);
CREATE INDEX IF NOT EXISTS idx_harvest_crop ON harvest_intakes(crop);
CREATE INDEX IF NOT EXISTS idx_sales_date ON crop_sales(date);
-- =========================================================================
-- Supabase Extensions, RLS, Realtime and Storage Configuration
-- =========================================================================

-- Enable RLS on all tables
ALTER TABLE farm_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE capital_injections ENABLE ROW LEVEL SECURITY;
ALTER TABLE plots ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE harvest_intakes ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE machinery ENABLE ROW LEVEL SECURITY;
ALTER TABLE labor ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Allow full access to authenticated / public farm team
DO $do$
DECLARE
  tbl text;
BEGIN
  FOR tbl IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "Allow full access to farm team" ON %I;', tbl);
    EXECUTE format('CREATE POLICY "Allow full access to farm team" ON %I FOR ALL USING (true) WITH CHECK (true);', tbl);
  END LOOP;
END $do$;

-- Enable Supabase Realtime for live multi-user synchronization
ALTER PUBLICATION supabase_realtime ADD TABLE 
  expenses,
  fuel_transactions,
  harvest_intakes,
  crop_sales,
  inventory_transactions,
  labor,
  plots,
  partners,
  capital_injections,
  audit_logs;

-- Supabase Storage bucket for invoice attachments
INSERT INTO storage.buckets (id, name, public) VALUES ('invoices', 'invoices', true) ON CONFLICT (id) DO NOTHING;
CREATE POLICY "Allow public uploads to invoices" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'invoices');
CREATE POLICY "Allow public read from invoices" ON storage.objects FOR SELECT USING (bucket_id = 'invoices');
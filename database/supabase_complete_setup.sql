-- =========================================================================
-- مشروع أبناء مصطفى حسن الزراعي - القضارف، كسمور الشرقي
-- مخطط قاعدة البيانات العلائقية (Relational SQL Schema)
-- متوافق 100% مع Supabase PostgreSQL
-- =========================================================================

-- تفعيل ملحق توليد المعرفات الفريدة
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================================================================
-- 1. إنشاء الجداول الـ 14 (Table Schemas)
-- =========================================================================

-- 1. جدول معلومات المزرعة والمشروع
CREATE TABLE IF NOT EXISTS farm_info (
    id VARCHAR(50) PRIMARY KEY DEFAULT 'main',
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    total_area_feddan DECIMAL(10, 2) NOT NULL DEFAULT 1450.00,
    season_start DATE NOT NULL,
    season_duration_months INT NOT NULL DEFAULT 6,
    currency VARCHAR(50) NOT NULL DEFAULT 'جنيه سوداني',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. جدول المستخدمين وصلاحيات الوصول (Users & Roles)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'accountant', 'supervisor', 'partner', 'viewer')),
    role_title VARCHAR(150),
    phone VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. جدول الشركاء وهيكل الملكية (Partners & Shares)
CREATE TABLE IF NOT EXISTS partners (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    shares INT NOT NULL DEFAULT 1,
    total_shares INT NOT NULL DEFAULT 13,
    paid_capital DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    role VARCHAR(150),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. جدول دفعات وضخ رأس المال (Capital Injections)
CREATE TABLE IF NOT EXISTS capital_injections (
    id VARCHAR(50) PRIMARY KEY,
    partner_id VARCHAR(50) REFERENCES partners(id) ON DELETE CASCADE,
    partner_name VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    payment_method VARCHAR(100) DEFAULT 'تحويل بنكك',
    purpose VARCHAR(255),
    logged_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. جدول النمر والمقطوعيات (Agricultural Plots)
CREATE TABLE IF NOT EXISTS plots (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    area_feddan DECIMAL(10, 2) NOT NULL,
    crop VARCHAR(100) NOT NULL,
    target_sowing_date DATE,
    prep_feddans DECIMAL(10, 2) DEFAULT 0.00,
    planted_feddans DECIMAL(10, 2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. جدول العمليات الميدانية في النمر (Plot Operations)
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
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. جدول حركة ومخزون الوقود (Fuel Transactions)
CREATE TABLE IF NOT EXISTS fuel_transactions (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('purchase', 'issue')),
    quantity DECIMAL(8, 2) NOT NULL,
    unit VARCHAR(50) DEFAULT 'برميل',
    driver VARCHAR(100) DEFAULT '-',
    plot VARCHAR(100) DEFAULT '-',
    operation_name VARCHAR(255),
    logged_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. جدول أصناف المخزون الزراعي (Inventory Items)
CREATE TABLE IF NOT EXISTS inventory_items (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    purchased_qty DECIMAL(10, 2) DEFAULT 0.00,
    used_qty DECIMAL(10, 2) DEFAULT 0.00,
    remaining_qty DECIMAL(10, 2) DEFAULT 0.00,
    unit VARCHAR(50) NOT NULL,
    unit_price DECIMAL(15, 2) DEFAULT 0.00,
    reorder_level DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. جدول حركة المستودع وصرف المواد (Inventory Transactions)
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    item_id VARCHAR(50) REFERENCES inventory_items(id) ON DELETE CASCADE,
    item_name VARCHAR(200) NOT NULL,
    category VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL CHECK (type IN ('purchase', 'issue', 'adjustment')),
    quantity DECIMAL(10, 2) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    unit_price DECIMAL(15, 2) DEFAULT 0.00,
    total_cost DECIMAL(15, 2) DEFAULT 0.00,
    plot VARCHAR(100) DEFAULT '-',
    crop VARCHAR(100) DEFAULT '-',
    receiver VARCHAR(100) DEFAULT '-',
    logged_by VARCHAR(100),
    notes TEXT,
    sale_id VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. جدول دخوليات وتشوين الحصاد (Harvest Intakes)
CREATE TABLE IF NOT EXISTS harvest_intakes (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    plot VARCHAR(100) NOT NULL,
    crop VARCHAR(100) NOT NULL,
    bags DECIMAL(10, 2) NOT NULL,
    weight_tons DECIMAL(10, 2) NOT NULL,
    storage_location VARCHAR(200) NOT NULL,
    supervisor VARCHAR(100) NOT NULL,
    quality_grade VARCHAR(50) DEFAULT 'درجة أولى',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. جدول مبيعات المحاصيل والتسويق (Crop Sales)
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
    payment_method VARCHAR(100) DEFAULT 'تحويل بنكك',
    delivery_location VARCHAR(200) DEFAULT 'صومعة القضارف',
    status VARCHAR(50) DEFAULT 'مكتملة ومستلمة',
    logged_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. جدول أسطول الآليات والمعدات (Machinery Fleet)
CREATE TABLE IF NOT EXISTS machinery (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    type VARCHAR(100) NOT NULL,
    plate VARCHAR(50) DEFAULT '-',
    driver VARCHAR(100) DEFAULT '-',
    status VARCHAR(100) DEFAULT 'جاهز للعمل',
    hours_operated DECIMAL(8, 2) DEFAULT 0.00,
    oil_change_due_hours DECIMAL(8, 2) DEFAULT 0.00,
    fuel_tank_capacity DECIMAL(8, 2) DEFAULT 0.00,
    feddan_done DECIMAL(10, 2) DEFAULT 0.00,
    fuel_used_barrels DECIMAL(8, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. جدول العمالة والمستحقات (Labor & Payroll)
CREATE TABLE IF NOT EXISTS labor (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    role VARCHAR(150) NOT NULL,
    worker_type VARCHAR(50) NOT NULL CHECK (worker_type IN ('permanent', 'temporary', 'contractor')),
    start_date DATE NOT NULL,
    end_date DATE,
    monthly_salary DECIMAL(15, 2) DEFAULT 0.00,
    days_worked INT DEFAULT 0,
    months_worked DECIMAL(4, 2) DEFAULT 0.00,
    deductions_amount DECIMAL(15, 2) DEFAULT 0.00,
    overtime DECIMAL(15, 2) DEFAULT 0.00,
    total_due DECIMAL(15, 2) DEFAULT 0.00,
    total_paid DECIMAL(15, 2) DEFAULT 0.00,
    status VARCHAR(50) DEFAULT 'partial' CHECK (status IN ('paid', 'partial', 'unpaid')),
    task VARCHAR(255),
    plot VARCHAR(100),
    crop VARCHAR(100),
    area_feddan DECIMAL(10, 2) DEFAULT 0.00,
    last_updated_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. جدول المصروفات والقيود المالية (Expenses & Financial Entries)
CREATE TABLE IF NOT EXISTS expenses (
    id VARCHAR(50) PRIMARY KEY,
    date DATE NOT NULL,
    category VARCHAR(100) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    plot VARCHAR(100) DEFAULT 'مشترك',
    crop VARCHAR(100) DEFAULT 'مشترك',
    op VARCHAR(255),
    is_under_review BOOLEAN DEFAULT FALSE,
    created_by VARCHAR(100),
    modified_by VARCHAR(100),
    notes TEXT,
    receipt_photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 15. جدول سجل العمليات والتدقيق (Audit Logs)
CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(50) PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    action VARCHAR(100) NOT NULL,
    details TEXT NOT NULL,
    section VARCHAR(100),
    user_name VARCHAR(100) NOT NULL
);

-- =========================================================================
-- 2. إعداد سياسات الأمان والحماية (Row Level Security - RLS)
-- =========================================================================

ALTER TABLE farm_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE capital_injections ENABLE ROW LEVEL SECURITY;
ALTER TABLE plots ENABLE ROW LEVEL SECURITY;
ALTER TABLE plot_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE harvest_intakes ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE machinery ENABLE ROW LEVEL SECURITY;
ALTER TABLE labor ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- سياسات الوصول العام الموثوق للتطبيق
DO $$
DECLARE
    tbl text;
BEGIN
    FOR tbl IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "Public Access %I" ON %I;', tbl, tbl);
        EXECUTE format('CREATE POLICY "Public Access %I" ON %I FOR ALL USING (true) WITH CHECK (true);', tbl, tbl);
    END LOOP;
END $$;

-- =========================================================================
-- 3. تفعيل البث اللحظي السحابي (Supabase Realtime)
-- =========================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;

DO $$
DECLARE
    t text;
    tbls text[] := ARRAY[
        'farm_info', 'partners', 'capital_injections', 'plots', 
        'plot_operations', 'fuel_transactions', 'inventory_items', 
        'inventory_transactions', 'harvest_intakes', 'crop_sales', 
        'machinery', 'labor', 'expenses', 'audit_logs'
    ];
BEGIN
    FOREACH t IN ARRAY tbls LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_rel pr
            JOIN pg_class pc ON pr.prrelid = pc.oid
            JOIN pg_publication p ON pr.prpubid = p.oid
            WHERE p.pubname = 'supabase_realtime' AND pc.relname = t
        ) THEN
            BEGIN
                EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE %I;', t);
            EXCEPTION WHEN OTHERS THEN
                -- تجاهل إذا كان الجدول مضافاً بالفعل
                NULL;
            END;
        END IF;
    END LOOP;
END $$;

-- =========================================================================
-- 4. إعداد حاوية تخزين الفواتير (Storage Bucket)
-- =========================================================================

INSERT INTO storage.buckets (id, name, public) 
VALUES ('invoices', 'invoices', true) 
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public View Invoices" ON storage.objects;
CREATE POLICY "Public View Invoices" ON storage.objects FOR SELECT USING (bucket_id = 'invoices');

DROP POLICY IF EXISTS "Public Upload Invoices" ON storage.objects;
CREATE POLICY "Public Upload Invoices" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'invoices');

DROP POLICY IF EXISTS "Public Update Invoices" ON storage.objects;
CREATE POLICY "Public Update Invoices" ON storage.objects FOR UPDATE USING (bucket_id = 'invoices');


-- =========================================================================
-- 5. Seed Data
-- =========================================================================

-- =========================================================================
-- PostgreSQL Database Seed - Kasamor Agricultural Project 2026
-- =========================================================================

INSERT INTO farm_info (id, name, location, total_area_feddan, season_start, season_duration_months, currency) VALUES ('main', 'مشروع أبناء مصطفى حسن الزراعي', 'القضارف، كسمور الشرقي', 1450, '2026-06-01', 6, 'جنيه سوداني') ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;
INSERT INTO users (id, name, username, password_hash, role, role_title, phone) VALUES ('u-1', 'محمد مصطفى', 'mohammed', '123', 'admin', 'المدير العام', '0912345678') ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, name, username, password_hash, role, role_title, phone) VALUES ('u-2', 'حسن مصطفى', 'hassan', '123', 'admin', 'المدير الإداري', '0923456789') ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, name, username, password_hash, role, role_title, phone) VALUES ('u-3', 'مصطفى الجعلي', 'mustafa', '123', 'accountant', 'المدير المالي', '0934567890') ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, name, username, password_hash, role, role_title, phone) VALUES ('u-4', 'عبدالقادر', 'abdelqader', '123', 'supervisor', 'الوكيل والمشرف العام', '0945678901') ON CONFLICT (id) DO NOTHING;
INSERT INTO users (id, name, username, password_hash, role, role_title, phone) VALUES ('u-5', 'أبوبكر مصطفى', 'abubakr', '123', 'partner', 'شريك في المشروع', '0956789012') ON CONFLICT (id) DO NOTHING;
INSERT INTO partners (id, name, full_name, shares, total_shares, paid_capital, role, notes) VALUES ('prt-1', 'عمرو', 'محمد مصطفى حسن', 2, 13, 77210462, 'شريك مؤسس', 'نسبة ربح ثابتة 2 من 13 (15.38%) • رأس المال مسترد بالكامل') ON CONFLICT (id) DO UPDATE SET paid_capital = EXCLUDED.paid_capital;
INSERT INTO partners (id, name, full_name, shares, total_shares, paid_capital, role, notes) VALUES ('prt-2', 'حسن', 'حسن مصطفى حسن', 2, 13, 10710462, 'شريك ومدير عام وميداني', 'نسبة ربح ثابتة 2 من 13 (15.38%) • رأس المال مسترد بالكامل') ON CONFLICT (id) DO UPDATE SET paid_capital = EXCLUDED.paid_capital;
INSERT INTO partners (id, name, full_name, shares, total_shares, paid_capital, role, notes) VALUES ('prt-3', 'ابوبكر', 'أبوبكر مصطفى حسن', 2, 13, 10710462, 'شريك مؤسس', 'نسبة ربح ثابتة 2 من 13 (15.38%) • رأس المال مسترد بالكامل') ON CONFLICT (id) DO UPDATE SET paid_capital = EXCLUDED.paid_capital;
INSERT INTO partners (id, name, full_name, shares, total_shares, paid_capital, role, notes) VALUES ('prt-4', 'هاجر', 'هاجر عوض السيد', 2, 13, 10710462, 'شريكة مؤسسة', 'نسبة ربح ثابتة 2 من 13 (15.38%) • رأس المال مسترد بالكامل') ON CONFLICT (id) DO UPDATE SET paid_capital = EXCLUDED.paid_capital;
INSERT INTO partners (id, name, full_name, shares, total_shares, paid_capital, role, notes) VALUES ('prt-5', 'الجعلي', 'مصطفى الجعلي', 1, 13, 5355231, 'شريك ومدير مالي', 'نسبة ربح ثابتة 1 من 13 (7.69%) • رأس المال مسترد بالكامل') ON CONFLICT (id) DO UPDATE SET paid_capital = EXCLUDED.paid_capital;
INSERT INTO partners (id, name, full_name, shares, total_shares, paid_capital, role, notes) VALUES ('prt-6', 'هديل', 'هديل مصطفى حسن', 1, 13, 5355231, 'شريكة مؤسسة', 'نسبة ربح ثابتة 1 من 13 (7.69%) • رأس المال مسترد بالكامل') ON CONFLICT (id) DO UPDATE SET paid_capital = EXCLUDED.paid_capital;
INSERT INTO partners (id, name, full_name, shares, total_shares, paid_capital, role, notes) VALUES ('prt-7', 'ايناس', 'إيناس مصطفى حسن', 1, 13, 5355231, 'شريكة مؤسسة', 'نسبة ربح ثابتة 1 من 13 (7.69%) • رأس المال مسترد بالكامل') ON CONFLICT (id) DO UPDATE SET paid_capital = EXCLUDED.paid_capital;
INSERT INTO partners (id, name, full_name, shares, total_shares, paid_capital, role, notes) VALUES ('prt-8', 'رزاز', 'رزاز مصطفى حسن', 1, 13, 5355231, 'شريكة مؤسسة', 'نسبة ربح ثابتة 1 من 13 (7.69%) • رأس المال مسترد بالكامل') ON CONFLICT (id) DO UPDATE SET paid_capital = EXCLUDED.paid_capital;
INSERT INTO partners (id, name, full_name, shares, total_shares, paid_capital, role, notes) VALUES ('prt-9', 'عناب', 'عناب مصطفى حسن', 1, 13, 5355231, 'شريكة مؤسسة', 'نسبة ربح ثابتة 1 من 13 (7.69%) • رأس المال مسترد بالكامل') ON CONFLICT (id) DO UPDATE SET paid_capital = EXCLUDED.paid_capital;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-1788086905527', 'prt-1', 'عمرو', '2026-07-01', 66500000, 'تحويل بنكك', 'استكمال راس مال تشغيلي', 'محمد مصطفى', '') ON CONFLICT (id) DO NOTHING;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-1', 'prt-1', 'محمد', '2026-06-15', 10710462, 'تحويل بنكك', 'رأس المال التأسيسي للموسم (2 سهم)', 'مصطفى الجعلي', 'الدفعة التأسيسية الأولى لتمويل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-2', 'prt-2', 'حسن', '2026-06-15', 10710462, 'تحويل بنكك', 'رأس المال التأسيسي للموسم (2 سهم)', 'مصطفى الجعلي', 'الدفعة التأسيسية الأولى لتمويل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-3', 'prt-3', 'ابوبكر', '2026-06-15', 10710462, 'تحويل بنكك', 'رأس المال التأسيسي للموسم (2 سهم)', 'مصطفى الجعلي', 'الدفعة التأسيسية الأولى لتمويل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-4', 'prt-4', 'هاجر', '2026-06-15', 10710462, 'تحويل بنكك', 'رأس المال التأسيسي للموسم (2 سهم)', 'مصطفى الجعلي', 'الدفعة التأسيسية الأولى لتمويل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-5', 'prt-5', 'الجعلي', '2026-06-15', 5355231, 'تحويل بنكك', 'رأس المال التأسيسي للموسم (سهم واحد)', 'مصطفى الجعلي', 'الدفعة التأسيسية الأولى لتمويل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-6', 'prt-6', 'هديل', '2026-06-15', 5355231, 'تحويل بنكك', 'رأس المال التأسيسي للموسم (سهم واحد)', 'مصطفى الجعلي', 'الدفعة التأسيسية الأولى لتمويل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-7', 'prt-7', 'ايناس', '2026-06-15', 5355231, 'تحويل بنكك', 'رأس المال التأسيسي للموسم (سهم واحد)', 'مصطفى الجعلي', 'الدفعة التأسيسية الأولى لتمويل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-8', 'prt-8', 'رزاز', '2026-06-15', 5355231, 'تحويل بنكك', 'رأس المال التأسيسي للموسم (سهم واحد)', 'مصطفى الجعلي', 'الدفعة التأسيسية الأولى لتمويل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO capital_injections (id, partner_id, partner_name, date, amount, payment_method, purpose, logged_by, notes) VALUES ('inj-9', 'prt-9', 'عناب', '2026-06-15', 5355231, 'تحويل بنكك', 'رأس المال التأسيسي للموسم (سهم واحد)', 'مصطفى الجعلي', 'الدفعة التأسيسية الأولى لتمويل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO plots (id, name, area_feddan, crop, target_sowing_date, prep_feddans, planted_feddans) VALUES ('plot-weika', 'الويكة', 320, 'تسالي', '2026-09-25', 320, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-1', 'plot-weika', 'حراثة (كسرة أولى)', '2026-09-01', 'completed', 'ابستة', 2, 'عبدالقادر (الوكيل)', 'إشراف عبدالقادر: تمت الحراثة الأولى بنجاح') ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-2', 'plot-weika', 'رش مبيد', '2026-09-10', 'planned', 'الجعيلي', 1, 'عبدالقادر (الوكيل)', 'رش مبيد حشائش قبل الزراعة') ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-3', 'plot-weika', 'زراعة', '2026-09-25', 'planned', 'ابستة', 2, 'عبدالقادر (الوكيل)', 'بذر محصول التسالي') ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-1788070901796', 'plot-weika', 'حراثة (كسرة أولى)', '2026-08-30', 'completed', 'ابستة', 1, 'محمد مصطفى', 'بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO plots (id, name, area_feddan, crop, target_sowing_date, prep_feddans, planted_feddans) VALUES ('plot-500', 'ال500', 429, 'ذرة ارفع قدمك محسن', '2026-08-05', 429, 429) ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-4', 'plot-500', 'زراعة', '2026-08-05', 'completed', 'الجعيلي', 2.5, 'عبدالقادر (الوكيل)', 'زراعة مباشرة بدون حراثة سابقة بإشراف الوكيل عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-5', 'plot-500', 'كديب ونظافة', '2026-08-28', 'in_progress', 'عمالة يدوية', 0, 'عبدالقادر (الوكيل)', 'نظافة الحشائش في المرحلة الأولى') ON CONFLICT (id) DO NOTHING;
INSERT INTO plots (id, name, area_feddan, crop, target_sowing_date, prep_feddans, planted_feddans) VALUES ('plot-nuba', 'النوبة', 380, 'ذرة ارفع قدمك محسن', '2026-08-10', 380, 380) ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-6', 'plot-nuba', 'حراثة (كسرة أولى)', '2026-07-20', 'completed', 'ابستة', 2, 'عبدالقادر (الوكيل)', 'كسرة أولى لتجهيز التربة') ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-7', 'plot-nuba', 'زراعة', '2026-08-10', 'completed', 'ابستة', 2, 'عبدالقادر (الوكيل)', 'تمت الزراعة بنجاح') ON CONFLICT (id) DO NOTHING;
INSERT INTO plots (id, name, area_feddan, crop, target_sowing_date, prep_feddans, planted_feddans) VALUES ('plot-raqiqa', 'الرقيقة', 150, 'ذرة ارفع قدمك محسن', '2026-08-15', 150, 150) ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-8', 'plot-raqiqa', 'حراثة (كسرة أولى)', '2026-07-05', 'completed', 'الجعيلي', 1, 'عبدالقادر (الوكيل)', 'كسرة مبكرة') ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-9', 'plot-raqiqa', 'زراعة', '2026-08-15', 'completed', 'الجعيلي', 1, 'عبدالقادر (الوكيل)', 'زراعة ذرة ارفع قدمك') ON CONFLICT (id) DO NOTHING;
INSERT INTO plots (id, name, area_feddan, crop, target_sowing_date, prep_feddans, planted_feddans) VALUES ('plot-abbas', 'عباس', 170, 'تسالي', '2026-09-25', 0, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-10', 'plot-abbas', 'رش مبيد', '2026-09-10', 'planned', 'ابستة', 0.5, 'عبدالقادر (الوكيل)', 'رش وقائي') ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-11', 'plot-abbas', 'حراثة وزراعة', '2026-09-25', 'planned', 'الجعيلي', 1.5, 'عبدالقادر (الوكيل)', 'كسرة وزراعة تسالي') ON CONFLICT (id) DO NOTHING;
INSERT INTO plot_operations (id, plot_id, type, date, status, driver, fuel_barrels, created_by, notes) VALUES ('op-1788070877712', 'plot-abbas', 'حراثة (كسرة أولى)', '2026-08-30', 'completed', 'ابستة', 1, 'محمد مصطفى', 'بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO fuel_transactions (id, date, type, quantity, driver, plot, operation_name, logged_by, notes) VALUES ('ft-1788070995128', '2026-08-30', 'issue', 1, 'ابستة', 'الويكة', 'حراثة (كسرة أولى)', 'محمد مصطفى', 'صرف 1 برميل للسائق ابستة لعملية حراثة (كسرة أولى) بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO fuel_transactions (id, date, type, quantity, driver, plot, operation_name, logged_by, notes) VALUES ('ft-1', '2026-06-15', 'purchase', 6, '-', 'المخزن الرئيسي', 'توريد وقود بداية الموسم', 'مصطفى الجعلي', 'توريد من محطة القضارف المركزية بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO fuel_transactions (id, date, type, quantity, driver, plot, operation_name, logged_by, notes) VALUES ('ft-2', '2026-07-13', 'purchase', 4, '-', 'المخزن الرئيسي', 'توريد وقود إضافي', 'مصطفى الجعلي', 'توريد وقود بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO fuel_transactions (id, date, type, quantity, driver, plot, operation_name, logged_by, notes) VALUES ('ft-3', '2026-08-05', 'purchase', 4, '-', 'المخزن الرئيسي', 'توريد وقود لمرحلة الزراعة', 'مصطفى الجعلي', 'توريد وقود بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO fuel_transactions (id, date, type, quantity, driver, plot, operation_name, logged_by, notes) VALUES ('ft-4', '2026-07-05', 'issue', 2, 'الجعيلي', 'الرقيقة', 'حراثة (كسرة أولى)', 'حسن مصطفى', 'صرف جاز لتجهيز الرقيقة بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO fuel_transactions (id, date, type, quantity, driver, plot, operation_name, logged_by, notes) VALUES ('ft-5', '2026-07-20', 'issue', 3, 'ابستة', 'النوبة', 'حراثة (كسرة أولى)', 'حسن مصطفى', 'صرف جاز لكسرة النوبة بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO fuel_transactions (id, date, type, quantity, driver, plot, operation_name, logged_by, notes) VALUES ('ft-6', '2026-08-05', 'issue', 3, 'الجعيلي', 'ال500', 'زراعة', 'حسن مصطفى', 'صرف جاز لزراعة مقطوعية ال500 بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO fuel_transactions (id, date, type, quantity, driver, plot, operation_name, logged_by, notes) VALUES ('ft-1788070877712', '2026-08-30', 'issue', 1, 'ابستة', 'عباس', 'حراثة (كسرة أولى)', 'محمد مصطفى', 'صرف وقود لعملية حراثة (كسرة أولى) بإشراف عبدالقادر') ON CONFLICT (id) DO NOTHING;
INSERT INTO inventory_items (id, name, category, purchased_qty, used_qty, remaining_qty, unit, unit_price) VALUES ('inv-1', 'بذور ذرة ارفع قدمك محسن (تيراب)', 'بذور', 4, 3.8, 0.20000000000000018, 'طن / جوال', 3800000) ON CONFLICT (id) DO UPDATE SET purchased_qty = EXCLUDED.purchased_qty, used_qty = EXCLUDED.used_qty, remaining_qty = EXCLUDED.remaining_qty;
INSERT INTO inventory_items (id, name, category, purchased_qty, used_qty, remaining_qty, unit, unit_price) VALUES ('inv-2', 'بذور تسالي نقاوة أولى', 'بذور', 25, 0, 25, 'جوال (50 كجم)', 45000) ON CONFLICT (id) DO UPDATE SET purchased_qty = EXCLUDED.purchased_qty, used_qty = EXCLUDED.used_qty, remaining_qty = EXCLUDED.remaining_qty;
INSERT INTO inventory_items (id, name, category, purchased_qty, used_qty, remaining_qty, unit, unit_price) VALUES ('inv-3', 'مبيد 24D للحشائش عريضة', 'مبيدات', 2, 0, 2, 'برميل', 4400000) ON CONFLICT (id) DO UPDATE SET purchased_qty = EXCLUDED.purchased_qty, used_qty = EXCLUDED.used_qty, remaining_qty = EXCLUDED.remaining_qty;
INSERT INTO inventory_items (id, name, category, purchased_qty, used_qty, remaining_qty, unit, unit_price) VALUES ('inv-4', 'مبيد علب بودا', 'مبيدات', 27, 0, 27, 'علبة', 45000) ON CONFLICT (id) DO UPDATE SET purchased_qty = EXCLUDED.purchased_qty, used_qty = EXCLUDED.used_qty, remaining_qty = EXCLUDED.remaining_qty;
INSERT INTO inventory_items (id, name, category, purchased_qty, used_qty, remaining_qty, unit, unit_price) VALUES ('inv-5', 'دواء سويد وقارض للتقاوي', 'مبيدات', 80, 80, 0, 'ظرف', 12000) ON CONFLICT (id) DO UPDATE SET purchased_qty = EXCLUDED.purchased_qty, used_qty = EXCLUDED.used_qty, remaining_qty = EXCLUDED.remaining_qty;
INSERT INTO inventory_items (id, name, category, purchased_qty, used_qty, remaining_qty, unit, unit_price) VALUES ('inv-6', 'جازولين وقود زراعي', 'وقود', 14, 10, 4, 'برميل', 160000) ON CONFLICT (id) DO UPDATE SET purchased_qty = EXCLUDED.purchased_qty, used_qty = EXCLUDED.used_qty, remaining_qty = EXCLUDED.remaining_qty;
INSERT INTO inventory_items (id, name, category, purchased_qty, used_qty, remaining_qty, unit, unit_price) VALUES ('inv-crop-tasali', 'محصول تسالي (مخزون الحصاد)', 'محاصيل', 23, 2, 21, 'جوال', 400000) ON CONFLICT (id) DO UPDATE SET purchased_qty = EXCLUDED.purchased_qty, used_qty = EXCLUDED.used_qty, remaining_qty = EXCLUDED.remaining_qty;
INSERT INTO inventory_items (id, name, category, purchased_qty, used_qty, remaining_qty, unit, unit_price) VALUES ('inv-crop-sorghum', 'محصول ذرة (مخزون الحصاد)', 'محاصيل', 306, 0, 306, 'جوال', 320000) ON CONFLICT (id) DO UPDATE SET purchased_qty = EXCLUDED.purchased_qty, used_qty = EXCLUDED.used_qty, remaining_qty = EXCLUDED.remaining_qty;
INSERT INTO inventory_transactions (id, date, item_id, item_name, category, type, quantity, unit, unit_price, total_cost, plot, crop, receiver, logged_by, notes, sale_id) VALUES ('itx-sale-sale-1788159930960', '2026-08-30', 'inv-crop-tasali', 'محصول تسالي (مخزون الحصاد)', 'محاصيل', 'issue', 2, 'جوال', 400000, 800000, 'صومعة القضارف / الشونة', 'تسالي', 'خالد غريقانة', 'محمد مصطفى', 'صرف وتسليم مبيعات للتاجر/الشركة: خالد غريقانة (2 جوال تسالي (بلدي) × 400,000 ج.س)', 'sale-1788159930960') ON CONFLICT (id) DO NOTHING;
INSERT INTO inventory_transactions (id, date, item_id, item_name, category, type, quantity, unit, unit_price, total_cost, plot, crop, receiver, logged_by, notes, sale_id) VALUES ('itx-1788071282028', '2026-08-30', 'inv-1', 'بذور ذرة ارفع قدمك محسن (تيراب)', 'بذور', 'issue', 2, 'طن / جوال', 3800000, 7600000, 'الويكة', 'ذرة', 'ابستة', 'محمد مصطفى', 'زراعة', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO inventory_transactions (id, date, item_id, item_name, category, type, quantity, unit, unit_price, total_cost, plot, crop, receiver, logged_by, notes, sale_id) VALUES ('itx-1', '2026-08-04', 'inv-1', 'بذور ذرة ارفع قدمك محسن (تيراب)', 'بذور', 'purchase', 4, 'طن', 3800000, 15200000, 'المخزن الرئيسي', 'ذرة', '-', 'مصطفى الجعلي', 'شراء 4 طن تيراب معتمد × 3,800,000 ج.س', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO inventory_transactions (id, date, item_id, item_name, category, type, quantity, unit, unit_price, total_cost, plot, crop, receiver, logged_by, notes, sale_id) VALUES ('itx-2', '2026-08-04', 'inv-3', 'مبيد 24D للحشائش عريضة', 'مبيدات', 'purchase', 2, 'برميل', 4400000, 8800000, 'المخزن الرئيسي', 'ذرة', '-', 'مصطفى الجعلي', '2 برميل 24D للحشائش', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO inventory_transactions (id, date, item_id, item_name, category, type, quantity, unit, unit_price, total_cost, plot, crop, receiver, logged_by, notes, sale_id) VALUES ('itx-3', '2026-08-04', 'inv-4', 'مبيد علب بودا', 'مبيدات', 'purchase', 27, 'علبة', 45000, 1215000, 'المخزن الرئيسي', 'ذرة', '-', 'مصطفى الجعلي', '27 علبة بودا لمكافحة الحشائش', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO inventory_transactions (id, date, item_id, item_name, category, type, quantity, unit, unit_price, total_cost, plot, crop, receiver, logged_by, notes, sale_id) VALUES ('itx-4', '2026-08-05', 'inv-1', 'بذور ذرة ارفع قدمك محسن (تيراب)', 'بذور', 'issue', 1.8, 'طن', 3800000, 6840000, 'ال500', 'ذرة', 'الجعيلي', 'حسن مصطفى', 'صرف تقاوي لزراعة مقطوعية ال500 بإشراف عبدالقادر', NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO harvest_intakes (id, date, plot, crop, bags, weight_tons, storage_location, supervisor, quality_grade, notes) VALUES ('harv-1788157774886', '2026-06-20', 'ال500', 'تسالي (بلدي)', 23, 2.14, 'مخزن سوق المحاصيل (القضارف)', 'مصطفى الجعلي', 'درجة أولى', '') ON CONFLICT (id) DO NOTHING;
INSERT INTO harvest_intakes (id, date, plot, crop, bags, weight_tons, storage_location, supervisor, quality_grade, notes) VALUES ('harv-2', '2026-06-20', 'ال500', 'ذرة (فتريتة)', 306, 30.6, 'مخزن سوق المحاصيل (القضارف)', 'مصطفى الجعلي', 'درجة أولى', 'ترحيل فوري للصوامع عبر التريلة') ON CONFLICT (id) DO NOTHING;
INSERT INTO crop_sales (id, date, buyer_name, crop, bags, price_per_bag, total_amount, paid_amount, remaining_amount, payment_method, delivery_location, status, logged_by, notes) VALUES ('sale-1788159930960', '2026-08-30', 'خالد غريقانة', 'تسالي (بلدي)', 2, 400000, 800000, 800000, 0, 'تحويل بنكك', 'صومعة القضارف', 'مكتملة ومستلمة', 'محمد مصطفى', '') ON CONFLICT (id) DO NOTHING;
INSERT INTO machinery (id, name, type, plate, driver, status, hours_operated, oil_change_due_hours, fuel_tank_capacity, feddan_done, fuel_used_barrels) VALUES ('mac-2', 'جرار ماسي فيرجسون 290', 'جرار زراعي متوسط', 'قضارف 8934', 'محمد الجعيلي', 'جاهز وممتاز', 380, 450, 140, 579, 45) ON CONFLICT (id) DO NOTHING;
INSERT INTO machinery (id, name, type, plate, driver, status, hours_operated, oil_change_due_hours, fuel_tank_capacity, feddan_done, fuel_used_barrels) VALUES ('mac-3', 'حراثة ديسك 28 قرص (معدات)', 'حراثة وتقليب', '-', 'مشترك', 'جاهز للعمل', 310, 0, 0, 959, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO machinery (id, name, type, plate, driver, status, hours_operated, oil_change_due_hours, fuel_tank_capacity, feddan_done, fuel_used_barrels) VALUES ('mac-4', 'تريلة سحب ومقطورة غلال', 'ترحيل ونقل غلال', 'قضارف 1205', 'عبدالقادر', 'جاهز للعمل', 190, 0, 0, 0, 0) ON CONFLICT (id) DO NOTHING;
INSERT INTO labor (id, name, role, worker_type, start_date, end_date, monthly_salary, days_worked, months_worked, deductions_amount, overtime, total_due, total_paid, status, task, plot, crop, area_feddan, last_updated_by) VALUES ('lab-1', 'عبدالقادر', 'الوكيل والمشرف العام الميداني', 'permanent', '2026-07-10', NULL, 600000, 53, 1.8, 0, 0, 1080000, 1400000, 'paid', 'إشراف عام على العمليات والوقود والمخزون', 'كامل المشروع', 'مشترك', 1450, 'محمد مصطفى') ON CONFLICT (id) DO NOTHING;
INSERT INTO labor (id, name, role, worker_type, start_date, end_date, monthly_salary, days_worked, months_worked, deductions_amount, overtime, total_due, total_paid, status, task, plot, crop, area_feddan, last_updated_by) VALUES ('lab-2', 'ابستة', 'سائق تركتور أول', 'permanent', '2026-07-14', NULL, 800000, 49, 1.6, 0, 0, 1280000, 650000, 'partial', 'حراثة وزراعة النوبة والويكة', 'النوبة / الويكة', 'مشترك', 380, 'محمد مصطفى') ON CONFLICT (id) DO NOTHING;
INSERT INTO labor (id, name, role, worker_type, start_date, end_date, monthly_salary, days_worked, months_worked, deductions_amount, overtime, total_due, total_paid, status, task, plot, crop, area_feddan, last_updated_by) VALUES ('lab-3', 'محمد الجعيلي', 'سائق تركتور ثانٍ', 'permanent', '2026-07-14', NULL, 800000, 49, 1.6, 0, 0, 1280000, 650000, 'partial', 'حراثة وزراعة ال500 والرقيقة', 'ال500 / الرقيقة', 'ذرة', 579, 'محمد مصطفى') ON CONFLICT (id) DO NOTHING;
INSERT INTO labor (id, name, role, worker_type, start_date, end_date, monthly_salary, days_worked, months_worked, deductions_amount, overtime, total_due, total_paid, status, task, plot, crop, area_feddan, last_updated_by) VALUES ('lab-4', 'تشالي الحبشي', 'زيات', 'permanent', '2026-08-07', NULL, 400000, 25, 0.8, 0, 0, 320000, 100000, 'partial', 'تزييت وتشحيم الآليات ومساعدة السائقين', 'المقر والمخزن', 'مشترك', 0, 'محمد مصطفى') ON CONFLICT (id) DO NOTHING;
INSERT INTO labor (id, name, role, worker_type, start_date, end_date, monthly_salary, days_worked, months_worked, deductions_amount, overtime, total_due, total_paid, status, task, plot, crop, area_feddan, last_updated_by) VALUES ('lab-5', 'عمال الكمبو والبناء', 'بناء وتجهيز كمبو المزرعة', 'temporary', '2026-07-13', NULL, 950000, 50, 1.7, 0, 0, 1615000, 950000, 'partial', 'بناء الرواكيب والكرانك والسراير', 'كمبو المزرعة', 'مشترك', 0, 'محمد مصطفى') ON CONFLICT (id) DO NOTHING;
INSERT INTO labor (id, name, role, worker_type, start_date, end_date, monthly_salary, days_worked, months_worked, deductions_amount, overtime, total_due, total_paid, status, task, plot, crop, area_feddan, last_updated_by) VALUES ('lab-1788077268220', 'زيات حبشي', 'زيات', 'temporary', '2026-08-07', '2026-07-31', 400000, 1, 0.1, 303000, 0, -263000, 970000, 'paid', 'عمليات موسمية', 'مشترك', 'مشترك', 0, 'محمد مصطفى') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-1788082169682', '2026-08-30', 'البيت', 4980000, 'مشترك', 'البيت', 'عمرة حمادية', FALSE, 'محمد مصطفى', NULL, 'عمرة حمادية') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-001', '2026-06-22', 'إيجار أرض', 1150000, 'مشترك', 'مشترك', 'تجديد المشروع (تم تجديد المشروع لمدة سنة)', FALSE, 'مصطفى الجعلي', NULL, 'تجديد المشروع (تم تجديد المشروع لمدة سنة)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-002', '2026-06-14', 'البيت', 2000000, 'المقر والمنزل', 'البيت', 'طاقة شمسية حبوبة (تم تركيب طاقة شمسية لحبوبة بمشاركة جميع الاحفاد)', FALSE, 'مصطفى الجعلي', NULL, 'طاقة شمسية حبوبة (تم تركيب طاقة شمسية لحبوبة بمشاركة جميع الاحفاد)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-003', '2026-06-14', 'البيت', 200000, 'المقر والمنزل', 'البيت', 'تحويل حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'تحويل حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-004', '2026-06-14', 'البيت', 150000, 'المقر والمنزل', 'البيت', 'حسكو كاش البت الشغالة (راتب البت الشغالة)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو كاش البت الشغالة (راتب البت الشغالة)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-005', '2026-07-04', 'بذور', 290000, 'مشترك', 'مشترك', 'ترحيل ورفع ونزول عيش (مخزون الموسم السابق)', FALSE, 'مصطفى الجعلي', NULL, 'ترحيل ورفع ونزول عيش (مخزون الموسم السابق)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-006', '2026-07-04', 'البيت', 100000, 'المقر والمنزل', 'البيت', 'تحويل حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'تحويل حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-007', '2026-07-04', 'البيت', 200000, 'المقر والمنزل', 'البيت', 'تحويل حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'تحويل حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-008', '2026-07-04', 'وقود', 130000, 'مشترك', 'مشترك', 'زيت + جاز (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'زيت + جاز (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-009', '2026-07-04', 'البيت', 100000, 'المقر والمنزل', 'البيت', 'تحويل حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'تحويل حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-010', '2026-07-04', 'مصاريف إدارية', 330000, 'مشترك', 'مشترك', 'مواسير لعدد 4 سراير (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'مواسير لعدد 4 سراير (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-011', '2026-07-04', 'مصاريف إدارية', 60000, 'مشترك', 'مشترك', 'مصنعية الحداد (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'مصنعية الحداد (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-012', '2026-07-04', 'مصاريف إدارية', 130000, 'مشترك', 'مشترك', 'تجليد سراير الخلا (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'تجليد سراير الخلا (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-013', '2026-07-04', 'البيت', 102000, 'المقر والمنزل', 'البيت', 'طحنية وبسكويت حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'طحنية وبسكويت حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-014', '2026-07-04', 'البيت', 108000, 'المقر والمنزل', 'البيت', 'حساب حسكو الدكان (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حساب حسكو الدكان (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-015', '2026-07-04', 'البيت', 200000, 'المقر والمنزل', 'البيت', 'تحويل حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'تحويل حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-016', '2026-07-08', 'إيجار آليات', 1200000, 'مشترك', 'مشترك', 'ايجار تريلة (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'ايجار تريلة (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-017', '2026-07-08', 'إيجار آليات', 4500000, 'مشترك', 'مشترك', 'ايجار دسكي (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'ايجار دسكي (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-018', '2026-07-08', 'مصاريف إدارية', 100000, 'مشترك', 'مشترك', 'تحويل حسكو + رصيد+ مواصلات لهيثم (تفاوض مع هيثم)', FALSE, 'مصطفى الجعلي', NULL, 'تحويل حسكو + رصيد+ مواصلات لهيثم (تفاوض مع هيثم)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-019', '2026-07-08', 'إيجار آليات', 9000000, 'مشترك', 'مشترك', 'ايجار بابور (يخصم من قيمة الايجار)', FALSE, 'مصطفى الجعلي', NULL, 'ايجار بابور (يخصم من قيمة الايجار)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-020', '2026-07-12', 'عمالة', 100000, 'مشترك', 'مشترك', 'عبدالقادر (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'عبدالقادر (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-021', '2026-07-12', 'مصاريف إدارية', 150000, 'مشترك', 'مشترك', 'ميز (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'ميز (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-022', '2026-07-12', 'إيجار آليات', 50000, 'مشترك', 'مشترك', 'حسكو- عمولة ايجار بابور (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو- عمولة ايجار بابور (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-023', '2026-07-12', 'إيجار آليات', 800000, 'مشترك', 'مشترك', 'اسبيرات للبابور (يخصم من قيمة الايجار)', FALSE, 'مصطفى الجعلي', NULL, 'اسبيرات للبابور (يخصم من قيمة الايجار)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-024', '2026-07-12', 'وقود', 167000, 'مشترك', 'مشترك', 'جاز للبابور (جاز للبابور)', FALSE, 'مصطفى الجعلي', NULL, 'جاز للبابور (جاز للبابور)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-025', '2026-07-12', 'إيجار آليات', 262000, 'مشترك', 'مشترك', 'اسبيرات للبابور 2 (يخصم من قيمة الايجار)', FALSE, 'مصطفى الجعلي', NULL, 'اسبيرات للبابور 2 (يخصم من قيمة الايجار)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-026', '2026-07-12', 'مصاريف إدارية', 115000, 'مشترك', 'مشترك', 'عدة خلا + مواصلات + فطور وقهوة (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'عدة خلا + مواصلات + فطور وقهوة (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-027', '2026-07-12', 'البيت', 50000, 'المقر والمنزل', 'البيت', 'تحويل حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'تحويل حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-028', '2026-07-12', 'مصاريف إدارية', 235000, 'مشترك', 'مشترك', 'حسكو+جعفر (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو+جعفر (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-029', '2026-07-13', 'مصاريف إدارية', 1330000, 'مشترك', 'مشترك', 'تكملة مواد الكمبو (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'تكملة مواد الكمبو (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-030', '2026-07-13', 'مصاريف إدارية', 20000, 'مشترك', 'مشترك', 'فطور (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'فطور (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-031', '2026-07-13', 'مصاريف إدارية', 40000, 'مشترك', 'مشترك', 'اجنه + سمبك + مفتاح (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'اجنه + سمبك + مفتاح (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-032', '2026-07-13', 'إيجار آليات', 60000, 'مشترك', 'مشترك', 'اسبير للبابور (يخصم من قيمة الايجار)', FALSE, 'مصطفى الجعلي', NULL, 'اسبير للبابور (يخصم من قيمة الايجار)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-033', '2026-07-13', 'مصاريف إدارية', 700000, 'مشترك', 'مشترك', 'كرتونة زيت + ٢ امبوبه مقاس ١٥ (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'كرتونة زيت + ٢ امبوبه مقاس ١٥ (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-034', '2026-07-13', 'بذور', 162000, 'مشترك', 'مشترك', 'شوال عيش (دقيق) (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'شوال عيش (دقيق) (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-035', '2026-07-13', 'مصاريف إدارية', 91000, 'مشترك', 'مشترك', 'جامايكا (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'جامايكا (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-036', '2026-07-13', 'إيجار آليات', 15000, 'مشترك', 'مشترك', 'مسمار للبابور (يخصم من قيمة الايجار)', FALSE, 'مصطفى الجعلي', NULL, 'مسمار للبابور (يخصم من قيمة الايجار)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-037', '2026-07-13', 'مصاريف إدارية', 50000, 'مشترك', 'مشترك', 'سكر ٥ كيلو + كرتونة صلصه (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'سكر ٥ كيلو + كرتونة صلصه (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-038', '2026-07-13', 'مصاريف إدارية', 60000, 'مشترك', 'مشترك', '٢ رطل تمباك (عبد القادر) (إدارية)', FALSE, 'مصطفى الجعلي', NULL, '٢ رطل تمباك (عبد القادر) (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-039', '2026-07-13', 'إيجار آليات', 90000, 'مشترك', 'مشترك', 'مصنعية البابور (يخصم من قيمة الايجار)', FALSE, 'مصطفى الجعلي', NULL, 'مصنعية البابور (يخصم من قيمة الايجار)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-040', '2026-07-13', 'عمالة', 40000, 'مشترك', 'مشترك', 'عتالة رفع المواد (للكمبو) (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'عتالة رفع المواد (للكمبو) (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-041', '2026-07-13', 'إيجار آليات', 70000, 'مشترك', 'مشترك', 'مقدم ايجار تريلة (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'مقدم ايجار تريلة (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-042', '2026-07-13', 'مصاريف إدارية', 134000, 'مشترك', 'مشترك', 'فاسات حطب و لحلمه و مدقه و اباريق (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'فاسات حطب و لحلمه و مدقه و اباريق (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-043', '2026-07-13', 'إيجار آليات', 20000, 'مشترك', 'مشترك', 'عدد 2 مسمار قطرة (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'عدد 2 مسمار قطرة (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-044', '2026-07-13', 'عمالة', 20000, 'مشترك', 'مشترك', 'مواصلات وفطور عبدالقادر (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'مواصلات وفطور عبدالقادر (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-045', '2026-07-13', 'إيجار آليات', 100000, 'مشترك', 'مشترك', 'مصنعية بابور (يخصم من قيمة الايجار)', FALSE, 'مصطفى الجعلي', NULL, 'مصنعية بابور (يخصم من قيمة الايجار)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-046', '2026-07-13', 'مصاريف إدارية', 120000, 'مشترك', 'مشترك', 'شرقاني (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'شرقاني (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-047', '2026-07-13', 'مصاريف إدارية', 350000, 'مشترك', 'مشترك', 'قصب (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'قصب (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-048', '2026-07-13', 'مصاريف إدارية', 150000, 'مشترك', 'مشترك', 'مقدم بناء (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'مقدم بناء (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-049', '2026-07-13', 'مصاريف إدارية', 250000, 'مشترك', 'مشترك', 'قش الكرنك (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'قش الكرنك (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-050', '2026-07-13', 'مصاريف إدارية', 42000, 'مشترك', 'مشترك', 'حبل رباط (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'حبل رباط (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-051', '2026-07-13', 'إيجار آليات', 55000, 'مشترك', 'مشترك', 'اسبير البابور (يخصم من قيمة الايجار)', FALSE, 'مصطفى الجعلي', NULL, 'اسبير البابور (يخصم من قيمة الايجار)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-052', '2026-07-13', 'وقود', 6865000, 'مشترك', 'مشترك', 'جاز (وقود)', FALSE, 'مصطفى الجعلي', NULL, 'جاز (وقود)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-053', '2026-07-13', 'إيجار آليات', 1919000, 'مشترك', 'مشترك', 'فاتورة حاتم عمر خالد (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'فاتورة حاتم عمر خالد (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-054', '2026-07-13', 'عمالة', 200000, 'مشترك', 'مشترك', 'ابستة (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'ابستة (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-055', '2026-07-13', 'عمالة', 300000, 'مشترك', 'مشترك', 'عبدالقادر (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'عبدالقادر (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-056', '2026-07-13', 'صيانة', 7120000, 'مشترك', 'مشترك', 'عمرة العربية (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'عمرة العربية (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-057', '2026-07-15', 'إيجار آليات', 1618000, 'مشترك', 'مشترك', 'متبقي إيجار البابور (يخصم من قيمة الايجار)', FALSE, 'مصطفى الجعلي', NULL, 'متبقي إيجار البابور (يخصم من قيمة الايجار)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-058', '2026-07-15', 'عمالة', 150000, 'مشترك', 'مشترك', 'محمد الجعيلي (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'محمد الجعيلي (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-059', '2026-07-18', 'مصاريف إدارية', 800000, 'مشترك', 'مشترك', 'متبقي عمال الكمبو (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'متبقي عمال الكمبو (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-060', '2026-07-18', 'البيت', 100000, 'المقر والمنزل', 'البيت', 'تحويل حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'تحويل حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-061', '2026-07-18', 'مصاريف إدارية', 317000, 'مشترك', 'مشترك', 'سجاير وتمباك وباتة وحبوب وسلك (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'سجاير وتمباك وباتة وحبوب وسلك (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-062', '2026-07-18', 'مصاريف إدارية', 35000, 'مشترك', 'مشترك', 'ترحيل + سلطة وعيش (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'ترحيل + سلطة وعيش (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-063', '2026-07-26', 'صيانة', 2000000, 'مشترك', 'مشترك', 'الميكانيكي (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'الميكانيكي (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-064', '2026-07-26', 'صيانة', 150000, 'مشترك', 'مشترك', 'مخرطة رأس (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'مخرطة رأس (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-065', '2026-07-26', 'صيانة', 270000, 'مشترك', 'مشترك', 'مخرطة سلندر (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'مخرطة سلندر (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-066', '2026-07-26', 'صيانة', 210000, 'مشترك', 'مشترك', 'سايفون (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'سايفون (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-067', '2026-07-26', 'مصاريف إدارية', 200000, 'مشترك', 'مشترك', 'ميز (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'ميز (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-068', '2026-07-26', 'صيانة', 310000, 'مشترك', 'مشترك', 'غيار زيت ومصفى وزيت هايدروليك (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'غيار زيت ومصفى وزيت هايدروليك (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-069', '2026-07-26', 'صيانة', 360000, 'مشترك', 'مشترك', 'قماشات ولقم فرامل (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'قماشات ولقم فرامل (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-070', '2026-07-26', 'البيت', 200000, 'المقر والمنزل', 'البيت', 'حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-071', '2026-07-26', 'البيت', 225000, 'المقر والمنزل', 'البيت', 'رسوم ميان الروضة (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'رسوم ميان الروضة (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-072', '2026-07-26', 'صيانة', 140000, 'مشترك', 'مشترك', 'سمكرة (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'سمكرة (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-073', '2026-07-26', 'البيت', 200000, 'المقر والمنزل', 'البيت', 'حسكو البت الشغالة (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو البت الشغالة (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-074', '2026-07-26', 'إيجار آليات', 80000, 'مشترك', 'مشترك', 'خرطوش لديتر للبابور (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'خرطوش لديتر للبابور (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-075', '2026-07-26', 'البيت', 56000, 'المقر والمنزل', 'البيت', 'حسكو (الجمري الاسعد) (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (الجمري الاسعد) (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-076', '2026-07-28', 'مصاريف إدارية', 372000, 'مشترك', 'مشترك', 'ميز (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'ميز (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-077', '2026-07-28', 'مصاريف إدارية', 30000, 'مشترك', 'مشترك', 'صحون (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'صحون (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-078', '2026-07-28', 'إيجار آليات', 18000, 'مشترك', 'مشترك', 'صبابة للجاز (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'صبابة للجاز (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-079', '2026-07-28', 'إيجار آليات', 235000, 'مشترك', 'مشترك', '(مسامير و ورد وحبه ويد حبه و٤ هاوزن) (معدات)', FALSE, 'مصطفى الجعلي', NULL, '(مسامير و ورد وحبه ويد حبه و٤ هاوزن) (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-080', '2026-07-28', 'وقود', 350000, 'مشترك', 'مشترك', 'جاز (وقود)', FALSE, 'مصطفى الجعلي', NULL, 'جاز (وقود)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-081', '2026-07-28', 'مصاريف إدارية', 600000, 'مشترك', 'مشترك', 'كرامه (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'كرامه (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-082', '2026-07-28', 'عمالة', 300000, 'مشترك', 'مشترك', 'عبد القادر (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'عبد القادر (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-083', '2026-08-04', 'مصاريف إدارية', 30000, 'مشترك', 'مشترك', 'فطور (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'فطور (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-084', '2026-08-04', 'عمالة', 10000, 'مشترك', 'مشترك', 'عبد القادر فطور (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'عبد القادر فطور (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-085', '2026-08-04', 'إيجار أرض', 1994000, 'مشترك', 'مشترك', 'ضرائب التسالي (مخزون الموسم السابق)', FALSE, 'مصطفى الجعلي', NULL, 'ضرائب التسالي (مخزون الموسم السابق)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-086', '2026-08-04', 'إيجار أرض', 1869000, 'مشترك', 'مشترك', 'ايجار المخزن (مخزون الموسم السابق)', FALSE, 'مصطفى الجعلي', NULL, 'ايجار المخزن (مخزون الموسم السابق)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-087', '2026-08-04', 'إيجار آليات', 3000000, 'مشترك', 'مشترك', 'مقدم صيانة البابور (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'مقدم صيانة البابور (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-088', '2026-08-04', 'مصاريف إدارية', 50000, 'مشترك', 'مشترك', 'بريش (حلل شالا حسكو) (تجهيز الكمبو)', FALSE, 'مصطفى الجعلي', NULL, 'بريش (حلل شالا حسكو) (تجهيز الكمبو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-089', '2026-08-04', 'إيجار آليات', 950000, 'مشترك', 'مشترك', 'جوز لساتك (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'جوز لساتك (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-090', '2026-08-04', 'إيجار آليات', 40000, 'مشترك', 'مشترك', 'جلب (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'جلب (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-091', '2026-08-04', 'مصاريف إدارية', 10000, 'مشترك', 'مشترك', 'صابون (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'صابون (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-092', '2026-08-04', 'مصاريف إدارية', 20000, 'مشترك', 'مشترك', 'فطور (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'فطور (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-093', '2026-08-04', 'مصاريف إدارية', 30000, 'مشترك', 'مشترك', 'مصاريف (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'مصاريف (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-094', '2026-08-04', 'البيت', 100000, 'المقر والمنزل', 'البيت', 'حسن (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسن (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-095', '2026-08-04', 'وقود', 200000, 'مشترك', 'مشترك', 'جاز (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'جاز (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-096', '2026-08-04', 'عمالة', 100000, 'مشترك', 'مشترك', 'عبد القادر (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'عبد القادر (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-097', '2026-08-04', 'إيجار آليات', 1850000, 'مشترك', 'مشترك', 'براميل (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'براميل (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-098', '2026-08-04', 'البيت', 500000, 'المقر والمنزل', 'البيت', 'حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-099', '2026-08-04', 'إيجار آليات', 330000, 'مشترك', 'مشترك', 'زيت للبابور (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'زيت للبابور (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-100', '2026-08-04', 'إيجار آليات', 50000, 'مشترك', 'مشترك', 'تسييخ لديتر البابور (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'تسييخ لديتر البابور (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-101', '2026-08-04', 'إيجار آليات', 3100000, 'مشترك', 'مشترك', 'متبقي صيانة البابور (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'متبقي صيانة البابور (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-102', '2026-08-04', 'بذور', 15200000, 'مشترك', 'ذرة', 'عدد 4 طن تيراب × 3,800 (تقاوي)', FALSE, 'مصطفى الجعلي', NULL, 'عدد 4 طن تيراب × 3,800 (تقاوي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-103', '2026-08-04', 'مبيدات', 520000, 'مشترك', 'ذرة', 'عدد 40 ظرف دواء سويد × 13,000 (مبيد)', FALSE, 'مصطفى الجعلي', NULL, 'عدد 40 ظرف دواء سويد × 13,000 (مبيد)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-104', '2026-08-04', 'مبيدات', 440000, 'مشترك', 'ذرة', 'عدد 40 ظرف دواء قارض × 11,000 (مبيد)', FALSE, 'مصطفى الجعلي', NULL, 'عدد 40 ظرف دواء قارض × 11,000 (مبيد)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-105', '2026-08-04', 'مبيدات', 8800000, 'مشترك', 'ذرة', '2 برميل 24D للحشائش (مبيد)', FALSE, 'مصطفى الجعلي', NULL, '2 برميل 24D للحشائش (مبيد)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-106', '2026-08-04', 'مبيدات', 1215000, 'مشترك', 'ذرة', 'عدد 27 علبة بودا × 45,000 (مبيد)', FALSE, 'مصطفى الجعلي', NULL, 'عدد 27 علبة بودا × 45,000 (مبيد)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-107', '2026-08-04', 'عمالة', 200000, 'مشترك', 'ذرة', 'حسكو كاش للعتالة (رفع وتنزيل التقاوي والمبيد)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو كاش للعتالة (رفع وتنزيل التقاوي والمبيد)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-108', '2026-08-04', 'نقل', 1100000, 'مشترك', 'ذرة', 'ايجار لوري (ترحيل التقواي والمبيد)', FALSE, 'مصطفى الجعلي', NULL, 'ايجار لوري (ترحيل التقواي والمبيد)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-109', '2026-08-05', 'مصاريف إدارية', 14000, 'مشترك', 'مشترك', 'فطور (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'فطور (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-110', '2026-08-05', 'وقود', 21352000, 'مشترك', 'مشترك', 'جاز (وقود)', FALSE, 'مصطفى الجعلي', NULL, 'جاز (وقود)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-111', '2026-08-05', 'إيجار آليات', 700000, 'مشترك', 'مشترك', 'صيانة التريلة (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'صيانة التريلة (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-112', '2026-08-05', 'عمالة', 100000, 'مشترك', 'مشترك', 'عبدالقادر (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'عبدالقادر (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-113', '2026-08-11', 'مصاريف إدارية', 34000, 'مشترك', 'مشترك', 'فطور وقهوه ومواصلات (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'فطور وقهوه ومواصلات (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-114', '2026-08-11', 'عمالة', 50000, 'مشترك', 'مشترك', 'منقلي الزيات (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'منقلي الزيات (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-115', '2026-08-11', 'إيجار آليات', 300000, 'مشترك', 'مشترك', 'اسبيرات (هوب وبلي ولباد) (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'اسبيرات (هوب وبلي ولباد) (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-116', '2026-08-11', 'إيجار أرض', 75000, 'مشترك', 'مشترك', 'ترتيب التسالي (مخزون الموسم السابق)', FALSE, 'مصطفى الجعلي', NULL, 'ترتيب التسالي (مخزون الموسم السابق)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-117', '2026-08-11', 'إيجار آليات', 200000, 'مشترك', 'مشترك', 'حاتم عمر خالد (حساب قديم ويد.حبه) (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'حاتم عمر خالد (حساب قديم ويد.حبه) (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-118', '2026-08-11', 'مصاريف إدارية', 90000, 'مشترك', 'مشترك', 'باور بانك (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'باور بانك (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-119', '2026-08-11', 'مصاريف إدارية', 80000, 'مشترك', 'مشترك', 'سجار (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'سجار (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-120', '2026-08-11', 'مصاريف إدارية', 30000, 'مشترك', 'مشترك', 'تمباك (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'تمباك (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-121', '2026-08-11', 'مصاريف إدارية', 165000, 'مشترك', 'مشترك', '(سكر زيت صلصه شاي) (الميز)', FALSE, 'مصطفى الجعلي', NULL, '(سكر زيت صلصه شاي) (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-122', '2026-08-11', 'مصاريف إدارية', 140000, 'مشترك', 'مشترك', 'كجيك (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'كجيك (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-123', '2026-08-11', 'مصاريف إدارية', 48000, 'مشترك', 'مشترك', 'بصل (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'بصل (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-124', '2026-08-11', 'مصاريف إدارية', 30000, 'مشترك', 'مشترك', '(كسبره توم لوبا قرفه) (الميز)', FALSE, 'مصطفى الجعلي', NULL, '(كسبره توم لوبا قرفه) (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-125', '2026-08-11', 'مصاريف إدارية', 80000, 'مشترك', 'مشترك', 'صيانة البطاريه بتاعت المزرعه (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'صيانة البطاريه بتاعت المزرعه (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-126', '2026-08-11', 'مصاريف إدارية', 34000, 'مشترك', 'مشترك', 'دقيق (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'دقيق (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-127', '2026-08-11', 'مصاريف إدارية', 14000, 'مشترك', 'مشترك', '٢ طبله (الميز)', FALSE, 'مصطفى الجعلي', NULL, '٢ طبله (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-128', '2026-08-11', 'مصاريف إدارية', 8000, 'مشترك', 'مشترك', 'معجون (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'معجون (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-129', '2026-08-11', 'مصاريف إدارية', 6000, 'مشترك', 'مشترك', 'صابون بدره (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'صابون بدره (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-130', '2026-08-11', 'مصاريف إدارية', 6000, 'مشترك', 'مشترك', 'فرش (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'فرش (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-131', '2026-08-11', 'مصاريف إدارية', 10000, 'مشترك', 'مشترك', 'رغيف (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'رغيف (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-132', '2026-08-11', 'مصاريف إدارية', 8000, 'مشترك', 'مشترك', 'سلطة (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'سلطة (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-133', '2026-08-11', 'مصاريف إدارية', 6000, 'مشترك', 'مشترك', 'صابون حجر (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'صابون حجر (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-134', '2026-08-11', 'مصاريف إدارية', 8000, 'مشترك', 'مشترك', 'صابون سائل (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'صابون سائل (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-135', '2026-08-11', 'البيت', 250000, 'المقر والمنزل', 'البيت', 'حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-136', '2026-08-11', 'وقود', 300000, 'مشترك', 'مشترك', 'جاز (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'جاز (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-137', '2026-08-11', 'إيجار آليات', 50000, 'مشترك', 'مشترك', 'هنبوبة (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'هنبوبة (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-138', '2026-08-19', 'عمالة', 97000, 'مشترك', 'مشترك', 'الحبشي الزيات (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'الحبشي الزيات (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-139', '2026-08-19', 'عمالة', 300000, 'مشترك', 'مشترك', 'عبدالقادر (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'عبدالقادر (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-140', '2026-08-19', 'مصاريف إدارية', 80000, 'مشترك', 'مشترك', 'حسكو باقي البنك (إدارية)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو باقي البنك (إدارية)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-141', '2026-08-19', 'البيت', 200000, 'المقر والمنزل', 'البيت', 'حسكو البت الشغالة (راتب البت الشغالة)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو البت الشغالة (راتب البت الشغالة)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-142', '2026-08-19', 'إيجار آليات', 130000, 'مشترك', 'مشترك', 'يد طقطاق جنزير ومسامير ياي (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'يد طقطاق جنزير ومسامير ياي (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-143', '2026-08-19', 'البيت', 180000, 'المقر والمنزل', 'البيت', 'جواز حمادية (عمل خير)', FALSE, 'مصطفى الجعلي', NULL, 'جواز حمادية (عمل خير)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-144', '2026-08-19', 'البيت', 50000, 'المقر والمنزل', 'البيت', 'حسكو رصيد (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو رصيد (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-145', '2026-08-19', 'مصاريف إدارية', 530000, 'مشترك', 'مشترك', 'بن (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'بن (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-146', '2026-08-19', 'مصاريف إدارية', 28000, 'مشترك', 'مشترك', 'لوبا + كسبرة + توم (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'لوبا + كسبرة + توم (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-147', '2026-08-19', 'مصاريف إدارية', 70000, 'مشترك', 'مشترك', 'صلصة + زيت (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'صلصة + زيت (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-148', '2026-08-19', 'مصاريف إدارية', 12000, 'مشترك', 'مشترك', 'بلح (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'بلح (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-149', '2026-08-19', 'مصاريف إدارية', 20000, 'مشترك', 'مشترك', 'سلطة + رغيف (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'سلطة + رغيف (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-150', '2026-08-19', 'مصاريف إدارية', 50000, 'مشترك', 'مشترك', 'بصل (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'بصل (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-151', '2026-08-19', 'إيجار آليات', 180000, 'مشترك', 'مشترك', 'زيت مكنة + موية نار (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'زيت مكنة + موية نار (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-152', '2026-08-19', 'مصاريف إدارية', 9000, 'مشترك', 'مشترك', 'شاحن (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'شاحن (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-153', '2026-08-19', 'مصاريف إدارية', 50000, 'مشترك', 'مشترك', 'محول (انفيرتر) (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'محول (انفيرتر) (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-154', '2026-08-19', 'مصاريف إدارية', 90000, 'مشترك', 'مشترك', 'تمباك (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'تمباك (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-155', '2026-08-19', 'مصاريف إدارية', 90000, 'مشترك', 'مشترك', 'سجاير (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'سجاير (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-156', '2026-08-19', 'مصاريف إدارية', 65000, 'مشترك', 'مشترك', 'كجيك (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'كجيك (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-157', '2026-08-19', 'إيجار آليات', 220000, 'مشترك', 'مشترك', 'صاجات ديسكي (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'صاجات ديسكي (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-158', '2026-08-19', 'إيجار آليات', 40000, 'مشترك', 'مشترك', 'انبوبة مقاس 16 (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'انبوبة مقاس 16 (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-159', '2026-08-19', 'مصاريف إدارية', 10000, 'مشترك', 'مشترك', 'رغيف (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'رغيف (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-160', '2026-08-19', 'مصاريف إدارية', 20000, 'مشترك', 'مشترك', 'صباعات بطارية (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'صباعات بطارية (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-161', '2026-08-19', 'مصاريف إدارية', 20000, 'مشترك', 'مشترك', 'سلطة (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'سلطة (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-162', '2026-08-19', 'مصاريف إدارية', 600000, 'مشترك', 'مشترك', 'كرامتين (حملين من الخلا) (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'كرامتين (حملين من الخلا) (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-163', '2026-08-19', 'البيت', 305000, 'المقر والمنزل', 'البيت', 'حسكو (عمل خير)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (عمل خير)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-164', '2026-08-20', 'عمالة', 500000, 'مشترك', 'مشترك', 'محمد الجعيلي (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'محمد الجعيلي (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-165', '2026-08-22', 'مصاريف إدارية', 100000, 'مشترك', 'مشترك', 'حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-166', '2026-08-22', 'عمالة', 100000, 'مشترك', 'مشترك', 'تشالي الزيات (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'تشالي الزيات (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-167', '2026-08-22', 'عمالة', 350000, 'مشترك', 'مشترك', 'اب ستة (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'اب ستة (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-168', '2026-08-22', 'البيت', 300000, 'المقر والمنزل', 'البيت', 'حسكو عشاء (عمل خير)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو عشاء (عمل خير)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-169', '2026-08-22', 'البيت', 200000, 'المقر والمنزل', 'البيت', 'حسكو بنزين (عمل خير)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو بنزين (عمل خير)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-170', '2026-08-22', 'البيت', 1000000, 'المقر والمنزل', 'البيت', 'حسكو (عمل خير)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (عمل خير)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-171', '2026-08-22', 'البيت', 1650000, 'المقر والمنزل', 'البيت', 'كرامة البيت (عمل خير)', FALSE, 'مصطفى الجعلي', NULL, 'كرامة البيت (عمل خير)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-172', '2026-08-22', 'صيانة', 200000, 'مشترك', 'مشترك', 'جاز (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'جاز (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-173', '2026-07-28', 'عمالة', 300000, 'مشترك', 'مشترك', 'عبدالقادر (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'عبدالقادر (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-174', '2026-07-28', 'صيانة', 300000, 'مشترك', 'مشترك', 'جاز (عربية الجعلي)', FALSE, 'مصطفى الجعلي', NULL, 'جاز (عربية الجعلي)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-175', '2026-07-28', 'مصاريف إدارية', 30000, 'مشترك', 'مشترك', 'رغيف وسلطة (الميز)', FALSE, 'مصطفى الجعلي', NULL, 'رغيف وسلطة (الميز)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-176', '2026-07-28', 'البيت', 150000, 'المقر والمنزل', 'البيت', 'حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-177', '2026-07-28', 'عمالة', 100000, 'المقر والمنزل', 'البيت', 'الغفير (جزء من الراتب)', FALSE, 'مصطفى الجعلي', NULL, 'الغفير (جزء من الراتب)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-178', '2026-07-28', 'البيت', 500000, 'المقر والمنزل', 'البيت', 'حسكو (مصاريف حسكو)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (مصاريف حسكو)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-179', '2026-07-28', 'البيت', 2822000, 'المقر والمنزل', 'البيت', 'باقي العمرة (عمل خير)', FALSE, 'مصطفى الجعلي', NULL, 'باقي العمرة (عمل خير)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-180', '2026-07-28', 'البيت', 166000, 'المقر والمنزل', 'البيت', 'تذكرة بورتسودان لحمادية (عمل خير)', FALSE, 'مصطفى الجعلي', NULL, 'تذكرة بورتسودان لحمادية (عمل خير)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-181', '2026-07-28', 'إيجار آليات', 271000, 'مشترك', 'مشترك', 'اسبيرات حاتم عمر خالد (معدات)', FALSE, 'مصطفى الجعلي', NULL, 'اسبيرات حاتم عمر خالد (معدات)') ON CONFLICT (id) DO NOTHING;
INSERT INTO expenses (id, date, category, amount, plot, crop, op, is_under_review, created_by, modified_by, notes) VALUES ('exp-182', '2026-07-28', 'البيت', 70000, 'المقر والمنزل', 'البيت', 'حسكو (نظافة البيت)', FALSE, 'مصطفى الجعلي', NULL, 'حسكو (نظافة البيت)') ON CONFLICT (id) DO NOTHING;

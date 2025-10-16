-- Schema cho quản lý địa chỉ người dùng
-- Chạy script này trên Supabase SQL Editor

-- Tạo bảng user_addresses
CREATE TABLE IF NOT EXISTS user_addresses (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address_line1 VARCHAR(200) NOT NULL,
    address_line2 VARCHAR(200),
    ward VARCHAR(100), -- Phường/Xã
    district VARCHAR(100), -- Quận/Huyện
    city VARCHAR(100) NOT NULL, -- Tỉnh/Thành phố
    postal_code VARCHAR(10),
    is_default BOOLEAN DEFAULT FALSE,
    address_type VARCHAR(20) DEFAULT 'home', -- home, office, other
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tạo index để tối ưu truy vấn
CREATE INDEX IF NOT EXISTS idx_user_addresses_user_id ON user_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_addresses_default ON user_addresses(user_id, is_default);

-- Tạo function để đảm bảo chỉ có 1 địa chỉ mặc định
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    -- Nếu đang set is_default = true
    IF NEW.is_default = true THEN
        -- Set tất cả địa chỉ khác của user này thành false
        UPDATE user_addresses 
        SET is_default = false 
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger để tự động xử lý địa chỉ mặc định
DROP TRIGGER IF EXISTS trigger_ensure_single_default_address ON user_addresses;
CREATE TRIGGER trigger_ensure_single_default_address
    BEFORE INSERT OR UPDATE ON user_addresses
    FOR EACH ROW
    EXECUTE FUNCTION ensure_single_default_address();

-- Tạo function để update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger để tự động update updated_at
DROP TRIGGER IF EXISTS trigger_update_user_addresses_updated_at ON user_addresses;
CREATE TRIGGER trigger_update_user_addresses_updated_at
    BEFORE UPDATE ON user_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

-- Tạo policy để user chỉ có thể xem/sửa địa chỉ của mình
CREATE POLICY "Users can view their own addresses" ON user_addresses
    FOR SELECT USING (auth.uid()::text = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY "Users can insert their own addresses" ON user_addresses
    FOR INSERT WITH CHECK (auth.uid()::text = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY "Users can update their own addresses" ON user_addresses
    FOR UPDATE USING (auth.uid()::text = (SELECT auth_id FROM users WHERE id = user_id));

CREATE POLICY "Users can delete their own addresses" ON user_addresses
    FOR DELETE USING (auth.uid()::text = (SELECT auth_id FROM users WHERE id = user_id));

-- Thêm một số địa chỉ mẫu (tùy chọn)
-- INSERT INTO user_addresses (user_id, full_name, phone, address_line1, ward, district, city, is_default, address_type)
-- VALUES 
-- (1, 'Nguyễn Văn A', '0123 456 789', '123 Đường ABC', 'Phường Bến Nghé', 'Quận 1', 'TP.HCM', true, 'home'),
-- (1, 'Nguyễn Văn A', '0123 456 789', '456 Đường XYZ', 'Phường Thủ Thiêm', 'Quận 2', 'TP.HCM', false, 'office');

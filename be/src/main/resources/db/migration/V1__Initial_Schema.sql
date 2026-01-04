-- Smart Grocery Database Schema
-- Version 1: Initial Schema

-- ============================================
-- 1. USERS & AUTHENTICATION
-- ============================================

CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255)
);

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    fcm_token VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_roles (
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- ============================================
-- 2. MASTER DATA (CATEGORIES & PRODUCTS)
-- ============================================

CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    icon_url VARCHAR(500),
    description VARCHAR(255),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE master_products (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    image_url VARCHAR(500),
    default_unit VARCHAR(50) NOT NULL,
    avg_shelf_life INTEGER,
    description VARCHAR(500),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE product_categories (
    product_id BIGINT NOT NULL REFERENCES master_products(id) ON DELETE CASCADE,
    category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, category_id)
);

CREATE INDEX idx_master_products_name ON master_products(name);
CREATE INDEX idx_categories_name ON categories(name);

-- ============================================
-- 3. FAMILY & MEMBERS
-- ============================================

CREATE TABLE families (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    invite_code VARCHAR(10) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE family_members (
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    nickname VARCHAR(50),
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (family_id, user_id)
);

CREATE INDEX idx_families_invite_code ON families(invite_code);
CREATE INDEX idx_family_members_user_id ON family_members(user_id);

-- ============================================
-- 4. SHOPPING LISTS
-- ============================================

CREATE TABLE shopping_lists (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'PLANNING',
    created_by BIGINT NOT NULL REFERENCES users(id),
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE shopping_items (
    id BIGSERIAL PRIMARY KEY,
    list_id BIGINT NOT NULL REFERENCES shopping_lists(id) ON DELETE CASCADE,
    master_product_id BIGINT REFERENCES master_products(id),
    custom_product_name VARCHAR(200),
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 1,
    unit VARCHAR(50) NOT NULL,
    is_bought BOOLEAN NOT NULL DEFAULT FALSE,
    note VARCHAR(255),
    price DECIMAL(12, 2),
    assigned_to BIGINT REFERENCES users(id),
    bought_by BIGINT REFERENCES users(id),
    version BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shopping_lists_family_id ON shopping_lists(family_id);
CREATE INDEX idx_shopping_lists_status ON shopping_lists(status);
CREATE INDEX idx_shopping_items_list_id ON shopping_items(list_id);

-- ============================================
-- 5. FRIDGE INVENTORY
-- ============================================

CREATE TABLE fridge_items (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    master_product_id BIGINT REFERENCES master_products(id),
    custom_product_name VARCHAR(200),
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 1,
    unit VARCHAR(50) NOT NULL,
    expiration_date DATE,
    location VARCHAR(20) NOT NULL DEFAULT 'COOLER',
    status VARCHAR(20) NOT NULL DEFAULT 'FRESH',
    note VARCHAR(255),
    added_by BIGINT NOT NULL REFERENCES users(id),
);

CREATE INDEX idx_fridge_items_family_id ON fridge_items(family_id);
CREATE INDEX idx_fridge_items_expiration_date ON fridge_items(expiration_date);
CREATE INDEX idx_fridge_items_status ON fridge_items(status);

-- ============================================
-- 6. RECIPES
-- ============================================

CREATE TABLE recipes (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description VARCHAR(500),
    instructions TEXT,
    difficulty VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    prep_time INTEGER,
    cook_time INTEGER,
    servings INTEGER DEFAULT 2,
    image_url VARCHAR(500),
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE recipe_ingredients (
    id BIGSERIAL PRIMARY KEY,
    recipe_id BIGINT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
    master_product_id BIGINT REFERENCES master_products(id),
    custom_ingredient_name VARCHAR(200),
    quantity DECIMAL(10, 2) NOT NULL DEFAULT 1,
    unit VARCHAR(50) NOT NULL,
    note VARCHAR(255),
    is_optional BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_recipes_title ON recipes(title);
CREATE INDEX idx_recipes_is_public ON recipes(is_public);
CREATE INDEX idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id);

-- ============================================
-- 7. MEAL PLANNING
-- ============================================

CREATE TABLE meal_plans (
    id BIGSERIAL PRIMARY KEY,
    family_id BIGINT NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    meal_type VARCHAR(20) NOT NULL,
    note VARCHAR(500),
    created_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_meal_plan_family_date_type UNIQUE (family_id, date, meal_type)
);

CREATE TABLE meal_items (
    id BIGSERIAL PRIMARY KEY,
    meal_plan_id BIGINT NOT NULL REFERENCES meal_plans(id) ON DELETE CASCADE,
    recipe_id BIGINT REFERENCES recipes(id),
    custom_dish_name VARCHAR(200),
    servings INTEGER DEFAULT 1,
    order_index INTEGER NOT NULL DEFAULT 0,
    note VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_meal_plans_family_id ON meal_plans(family_id);
CREATE INDEX idx_meal_plans_date ON meal_plans(date);
CREATE INDEX idx_meal_items_meal_plan_id ON meal_items(meal_plan_id);

-- ============================================
-- 8. INITIAL DATA
-- ============================================

-- Insert default roles
INSERT INTO roles (name, description) VALUES
    ('ADMIN', 'System administrator with full access'),
    ('USER', 'Regular user with standard access');

-- Insert default admin user (password: 123456)
-- BCrypt hash của '123456'
INSERT INTO users (username, email, password_hash, full_name, is_active, created_at, updated_at) VALUES
    ('admin', 'admin@smartgrocery.com', '$2a$10$9zGlWWg/P8JzAnES/Is4hemnmW4VE9B7P6k9lhHfOfUKuVnw/jjyS', 'System Admin', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Assign ADMIN role to admin user
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'ADMIN';

-- Also assign USER role to admin
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id FROM users u, roles r
WHERE u.username = 'admin' AND r.name = 'USER';

-- Insert sample categories
INSERT INTO categories (name, icon_url, description, display_order) VALUES
    ('Rau củ quả', '🥬', 'Các loại rau, củ, quả tươi', 1),
    ('Trái cây', '🍎', 'Các loại trái cây tươi', 2),
    ('Thịt', '🥩', 'Thịt heo, bò, gà và các loại thịt khác', 3),
    ('Hải sản', '🦐', 'Cá, tôm, cua, mực và hải sản', 4),
    ('Sữa & Trứng', '🥛', 'Sữa, trứng, phô mai và sản phẩm từ sữa', 5),
    ('Gia vị', '🧂', 'Muối, đường, nước mắm, gia vị nấu ăn', 6),
    ('Đồ khô', '🍚', 'Gạo, mì, bún, miến, đồ khô', 7),
    ('Đồ uống', '🧃', 'Nước ngọt, nước trái cây, cà phê, trà', 8),
    ('Đồ đông lạnh', '🧊', 'Thực phẩm đông lạnh', 9),
    ('Đồ hộp', '🥫', 'Thực phẩm đóng hộp', 10);

-- Insert sample master products
INSERT INTO master_products (name, default_unit, avg_shelf_life, description) VALUES
    ('Thịt heo', 'kg', 3, 'Thịt heo tươi'),
    ('Thịt bò', 'kg', 3, 'Thịt bò tươi'),
    ('Thịt gà', 'kg', 3, 'Thịt gà tươi'),
    ('Cá hồi', 'kg', 2, 'Cá hồi tươi'),
    ('Tôm sú', 'kg', 2, 'Tôm sú tươi'),
    ('Trứng gà', 'vỉ', 14, 'Trứng gà ta'),
    ('Sữa tươi', 'lít', 7, 'Sữa tươi tiệt trùng'),
    ('Rau muống', 'bó', 2, 'Rau muống tươi'),
    ('Cà chua', 'kg', 5, 'Cà chua tươi'),
    ('Hành lá', 'bó', 3, 'Hành lá tươi'),
    ('Tỏi', 'củ', 30, 'Tỏi tươi'),
    ('Gừng', 'củ', 14, 'Gừng tươi'),
    ('Gạo', 'kg', 180, 'Gạo trắng'),
    ('Mì gói', 'gói', 180, 'Mì ăn liền'),
    ('Nước mắm', 'chai', 365, 'Nước mắm'),
    ('Dầu ăn', 'lít', 365, 'Dầu ăn thực vật'),
    ('Muối', 'gói', 730, 'Muối tinh'),
    ('Đường', 'kg', 730, 'Đường trắng'),
    ('Táo', 'kg', 14, 'Táo tươi'),
    ('Cam', 'kg', 10, 'Cam tươi');

-- Link products to categories
INSERT INTO product_categories (product_id, category_id)
SELECT p.id, c.id FROM master_products p, categories c
WHERE (p.name = 'Thịt heo' AND c.name = 'Thịt')
   OR (p.name = 'Thịt bò' AND c.name = 'Thịt')
   OR (p.name = 'Thịt gà' AND c.name = 'Thịt')
   OR (p.name = 'Cá hồi' AND c.name = 'Hải sản')
   OR (p.name = 'Tôm sú' AND c.name = 'Hải sản')
   OR (p.name = 'Trứng gà' AND c.name = 'Sữa & Trứng')
   OR (p.name = 'Sữa tươi' AND c.name = 'Sữa & Trứng')
   OR (p.name = 'Rau muống' AND c.name = 'Rau củ quả')
   OR (p.name = 'Cà chua' AND c.name = 'Rau củ quả')
   OR (p.name = 'Hành lá' AND c.name = 'Rau củ quả')
   OR (p.name = 'Tỏi' AND c.name = 'Gia vị')
   OR (p.name = 'Gừng' AND c.name = 'Gia vị')
   OR (p.name = 'Gạo' AND c.name = 'Đồ khô')
   OR (p.name = 'Mì gói' AND c.name = 'Đồ khô')
   OR (p.name = 'Nước mắm' AND c.name = 'Gia vị')
   OR (p.name = 'Dầu ăn' AND c.name = 'Gia vị')
   OR (p.name = 'Muối' AND c.name = 'Gia vị')
   OR (p.name = 'Đường' AND c.name = 'Gia vị')
   OR (p.name = 'Táo' AND c.name = 'Trái cây')
   OR (p.name = 'Cam' AND c.name = 'Trái cây');


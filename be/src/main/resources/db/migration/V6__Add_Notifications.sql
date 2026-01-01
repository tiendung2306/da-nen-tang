-- Smart Grocery Database Schema
-- Version 6: Add Notifications System

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL DEFAULT 'GENERAL',
    reference_type VARCHAR(50),
    reference_id BIGINT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;

-- Add comment for documentation
COMMENT ON TABLE notifications IS 'Stores user notifications including fridge expiry alerts, family invites, friend requests, etc.';
COMMENT ON COLUMN notifications.type IS 'Type of notification: GENERAL, FAMILY_INVITE, FRIEND_REQUEST, FRIDGE_EXPIRY, SHOPPING_REMINDER, MEAL_PLAN';
COMMENT ON COLUMN notifications.reference_type IS 'Type of referenced entity: FAMILY, FRIEND_REQUEST, FRIDGE_ITEM, SHOPPING_LIST, etc.';
COMMENT ON COLUMN notifications.reference_id IS 'ID of the referenced entity for navigation purposes';

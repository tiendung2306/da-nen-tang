-- Add assigned_to column to shopping_lists table
ALTER TABLE shopping_lists
ADD COLUMN assigned_to BIGINT NULL;

-- Add foreign key constraint
ALTER TABLE shopping_lists
ADD CONSTRAINT fk_shopping_list_assigned_to
FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL;

-- Add index for better query performance
CREATE INDEX idx_shopping_list_assigned_to ON shopping_lists(assigned_to);

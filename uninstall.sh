#!/bin/bash

# Pterodactyl AI Chat Integration Uninstaller
# This script removes all files installed by the AI Chat addon

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default Pterodactyl path
PTERODACTYL_PATH="/var/www/pterodactyl"

echo -e "${BLUE}=== Pterodactyl AI Chat Integration Uninstaller ===${NC}"
echo ""

# Get Pterodactyl path
read -p "Enter your Pterodactyl installation path [$PTERODACTYL_PATH]: " input_path
PTERODACTYL_PATH=${input_path:-$PTERODACTYL_PATH}

# Verify Pterodactyl installation
if [ ! -f "$PTERODACTYL_PATH/artisan" ]; then
    echo -e "${RED}Error: Pterodactyl installation not found at $PTERODACTYL_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found Pterodactyl installation at $PTERODACTYL_PATH${NC}"

# Remove all AI Chat addon files
echo -e "${YELLOW}Removing AI Chat addon files...${NC}"

# Backend files to remove
BACKEND_FILES=(
    "$PTERODACTYL_PATH/app/Http/Controllers/Admin/AiSettingsController.php"
    "$PTERODACTYL_PATH/app/Http/Controllers/Api/Client/Servers/AiChatController.php"
    "$PTERODACTYL_PATH/app/Http/Requests/Api/Client/Servers/AiChatRequest.php"
    "$PTERODACTYL_PATH/app/Services/Servers/AiChatService.php"
    "$PTERODACTYL_PATH/app/Repositories/Wings/DaemonConsoleRepository.php"
    "$PTERODACTYL_PATH/resources/views/admin/ai/index.blade.php"
)

# Frontend files to remove
FRONTEND_FILES=(
    "$PTERODACTYL_PATH/resources/scripts/api/server/ai.ts"
    "$PTERODACTYL_PATH/resources/scripts/components/server/ai/AiChatContainer.tsx"
)

# Remove backend files
for file in "${BACKEND_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "  ✓ Removed $(basename "$file")"
    fi
done

# Remove frontend files
for file in "${FRONTEND_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        echo "  ✓ Removed $(basename "$file")"
    fi
done

# Remove empty directories
if [ -d "$PTERODACTYL_PATH/resources/views/admin/ai" ]; then
    rmdir "$PTERODACTYL_PATH/resources/views/admin/ai" 2>/dev/null || true
    echo "  ✓ Removed admin/ai directory"
fi

if [ -d "$PTERODACTYL_PATH/resources/scripts/components/server/ai" ]; then
    rmdir "$PTERODACTYL_PATH/resources/scripts/components/server/ai" 2>/dev/null || true
    echo "  ✓ Removed server/ai directory"
fi

echo -e "${GREEN}✓ AI Chat addon files removed${NC}"

# Revert configuration changes
echo -e "${YELLOW}Reverting configuration changes...${NC}"

# Remove Gemini config from services.php
if [ -f "$PTERODACTYL_PATH/config/services.php" ]; then
    if grep -q "gemini" "$PTERODACTYL_PATH/config/services.php"; then
        # Remove the gemini configuration block
        sed -i '/'\''gemini'\'' => \[/,/\],/d' "$PTERODACTYL_PATH/config/services.php"
        echo "  ✓ Removed Gemini config from services.php"
    fi
fi

# Remove AI routes from api-client.php
if [ -f "$PTERODACTYL_PATH/routes/api-client.php" ]; then
    if grep -q "AiChatController" "$PTERODACTYL_PATH/routes/api-client.php"; then
        # Remove the import
        sed -i '/use Pterodactyl\\Http\\Controllers\\Api\\Client\\Servers\\AiChatController;/d' "$PTERODACTYL_PATH/routes/api-client.php"
        
        # Remove the AI routes block
        sed -i '/Route::group.*prefix.*ai/,/});/d' "$PTERODACTYL_PATH/routes/api-client.php"
        echo "  ✓ Removed AI routes from api-client.php"
    fi
fi

# Remove AI routes from admin.php
if [ -f "$PTERODACTYL_PATH/routes/admin.php" ]; then
    if grep -q "AiSettingsController" "$PTERODACTYL_PATH/routes/admin.php"; then
        # Remove the import
        sed -i '/use Pterodactyl\\Http\\Controllers\\Admin\\AiSettingsController;/d' "$PTERODACTYL_PATH/routes/admin.php"
        
        # Remove the AI Settings Controller Routes block
        sed -i '/AI Settings Controller Routes/,/});/d' "$PTERODACTYL_PATH/routes/admin.php"
        
        # Remove the comment block before it
        sed -i '/|--------------------------------------------------------------------------/,/\*\//d' "$PTERODACTYL_PATH/routes/admin.php"
        echo "  ✓ Removed AI routes from admin.php"
    fi
fi

# Remove AI menu item from admin layout
if [ -f "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php" ]; then
    if grep -q "AI Settings" "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php"; then
        # Remove the AI Settings menu item
        sed -i '/AI Settings/,/<\/li>/d' "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php"
        echo "  ✓ Removed AI Settings menu from admin layout"
    fi
fi

echo -e "${GREEN}✓ Configuration changes reverted${NC}"

# Restore original routes.ts from backup if it exists
echo -e "${YELLOW}Restoring original routes.ts...${NC}"

# Find the most recent backup
BACKUP_DIR=$(find "$HOME" -name "pterodactyl-backup-*" -type d | sort -r | head -n 1)

if [ -n "$BACKUP_DIR" ] && [ -f "$BACKUP_DIR/resources/scripts/routers/routes.ts" ]; then
    cp "$BACKUP_DIR/resources/scripts/routers/routes.ts" "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"
    echo "  ✓ Restored original routes.ts from backup"
else
    echo -e "${YELLOW}  ⚠ No backup found. You may need to manually restore routes.ts${NC}"
    echo -e "${YELLOW}    Or reinstall Pterodactyl to get the original routes.ts${NC}"
fi

# Clear Laravel cache
echo -e "${YELLOW}Clearing Laravel cache...${NC}"
cd "$PTERODACTYL_PATH"
php artisan config:clear
php artisan cache:clear
php artisan view:clear
echo -e "${GREEN}✓ Laravel cache cleared${NC}"

# Remove GEMINI_API_KEY from .env if it exists
if [ -f "$PTERODACTYL_PATH/.env" ]; then
    if grep -q "GEMINI_API_KEY" "$PTERODACTYL_PATH/.env"; then
        sed -i '/GEMINI_API_KEY/d' "$PTERODACTYL_PATH/.env"
        echo "  ✓ Removed GEMINI_API_KEY from .env"
    fi
fi

echo ""
echo -e "${GREEN}=== Uninstallation Complete! ===${NC}"
echo ""
echo -e "${BLUE}AI Chat Integration has been completely removed.${NC}"
echo ""
echo -e "${YELLOW}Note: You may want to rebuild your frontend assets:${NC}"
echo "cd $PTERODACTYL_PATH && yarn build:production"
echo ""
echo -e "${GREEN}✓ All AI Chat addon files and configurations have been removed!${NC}"
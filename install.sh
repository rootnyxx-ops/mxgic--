#!/bin/bash

# Pterodactyl AI Chat Integration Installer
# Run this script from the addon directory

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default Pterodactyl path
PTERODACTYL_PATH="/var/www/pterodactyl"

echo -e "${BLUE}=== Pterodactyl AI Chat Integration Installer ===${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root${NC}"
   exit 1
fi

# Check if we're in the right directory
if [ ! -f "app/Services/Servers/AiChatService.php" ]; then
    echo -e "${RED}Error: Please run this script from the addon directory${NC}"
    echo "Make sure you have all the addon files in the current directory"
    exit 1
fi

# Get Pterodactyl path
read -p "Enter your Pterodactyl installation path [$PTERODACTYL_PATH]: " input_path
PTERODACTYL_PATH=${input_path:-$PTERODACTYL_PATH}

# Verify Pterodactyl installation
if [ ! -f "$PTERODACTYL_PATH/artisan" ]; then
    echo -e "${RED}Error: Pterodactyl installation not found at $PTERODACTYL_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found Pterodactyl installation at $PTERODACTYL_PATH${NC}"

# Create backup
echo -e "${YELLOW}Creating backup...${NC}"
BACKUP_DIR="$HOME/pterodactyl-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup files that will be modified
[ -f "$PTERODACTYL_PATH/routes/api-client.php" ] && cp "$PTERODACTYL_PATH/routes/api-client.php" "$BACKUP_DIR/"
[ -f "$PTERODACTYL_PATH/routes/admin.php" ] && cp "$PTERODACTYL_PATH/routes/admin.php" "$BACKUP_DIR/"
[ -f "$PTERODACTYL_PATH/config/services.php" ] && cp "$PTERODACTYL_PATH/config/services.php" "$BACKUP_DIR/"
[ -f "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts" ] && cp "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts" "$BACKUP_DIR/"
[ -f "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php" ] && cp "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php" "$BACKUP_DIR/"

echo -e "${GREEN}✓ Backup created at $BACKUP_DIR${NC}"

# Install backend files
echo -e "${YELLOW}Installing backend files...${NC}"

# Create directories
sudo mkdir -p "$PTERODACTYL_PATH/app/Http/Controllers/Admin"
sudo mkdir -p "$PTERODACTYL_PATH/app/Http/Controllers/Api/Client/Servers"
sudo mkdir -p "$PTERODACTYL_PATH/app/Http/Requests/Api/Client/Servers"
sudo mkdir -p "$PTERODACTYL_PATH/app/Services/Servers"
sudo mkdir -p "$PTERODACTYL_PATH/app/Repositories/Wings"
sudo mkdir -p "$PTERODACTYL_PATH/resources/views/admin/ai"

# Copy backend files
sudo cp "app/Http/Controllers/Admin/AiSettingsController.php" "$PTERODACTYL_PATH/app/Http/Controllers/Admin/"
sudo cp "app/Http/Controllers/Api/Client/Servers/AiChatController.php" "$PTERODACTYL_PATH/app/Http/Controllers/Api/Client/Servers/"
sudo cp "app/Http/Requests/Api/Client/Servers/AiChatRequest.php" "$PTERODACTYL_PATH/app/Http/Requests/Api/Client/Servers/"
sudo cp "app/Services/Servers/AiChatService.php" "$PTERODACTYL_PATH/app/Services/Servers/"
sudo cp "app/Repositories/Wings/DaemonConsoleRepository.php" "$PTERODACTYL_PATH/app/Repositories/Wings/"
sudo cp "resources/views/admin/ai/index.blade.php" "$PTERODACTYL_PATH/resources/views/admin/ai/"

echo -e "${GREEN}✓ Backend files installed${NC}"

# Install frontend files
echo -e "${YELLOW}Installing frontend files...${NC}"

sudo mkdir -p "$PTERODACTYL_PATH/resources/scripts/api/server"
sudo mkdir -p "$PTERODACTYL_PATH/resources/scripts/components/server/ai"

sudo cp "resources/scripts/api/server/ai.ts" "$PTERODACTYL_PATH/resources/scripts/api/server/"
sudo cp "resources/scripts/components/server/ai/AiChatContainer.tsx" "$PTERODACTYL_PATH/resources/scripts/components/server/ai/"

echo -e "${GREEN}✓ Frontend files installed${NC}"

# Update configuration files
echo -e "${YELLOW}Updating configuration files...${NC}"

# Update services.php - add Gemini config before the closing ];
if ! grep -q "gemini" "$PTERODACTYL_PATH/config/services.php"; then
    sudo sed -i "/^];$/i\\    'gemini' => [\\n        'api_key' => env('GEMINI_API_KEY'),\\n    ]," "$PTERODACTYL_PATH/config/services.php"
    echo -e "${GREEN}✓ Updated config/services.php${NC}"
else
    echo -e "${YELLOW}⚠ Gemini config already exists in services.php${NC}"
fi

# Update API routes - add AI routes to the servers group
if ! grep -q "AiChatController" "$PTERODACTYL_PATH/routes/api-client.php"; then
    # Add import after the existing Client import
    sudo sed -i '/use Pterodactyl\\Http\\Controllers\\Api\\Client;/a use Pterodactyl\\Http\\Controllers\\Api\\Client\\Servers\\AiChatController;' "$PTERODACTYL_PATH/routes/api-client.php"
    
    # Add AI routes before the closing }); of the servers group
    sudo sed -i '/Route::group.*prefix.*settings/i\    Route::group(['\''prefix'\'' => '\''ai'\''], function () {\
        Route::post('\''/chat'\'', [AiChatController::class, '\''chat'\'']);\
        Route::get('\''/history'\'', [AiChatController::class, '\''history'\'']);\
    });' "$PTERODACTYL_PATH/routes/api-client.php"
    echo -e "${GREEN}✓ Updated API routes${NC}"
else
    echo -e "${YELLOW}⚠ AI routes already exist${NC}"
fi

# Update admin routes
if [ -f "$PTERODACTYL_PATH/routes/admin.php" ] && ! grep -q "AiSettingsController" "$PTERODACTYL_PATH/routes/admin.php"; then
    # Add import after existing Admin import
    sudo sed -i '/use Pterodactyl\\Http\\Controllers\\Admin;/a use Pterodactyl\\Http\\Controllers\\Admin\\AiSettingsController;' "$PTERODACTYL_PATH/routes/admin.php"
    
    # Add routes at the end of file
    echo "" | sudo tee -a "$PTERODACTYL_PATH/routes/admin.php" > /dev/null
    echo "Route::group(['prefix' => 'ai'], function () {" | sudo tee -a "$PTERODACTYL_PATH/routes/admin.php" > /dev/null
    echo "    Route::get('/', [AiSettingsController::class, 'index'])->name('admin.ai.index');" | sudo tee -a "$PTERODACTYL_PATH/routes/admin.php" > /dev/null
    echo "    Route::post('/', [AiSettingsController::class, 'update'])->name('admin.ai.update');" | sudo tee -a "$PTERODACTYL_PATH/routes/admin.php" > /dev/null
    echo "});" | sudo tee -a "$PTERODACTYL_PATH/routes/admin.php" > /dev/null
    echo -e "${GREEN}✓ Updated admin routes${NC}"
fi

# Update admin layout - add AI menu item
if [ -f "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php" ] && ! grep -q "AI Settings" "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php"; then
    # Add AI Settings menu item after Settings in the BASIC ADMINISTRATION section
    sudo sed -i '/admin\.settings.*Settings/a\                        <li class="{{ ! starts_with(Route::currentRouteName(), '\''admin.ai'\'') ?: '\''active'\'' }}">\
                            <a href="{{ route('\''admin.ai.index'\'')}}\">\
                                <i class="fa fa-robot"></i> <span>AI Settings</span>\
                            </a>\
                        </li>' "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php"
    echo -e "${GREEN}✓ Updated admin navigation${NC}"
fi

# Update frontend routes
if [ -f "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts" ]; then
    if ! grep -q "AiChatContainer" "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"; then
        # Add import after existing lazy imports
        sudo sed -i '/const.*lazy.*import/a const AiChatContainer = lazy(() => import('\''@/components/server/ai/AiChatContainer'\''));' "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"
        
        # Add route to server array before the closing bracket
        sudo sed -i '/server:.*\[/,/    \],/{
            /    \],/{
                i\        {\
                i\            path: '\''/ai'\'',\
                i\            permission: null,\
                i\            name: '\''AI Assistant'\'',\
                i\            component: AiChatContainer,\
                i\            exact: true,\
                i\        },
            }
        }' "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"
        echo -e "${GREEN}✓ Updated frontend routes${NC}"
    fi
else
    # Copy our routes file if it doesn't exist
    sudo cp "resources/scripts/routers/routes.ts" "$PTERODACTYL_PATH/resources/scripts/routers/"
    echo -e "${GREEN}✓ Created frontend routes${NC}"
fi

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"
sudo chown -R www-data:www-data "$PTERODACTYL_PATH/app/Http/Controllers/Admin/AiSettingsController.php"
sudo chown -R www-data:www-data "$PTERODACTYL_PATH/app/Http/Controllers/Api/Client/Servers/AiChatController.php"
sudo chown -R www-data:www-data "$PTERODACTYL_PATH/app/Http/Requests/Api/Client/Servers/AiChatRequest.php"
sudo chown -R www-data:www-data "$PTERODACTYL_PATH/app/Services/Servers/AiChatService.php"
sudo chown -R www-data:www-data "$PTERODACTYL_PATH/app/Repositories/Wings/DaemonConsoleRepository.php"
sudo chown -R www-data:www-data "$PTERODACTYL_PATH/resources/views/admin/ai/"
sudo chown -R www-data:www-data "$PTERODACTYL_PATH/resources/scripts/api/server/ai.ts"
sudo chown -R www-data:www-data "$PTERODACTYL_PATH/resources/scripts/components/server/ai/"

echo -e "${GREEN}✓ Permissions set${NC}"

# Clear caches
echo -e "${YELLOW}Clearing Laravel caches...${NC}"
cd "$PTERODACTYL_PATH"
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan route:clear
sudo -u www-data php artisan cache:clear

echo -e "${GREEN}✓ Caches cleared${NC}"

# Build frontend
echo -e "${YELLOW}Building frontend (this may take a few minutes)...${NC}"
if command -v yarn &> /dev/null; then
    sudo -u www-data yarn install --production
    sudo -u www-data yarn build:production
elif command -v npm &> /dev/null; then
    sudo -u www-data npm install --production
    sudo -u www-data npm run build:production
else
    echo -e "${RED}Error: Neither yarn nor npm found. Please install Node.js and npm/yarn${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Frontend built successfully${NC}"

# Final instructions
echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Get your Gemini API key from: https://makersuite.google.com/app/apikey"
echo "2. Add to your .env file: GEMINI_API_KEY=your_api_key_here"
echo "3. Or configure via admin panel: /admin/ai"
echo "4. Access AI chat at: /server/{server-id}/ai"
echo ""
echo -e "${YELLOW}Backup location: $BACKUP_DIR${NC}"
echo ""
echo -e "${GREEN}🎉 AI Chat Integration installed successfully!${NC}"
echo ""
echo -e "${BLUE}Features installed:${NC}"
echo "✓ AI Chat with Gemini integration"
echo "✓ File content reading"
echo "✓ Console log access (if supported by Wings)"
echo "✓ Admin settings panel"
echo "✓ Chat history"
echo "✓ Permission-based access"
#!/bin/bash

# Pterodactyl AI Chat Integration Installer
# Usage: git clone https://github.com/rootnyxx-ops/mxgic-- && cd mxgic-- && chmod +x install.sh && ./install.sh

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
FILES_TO_BACKUP=(
    "routes/api-client.php"
    "routes/admin.php"
    "config/services.php"
    "resources/scripts/routers/routes.ts"
    "resources/views/layouts/admin.blade.php"
)

for file in "${FILES_TO_BACKUP[@]}"; do
    if [ -f "$PTERODACTYL_PATH/$file" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        cp "$PTERODACTYL_PATH/$file" "$BACKUP_DIR/$file"
        echo "  ✓ Backed up $file"
    fi
done

echo -e "${GREEN}✓ Backup created at $BACKUP_DIR${NC}"

# Function to safely copy files with error checking
safe_copy() {
    local src="$1"
    local dest="$2"
    
    if [ ! -f "$src" ]; then
        echo -e "${RED}Error: Source file $src not found${NC}"
        return 1
    fi
    
    sudo mkdir -p "$(dirname "$dest")"
    if sudo cp "$src" "$dest"; then
        echo "  ✓ Copied $(basename "$src")"
        return 0
    else
        echo -e "${RED}Error: Failed to copy $src to $dest${NC}"
        return 1
    fi
}

# Install backend files
echo -e "${YELLOW}Installing backend files...${NC}"

# Backend file mappings
declare -A BACKEND_FILES=(
    ["app/Http/Controllers/Admin/AiSettingsController.php"]="$PTERODACTYL_PATH/app/Http/Controllers/Admin/AiSettingsController.php"
    ["app/Http/Controllers/Api/Client/Servers/AiChatController.php"]="$PTERODACTYL_PATH/app/Http/Controllers/Api/Client/Servers/AiChatController.php"
    ["app/Http/Requests/Api/Client/Servers/AiChatRequest.php"]="$PTERODACTYL_PATH/app/Http/Requests/Api/Client/Servers/AiChatRequest.php"
    ["app/Services/Servers/AiChatService.php"]="$PTERODACTYL_PATH/app/Services/Servers/AiChatService.php"
    ["app/Repositories/Wings/DaemonConsoleRepository.php"]="$PTERODACTYL_PATH/app/Repositories/Wings/DaemonConsoleRepository.php"
    ["resources/views/admin/ai/index.blade.php"]="$PTERODACTYL_PATH/resources/views/admin/ai/index.blade.php"
)

for src in "${!BACKEND_FILES[@]}"; do
    safe_copy "$src" "${BACKEND_FILES[$src]}" || exit 1
done

echo -e "${GREEN}✓ Backend files installed${NC}"

# Install frontend files
echo -e "${YELLOW}Installing frontend files...${NC}"

declare -A FRONTEND_FILES=(
    ["resources/scripts/api/server/ai.ts"]="$PTERODACTYL_PATH/resources/scripts/api/server/ai.ts"
    ["resources/scripts/components/server/ai/AiChatContainer.tsx"]="$PTERODACTYL_PATH/resources/scripts/components/server/ai/AiChatContainer.tsx"
)

for src in "${!FRONTEND_FILES[@]}"; do
    safe_copy "$src" "${FRONTEND_FILES[$src]}" || exit 1
done

echo -e "${GREEN}✓ Frontend files installed${NC}"

# Update configuration files
echo -e "${YELLOW}Updating configuration files...${NC}"

# Update services.php - add Gemini config before the closing ];
if [ -f "$PTERODACTYL_PATH/config/services.php" ]; then
    if ! grep -q "gemini" "$PTERODACTYL_PATH/config/services.php"; then
        # Insert before the closing ]; - more reliable method
        sudo sed -i '/^];$/i\    '\''gemini'\'' => [\n        '\''api_key'\'' => env('\''GEMINI_API_KEY'\''),\n    ],' "$PTERODACTYL_PATH/config/services.php"
        echo "  ✓ Updated config/services.php"
    else
        echo -e "${YELLOW}⚠ Gemini config already exists in services.php${NC}"
    fi
fi

# Update API routes - add AI routes to the servers group
if [ -f "$PTERODACTYL_PATH/routes/api-client.php" ]; then
    if ! grep -q "AiChatController" "$PTERODACTYL_PATH/routes/api-client.php"; then
        # Add import after the existing Client import
        sudo sed -i '/use Pterodactyl\\Http\\Controllers\\Api\\Client;/a use Pterodactyl\\Http\\Controllers\\Api\\Client\\Servers\\AiChatController;' "$PTERODACTYL_PATH/routes/api-client.php"
        
        # Add AI routes before the settings group - this is the correct location based on actual structure
        sudo sed -i '/Route::group.*prefix.*settings/i\    Route::group(['\''prefix'\'' => '\''ai'\''], function () {\n        Route::post('\''/chat'\'', [AiChatController::class, '\''chat'\'']);\n        Route::get('\''/history'\'', [AiChatController::class, '\''history'\'']);\n    });\n' "$PTERODACTYL_PATH/routes/api-client.php"
        echo "  ✓ Updated API routes"
    else
        echo -e "${YELLOW}⚠ AI routes already exist${NC}"
    fi
fi

# Update admin routes
if [ -f "$PTERODACTYL_PATH/routes/admin.php" ]; then
    if ! grep -q "AiSettingsController" "$PTERODACTYL_PATH/routes/admin.php"; then
        # Add import after existing Admin import
        sudo sed -i '/use Pterodactyl\\Http\\Controllers\\Admin;/a use Pterodactyl\\Http\\Controllers\\Admin\\AiSettingsController;' "$PTERODACTYL_PATH/routes/admin.php"
        
        # Add routes at the end - following Pterodactyl's comment style
        {
            echo ""
            echo "/*"
            echo "|--------------------------------------------------------------------------"
            echo "| AI Settings Controller Routes"
            echo "|--------------------------------------------------------------------------"
            echo "|"
            echo "| Endpoint: /admin/ai"
            echo "|"
            echo "*/"
            echo "Route::group(['prefix' => 'ai'], function () {"
            echo "    Route::get('/', [AiSettingsController::class, 'index'])->name('admin.ai.index');"
            echo "    Route::post('/', [AiSettingsController::class, 'update'])->name('admin.ai.update');"
            echo "});"
        } | sudo tee -a "$PTERODACTYL_PATH/routes/admin.php" > /dev/null
        echo "  ✓ Updated admin routes"
    else
        echo -e "${YELLOW}⚠ Admin AI routes already exist${NC}"
    fi
fi

# Update admin layout - add AI menu item in BASIC ADMINISTRATION section
if [ -f "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php" ]; then
    if ! grep -q "AI Settings" "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php"; then
        # Add AI Settings menu item after Settings in BASIC ADMINISTRATION section
        sudo sed -i '/admin\.settings.*Settings/a\                        <li class="{{ ! starts_with(Route::currentRouteName(), '\''admin.ai'\'') ?: '\''active'\'' }}">\n                            <a href="{{ route('\''admin.ai.index'\'')}}\">\n                                <i class="fa fa-robot"></i> <span>AI Settings</span>\n                            </a>\n                        </li>' "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php"
        echo "  ✓ Updated admin navigation"
    else
        echo -e "${YELLOW}⚠ AI Settings menu already exists${NC}"
    fi
fi

# Update frontend routes (if routes.ts exists)
if [ -f "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts" ]; then
    if ! grep -q "AiChatContainer" "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"; then
        # Add import after existing lazy imports
        sudo sed -i '/const.*lazy.*import/a const AiChatContainer = lazy(() => import('\''@/components/server/ai/AiChatContainer'\''));' "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"
        
        # Add route to server routes array
        sudo sed -i '/server:.*\\[/,/    \\],/{
            /    \\],/{
                i\        {\
                i\            path: '\''/ai'\'',\
                i\            permission: null,\
                i\            name: '\''AI Assistant'\'',\
                i\            component: AiChatContainer,\
                i\            exact: true,\
                i\        },
            }
        }' "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"
        echo "  ✓ Updated frontend routes"
    else
        echo -e "${YELLOW}⚠ Frontend AI routes already exist${NC}"
    fi
else
    # Copy our routes file if it doesn't exist
    if [ -f "resources/scripts/routers/routes.ts" ]; then
        safe_copy "resources/scripts/routers/routes.ts" "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"
        echo "  ✓ Created frontend routes"
    fi
fi

echo -e "${GREEN}✓ Configuration files updated${NC}"

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"

ALL_FILES=(
    "$PTERODACTYL_PATH/app/Http/Controllers/Admin/AiSettingsController.php"
    "$PTERODACTYL_PATH/app/Http/Controllers/Api/Client/Servers/AiChatController.php"
    "$PTERODACTYL_PATH/app/Http/Requests/Api/Client/Servers/AiChatRequest.php"
    "$PTERODACTYL_PATH/app/Services/Servers/AiChatService.php"
    "$PTERODACTYL_PATH/app/Repositories/Wings/DaemonConsoleRepository.php"
    "$PTERODACTYL_PATH/resources/views/admin/ai/"
    "$PTERODACTYL_PATH/resources/scripts/api/server/ai.ts"
    "$PTERODACTYL_PATH/resources/scripts/components/server/ai/"
)

for file in "${ALL_FILES[@]}"; do
    if [ -e "$file" ]; then
        sudo chown -R www-data:www-data "$file"
    fi
done

echo -e "${GREEN}✓ Permissions set${NC}"

# Clear caches
echo -e "${YELLOW}Clearing Laravel caches...${NC}"
cd "$PTERODACTYL_PATH"

if sudo -u www-data php artisan config:clear; then
    echo "  ✓ Config cache cleared"
else
    echo -e "${YELLOW}⚠ Failed to clear config cache${NC}"
fi

if sudo -u www-data php artisan route:clear; then
    echo "  ✓ Route cache cleared"
else
    echo -e "${YELLOW}⚠ Failed to clear route cache${NC}"
fi

if sudo -u www-data php artisan cache:clear; then
    echo "  ✓ Application cache cleared"
else
    echo -e "${YELLOW}⚠ Failed to clear application cache${NC}"
fi

echo -e "${GREEN}✓ Caches cleared${NC}"

# Build frontend
echo -e "${YELLOW}Building frontend (this may take a few minutes)...${NC}"

# Check for package manager and build
if command -v yarn &> /dev/null; then
    echo "  Using Yarn..."
    if sudo -u www-data yarn install --production --frozen-lockfile; then
        echo "  ✓ Dependencies installed"
        if sudo -u www-data yarn build:production; then
            echo "  ✓ Frontend built with Yarn"
        else
            echo -e "${RED}Error: Frontend build failed with Yarn${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: Yarn install failed${NC}"
        exit 1
    fi
elif command -v npm &> /dev/null; then
    echo "  Using NPM..."
    if sudo -u www-data npm ci --production; then
        echo "  ✓ Dependencies installed"
        if sudo -u www-data npm run build:production; then
            echo "  ✓ Frontend built with NPM"
        else
            echo -e "${RED}Error: Frontend build failed with NPM${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: NPM install failed${NC}"
        exit 1
    fi
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
echo ""
echo -e "${YELLOW}If you encounter any issues, restore from backup:${NC}"
echo "sudo cp -r $BACKUP_DIR/* $PTERODACTYL_PATH/"
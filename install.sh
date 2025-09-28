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
    
    # Check if source and destination are the same file
    if [ "$(realpath "$src")" = "$(realpath "$dest")" ]; then
        echo -e "${YELLOW}⚠ $(basename "$src") already exists, skipping${NC}"
        return 0
    fi
    
    # Check if destination already exists
    if [ -f "$dest" ]; then
        echo -e "${YELLOW}⚠ $(basename "$src") already exists, overwriting${NC}"
    fi
    
    mkdir -p "$(dirname "$dest")"
    if cp "$src" "$dest"; then
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
    ["resources/scripts/routers/routes.ts"]="$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"
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
        sed -i '/^];$/i\    '\''gemini'\'' => [\n        '\''api_key'\'' => env('\''GEMINI_API_KEY'\''),\n    ],' "$PTERODACTYL_PATH/config/services.php"
        echo "  ✓ Updated config/services.php"
    else
        echo -e "${YELLOW}⚠ Gemini config already exists in services.php${NC}"
    fi
fi

# Update API routes - add AI routes to the servers group
if [ -f "$PTERODACTYL_PATH/routes/api-client.php" ]; then
    if ! grep -q "AiChatController" "$PTERODACTYL_PATH/routes/api-client.php"; then
        # Add import after the existing Client import
        sed -i '/use Pterodactyl\\Http\\Controllers\\Api\\Client;/a use Pterodactyl\\Http\\Controllers\\Api\\Client\\Servers\\AiChatController;' "$PTERODACTYL_PATH/routes/api-client.php"
        
        # Add AI routes before the settings group
        sed -i '/Route::group.*prefix.*settings/i\    Route::group(['\''prefix'\'' => '\''ai'\''], function () {\n        Route::post('\''/chat'\'', [AiChatController::class, '\''chat'\'']);\n        Route::get('\''/history'\'', [AiChatController::class, '\''history'\'']);\n    });\n' "$PTERODACTYL_PATH/routes/api-client.php"
        echo "  ✓ Updated API routes"
    else
        echo -e "${YELLOW}⚠ AI routes already exist${NC}"
    fi
fi

# Update admin routes
if [ -f "$PTERODACTYL_PATH/routes/admin.php" ]; then
    if ! grep -q "AiSettingsController" "$PTERODACTYL_PATH/routes/admin.php"; then
        # Add import after existing Admin import
        sed -i '/use Pterodactyl\\Http\\Controllers\\Admin;/a use Pterodactyl\\Http\\Controllers\\Admin\\AiSettingsController;' "$PTERODACTYL_PATH/routes/admin.php"
        
        # Add routes at the end
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
        } >> "$PTERODACTYL_PATH/routes/admin.php"
        echo "  ✓ Updated admin routes"
    else
        echo -e "${YELLOW}⚠ Admin AI routes already exist${NC}"
    fi
fi

# Update admin layout - add AI menu item
if [ -f "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php" ]; then
    if ! grep -q "AI Settings" "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php"; then
        sed -i '/admin\.settings.*Settings/a\                        <li class="{{ ! starts_with(Route::currentRouteName(), '\''admin.ai'\'') ?: '\''active'\'' }}">\n                            <a href="{{ route('\''admin.ai.index'\'')}}\">\n                                <i class="fa fa-robot"></i> <span>AI Settings</span>\n                            </a>\n                        </li>' "$PTERODACTYL_PATH/resources/views/layouts/admin.blade.php"
        echo "  ✓ Updated admin navigation"
    else
        echo -e "${YELLOW}⚠ AI Settings menu already exists${NC}"
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
    "$PTERODACTYL_PATH/resources/views/admin/ai/index.blade.php"
    "$PTERODACTYL_PATH/resources/scripts/api/server/ai.ts"
    "$PTERODACTYL_PATH/resources/scripts/components/server/ai/AiChatContainer.tsx"
    "$PTERODACTYL_PATH/resources/scripts/routers/routes.ts"
)

for file in "${ALL_FILES[@]}"; do
    if [ -f "$file" ]; then
        chown www-data:www-data "$file"
        chmod 644 "$file"
        echo "  ✓ Set permissions for $(basename "$file")"
    fi
done

echo -e "${GREEN}✓ Permissions set${NC}"

# Install Node.js and dependencies
echo -e "${YELLOW}Installing Node.js and dependencies...${NC}"

# Detect OS and install Node.js 22.x
if [ -f /etc/debian_version ]; then
    # Ubuntu/Debian
    echo "  Installing Node.js 22.x for Ubuntu/Debian..."
    curl -sL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt install -y nodejs
elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL/Rocky/Alma
    echo "  Installing Node.js 22.x for CentOS/RHEL..."
    curl -sL https://rpm.nodesource.com/setup_22.x | sudo -E bash -
    if command -v dnf &> /dev/null; then
        sudo dnf install -y nodejs yarn
    else
        sudo yum install -y nodejs yarn
    fi
else
    echo -e "${YELLOW}⚠ Unknown OS, please install Node.js 22.x manually${NC}"
fi

# Install yarn globally
echo "  Installing Yarn globally..."
npm i -g yarn

echo -e "${GREEN}✓ Node.js and Yarn installed${NC}"

# Clear Laravel cache
echo -e "${YELLOW}Clearing Laravel cache...${NC}"
cd "$PTERODACTYL_PATH"
php artisan config:clear
php artisan cache:clear
php artisan view:clear
echo -e "${GREEN}✓ Laravel cache cleared${NC}"

# Install dependencies and build
echo -e "${YELLOW}Installing JavaScript dependencies and building...${NC}"
cd "$PTERODACTYL_PATH"

# Remove all .yarnrc files that cause permission issues
find /var/www -name ".yarnrc" -delete 2>/dev/null || true
find /root -name ".yarnrc" -delete 2>/dev/null || true

# Set proper ownership for entire pterodactyl directory
chown -R www-data:www-data "$PTERODACTYL_PATH"

# Install panel build dependencies
echo "  Installing panel build dependencies..."
yarn

# Build Panel Assets (for NodeJS v17+)
echo "  Building panel assets..."
export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production

echo -e "${GREEN}✓ Frontend built successfully${NC}"

# Final message
echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Add your Gemini API key to .env:"
echo "   GEMINI_API_KEY=your_api_key_here"
echo ""
echo "2. Visit your admin panel at /admin/ai to configure settings"
echo ""
echo "3. Access the AI chat at /server/{id}/ai"
echo ""
echo -e "${YELLOW}Backup created at: $BACKUP_DIR${NC}"
echo ""
echo -e "${GREEN}🎉 Pterodactyl AI Chat Integration is now installed!${NC}"
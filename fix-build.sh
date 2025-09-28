#!/bin/bash

# Fix duplicate AiChatContainer declarations
cd /var/www/pterodactyl

# Remove all AiChatContainer declarations
sed -i '/const AiChatContainer = lazy/d' resources/scripts/routers/routes.ts

# Add it back once after FileEditContainer
sed -i '/const FileEditContainer = lazy/a const AiChatContainer = lazy(() => import('\''@/components/server/ai/AiChatContainer'\''));' resources/scripts/routers/routes.ts

# Remove duplicate AI routes if they exist
sed -i '/path: '\''\/ai'\''/,/},/d' resources/scripts/routers/routes.ts

# Add AI route properly
sed -i '/path: '\''\/schedules'\''/,/},/{
    /},/{
        a\        {\
        a\            path: '\''/ai'\'',\
        a\            permission: null,\
        a\            name: '\''AI Assistant'\'',\
        a\            component: AiChatContainer,\
        a\            exact: true,\
        a\        },
    }
}' resources/scripts/routers/routes.ts

echo "Fixed routes.ts"

# Build with legacy provider
export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production
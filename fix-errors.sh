#!/bin/bash

# Fix the TypeScript errors in Pterodactyl files

cd /var/www/pterodactyl

# Fix AiChatContainer.tsx - remove label prop and fix onChange type
sed -i 's/label="Include recent console logs"//' resources/scripts/components/server/ai/AiChatContainer.tsx
sed -i 's/onChange={(e) => setIncludeLogs(e.target.checked)}/onChange={(e: React.ChangeEvent<HTMLInputElement>) => setIncludeLogs(e.target.checked)}/' resources/scripts/components/server/ai/AiChatContainer.tsx

# Add label as separate element
sed -i '/name="includeLogs"/i\                        <label htmlFor="includeLogs" className="text-sm text-gray-300 ml-2">\n                            Include recent console logs\n                        </label>' resources/scripts/components/server/ai/AiChatContainer.tsx

# Fix routes.ts - remove all AiChatContainer declarations first
sed -i '/const AiChatContainer = lazy/d' resources/scripts/routers/routes.ts

# Add it back once after FileEditContainer
sed -i '/const FileEditContainer = lazy/a const AiChatContainer = lazy(() => import('\''@/components/server/ai/AiChatContainer'\''));' resources/scripts/routers/routes.ts

# Remove the broken route entries
sed -i '/a            path: '\''\/ai'\''/,/a        },/d' resources/scripts/routers/routes.ts

# Add proper AI route
sed -i '/path: '\''\/schedules'\''/,/},/{
    /},/{
        i\        {\
        i\            path: '\''/ai'\'',\
        i\            permission: null,\
        i\            name: '\''AI Assistant'\'',\
        i\            component: AiChatContainer,\
        i\            exact: true,\
        i\        },
    }
}' resources/scripts/routers/routes.ts

echo "Fixed TypeScript errors"
# AI Chat Integration Installation Guide

## Prerequisites
- Pterodactyl Panel v1.x
- Google Gemini API key
- Node.js and npm/yarn for frontend building

## Installation Steps

### 1. Backend Setup

#### Copy Backend Files
Copy the following files to your Pterodactyl installation:

```bash
# Controllers
cp app/Http/Controllers/Api/Client/Servers/AiChatController.php /var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/

# Requests
cp app/Http/Requests/Api/Client/Servers/AiChatRequest.php /var/www/pterodactyl/app/Http/Requests/Api/Client/Servers/

# Services
cp app/Services/Servers/AiChatService.php /var/www/pterodactyl/app/Services/Servers/
```

#### Update Routes
Add the AI routes to your existing `/var/www/pterodactyl/routes/api-client.php` file:

```php
// Add these routes inside the existing server group
Route::group(['prefix' => '/servers/{server}', 'middleware' => [AuthenticateServerAccess::class]], function () {
    // ... existing routes ...
    
    Route::group(['prefix' => '/ai'], function () {
        Route::post('/chat', [AiChatController::class, 'chat']);
        Route::get('/history', [AiChatController::class, 'history']);
    });
});
```

#### Update Configuration
Add Gemini configuration to `/var/www/pterodactyl/config/services.php`:

```php
'gemini' => [
    'api_key' => env('GEMINI_API_KEY'),
],
```

#### Environment Variables
Add to your `/var/www/pterodactyl/.env` file:

```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

### 2. Frontend Setup

#### Copy Frontend Files
```bash
# React Components
cp resources/scripts/components/server/ai/AiChatContainer.tsx /var/www/pterodactyl/resources/scripts/components/server/ai/

# API Functions
cp resources/scripts/api/server/ai.ts /var/www/pterodactyl/resources/scripts/api/server/
```

#### Update Server Router
Modify your existing `/var/www/pterodactyl/resources/scripts/routers/ServerRouter.tsx` to include the AI route:

```tsx
// Add import
import AiChatContainer from '@/components/server/ai/AiChatContainer';

// Add route in the Switch component
<Route path={`${match.path}/ai`} exact>
    <div className="h-screen">
        <AiChatContainer />
    </div>
</Route>

// Add navigation link in SubNavigation
<Route path={`${match.path}/ai`} exact>
    <SubNavigation.Link to={`${match.url}/ai`}>AI Assistant</SubNavigation.Link>
</Route>
```

### 3. Build and Deploy

#### Clear Laravel Cache
```bash
cd /var/www/pterodactyl
php artisan config:clear
php artisan route:clear
php artisan cache:clear
```

#### Build Frontend
```bash
cd /var/www/pterodactyl
npm run build:production
# or for development
npm run build
```

#### Set Permissions
```bash
chown -R www-data:www-data /var/www/pterodactyl/
```

### 4. Get Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Add it to your `.env` file as `GEMINI_API_KEY`

### 5. Test Installation

1. Navigate to any server in your panel
2. Go to `/server/{server-id}/ai`
3. Try sending a message to the AI
4. Test with console logs and file inclusion

## Usage

### Basic Chat
- Navigate to the AI page for any server
- Type a message and click Send
- The AI will respond based on your message

### Include Console Logs
- Check "Include recent console logs" checkbox
- The AI will have access to the last 30 lines of console output

### Include File Content
- Enter a file path (e.g., "server.properties", "config/config.yml")
- The AI will read and include the file content in its context

## Troubleshooting

### Common Issues

1. **"Gemini API key not configured"**
   - Ensure `GEMINI_API_KEY` is set in `.env`
   - Run `php artisan config:clear`

2. **"Route not found"**
   - Ensure routes are properly added to `api-client.php`
   - Run `php artisan route:clear`

3. **Frontend not loading**
   - Ensure all React files are copied correctly
   - Run `npm run build:production`
   - Check browser console for errors

4. **Permission denied errors**
   - Ensure user has server access permissions
   - Check file permissions on server files

### Debug Mode
Enable Laravel debug mode in `.env` for detailed error messages:
```env
APP_DEBUG=true
```

## Security Notes

- API key is stored securely in environment variables
- All requests validate user permissions
- File access is restricted to server files only
- Input is sanitized before sending to AI
- Chat history is cached per user/server combination

## Optional Enhancements

The current implementation includes:
- ✅ Per-user conversation history (7-day cache)
- ✅ File content inclusion with size limits
- ✅ Console log integration
- ✅ Real-time typing indicators
- ✅ Error handling and user feedback

Future enhancements could include:
- Multiple file selection
- Persistent database storage for chat history
- AI model selection (GPT-4, Claude, etc.)
- Custom AI prompts/personalities
- File upload for AI analysis
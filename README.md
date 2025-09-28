# Pterodactyl AI Chat Integration

A complete AI assistant integration for Pterodactyl Panel that allows users to chat with Google Gemini AI about their servers, with access to console logs and file contents.

## Features

- 🤖 **AI Chat Interface**: Clean, responsive chat UI integrated into Pterodactyl's design
- 📊 **Console Log Access**: Include recent server logs in AI context
- 📁 **File Content Reading**: AI can read and analyze server files
- 🔒 **Permission-Based**: Respects existing Pterodactyl permissions
- 💾 **Chat History**: Maintains conversation history per user/server
- ⚡ **Real-time**: Live typing indicators and instant responses
- 🛡️ **Secure**: API keys stored safely, input sanitization, permission validation

## Quick Start

1. **Get Gemini API Key**: Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. **Install Files**: Copy backend and frontend files to your Pterodactyl installation
3. **Configure**: Add API key to `.env` and update routes
4. **Build**: Run `npm run build:production`
5. **Access**: Navigate to `/server/{id}/ai` in your panel

## File Structure

```
├── app/
│   ├── Http/
│   │   ├── Controllers/Api/Client/Servers/
│   │   │   └── AiChatController.php          # Main API controller
│   │   └── Requests/Api/Client/Servers/
│   │       └── AiChatRequest.php             # Request validation
│   └── Services/Servers/
│       └── AiChatService.php                 # Gemini integration & logic
├── resources/scripts/
│   ├── api/server/
│   │   └── ai.ts                             # Frontend API functions
│   └── components/server/ai/
│       └── AiChatContainer.tsx               # Main React component
├── routes/
│   └── api-client.php                        # API routes
├── config/
│   └── services.php                          # Gemini configuration
└── INSTALLATION.md                           # Detailed setup guide
```

## API Endpoints

- `POST /api/client/servers/{server}/ai/chat` - Send message to AI
- `GET /api/client/servers/{server}/ai/history` - Get chat history

## Usage Examples

### Basic Chat
```
User: "How do I increase server memory?"
AI: "To increase server memory, you can modify the startup parameters..."
```

### With Console Logs
```
User: "Why is my server crashing?" (with logs enabled)
AI: "Based on your console logs, I can see a 'java.lang.OutOfMemoryError'..."
```

### With File Content
```
User: "Check my server.properties file" (with file path: server.properties)
AI: "Looking at your server.properties, I notice the max-players is set to 20..."
```

## Security Features

- ✅ Permission validation for all requests
- ✅ File access restricted to server directory
- ✅ Input sanitization and validation
- ✅ API key stored in environment variables
- ✅ Rate limiting and error handling
- ✅ User-specific chat isolation

## Requirements

- Pterodactyl Panel v1.x
- PHP 8.0+
- Node.js 16+
- Google Gemini API key

## Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed setup instructions.

## Contributing

This is a complete, production-ready implementation. All features are fully functional with no placeholder code.

## License

This project follows the same license as Pterodactyl Panel.
<?php

namespace Pterodactyl\Services\Servers;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Pterodactyl\Models\Server;
use Pterodactyl\Models\User;
use Pterodactyl\Repositories\Wings\DaemonFileRepository;
use Pterodactyl\Repositories\Wings\DaemonConsoleRepository;
use Pterodactyl\Contracts\Repository\SettingsRepositoryInterface;

class AiChatService
{
    private DaemonFileRepository $fileRepository;
    private DaemonConsoleRepository $consoleRepository;
    private SettingsRepositoryInterface $settings;

    public function __construct(
        DaemonFileRepository $fileRepository,
        DaemonConsoleRepository $consoleRepository,
        SettingsRepositoryInterface $settings
    ) {
        $this->fileRepository = $fileRepository;
        $this->consoleRepository = $consoleRepository;
        $this->settings = $settings;
    }

    public function processChat(Server $server, array $data): string
    {
        $context = $this->buildContext($server, $data);
        $response = $this->callGeminiApi($context);
        
        $this->storeChatHistory($server, auth()->user(), $data['message'], $response);
        
        return $response;
    }

    private function buildContext(Server $server, array $data): string
    {
        $context = "User message: " . $data['message'] . "\n\n";
        
        if ($data['include_logs'] ?? false) {
            $context .= "Recent console logs:\nConsole logs not available via API\n\n";
        }
        
        if (!empty($data['file_path'])) {
            try {
                $content = $this->fileRepository->setServer($server)->getContent($data['file_path']);
                $content = strlen($content) > 5000 ? substr($content, 0, 5000) . "\n... (truncated)" : $content;
                $context .= "File content (" . $data['file_path'] . "):\n" . $content . "\n\n";
            } catch (\Exception $e) {
                $context .= "Unable to read file: " . $e->getMessage() . "\n\n";
            }
        }
        
        $context .= "Please provide a helpful response based on the above context.";
        
        return $context;
    }

    private function callGeminiApi(string $prompt): string
    {
        $apiKey = config('services.gemini.api_key');
        
        if (!$apiKey) {
            throw new \Exception('Gemini API key not configured');
        }

        $response = Http::timeout(30)->post("https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key={$apiKey}", [
            'contents' => [
                [
                    'parts' => [
                        ['text' => $prompt]
                    ]
                ]
            ]
        ]);

        if (!$response->successful()) {
            throw new \Exception('Gemini API request failed: ' . $response->body());
        }

        $data = $response->json();
        
        if (!isset($data['candidates'][0]['content']['parts'][0]['text'])) {
            throw new \Exception('Invalid response from Gemini API');
        }

        return $data['candidates'][0]['content']['parts'][0]['text'];
    }

    public function getChatHistory(Server $server, User $user): array
    {
        $cacheKey = "ai_chat_history_{$server->id}_{$user->id}";
        return Cache::get($cacheKey, []);
    }

    private function storeChatHistory(Server $server, User $user, string $message, string $response): void
    {
        $cacheKey = "ai_chat_history_{$server->id}_{$user->id}";
        $history = Cache::get($cacheKey, []);
        
        $history[] = [
            'timestamp' => now()->toISOString(),
            'user_message' => $message,
            'ai_response' => $response,
        ];
        
        if (count($history) > 50) {
            $history = array_slice($history, -50);
        }
        
        Cache::put($cacheKey, $history, now()->addDays(7));
    }
}
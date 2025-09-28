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
        if (!$this->settings->get('ai::enabled', true)) {
            throw new \Exception('AI assistant is currently disabled');
        }

        $context = $this->buildContext($server, $data);
        $response = $this->callGeminiApi($context);
        
        $this->storeChatHistory($server, auth()->user(), $data['message'], $response);
        $this->updateUsageStats();
        
        return $response;
    }

    private function buildContext(Server $server, array $data): string
    {
        $context = "User message: " . $data['message'] . "\n\n";
        
        if ($data['include_logs'] ?? false) {
            $logs = $this->getServerLogs($server);
            $context .= "Recent console logs:\n" . $logs . "\n\n";
        }
        
        if (!empty($data['file_path'])) {
            $fileContent = $this->getFileContent($server, $data['file_path']);
            $context .= "File content (" . $data['file_path'] . "):\n" . $fileContent . "\n\n";
        }
        
        $context .= "Please provide a helpful response based on the above context. Focus on the user's question and use the provided logs/files to give accurate, specific advice.";
        
        return $context;
    }

    private function getServerLogs(Server $server): string
    {
        try {
            $logs = $this->consoleRepository->setServer($server)->getLogs(30);
            return $logs;
        } catch (\Exception $e) {
            return "Unable to fetch console logs: " . $e->getMessage();
        }
    }

    private function getFileContent(Server $server, string $filePath): string
    {
        try {
            $content = $this->fileRepository->setServer($server)->getContent($filePath);
            return strlen($content) > 5000 ? substr($content, 0, 5000) . "\n... (truncated)" : $content;
        } catch (\Exception $e) {
            return "Unable to read file: " . $e->getMessage();
        }
    }

    private function callGeminiApi(string $prompt): string
    {
        $apiKey = $this->settings->get('ai::gemini_api_key') ?: config('services.gemini.api_key');
        
        if (!$apiKey) {
            throw new \Exception('Gemini API key not configured');
        }

        $response = Http::withHeaders([
            'Content-Type' => 'application/json',
        ])->post("https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={$apiKey}", [
            'contents' => [
                [
                    'parts' => [
                        ['text' => $prompt]
                    ]
                ]
            ],
            'generationConfig' => [
                'temperature' => (float) $this->settings->get('ai::temperature', 0.7),
                'maxOutputTokens' => (int) $this->settings->get('ai::max_tokens', 1000),
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
        
        // Keep only last 50 messages
        if (count($history) > 50) {
            $history = array_slice($history, -50);
        }
        
        Cache::put($cacheKey, $history, now()->addDays(7));
    }

    private function updateUsageStats(): void
    {
        Cache::increment('ai_total_chats');
        
        $userKey = 'ai_user_' . auth()->id();
        if (!Cache::has($userKey)) {
            Cache::put($userKey, true, now()->addDay());
            Cache::increment('ai_active_users');
        }
    }
}
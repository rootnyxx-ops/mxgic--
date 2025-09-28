<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Pterodactyl\Models\Server;
use Pterodactyl\Services\Servers\AiChatService;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\AiChatRequest;

class AiChatController extends ClientApiController
{
    private AiChatService $aiChatService;

    public function __construct(AiChatService $aiChatService)
    {
        parent::__construct();
        $this->aiChatService = $aiChatService;
    }

    public function chat(AiChatRequest $request, Server $server): JsonResponse
    {
        $this->authorize('view-console', $server);

        try {
            $response = $this->aiChatService->processChat(
                $server,
                $request->validated()
            );

            return response()->json([
                'success' => true,
                'response' => $response
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => 'Failed to process AI request: ' . htmlspecialchars($e->getMessage(), ENT_QUOTES, 'UTF-8')
            ], 500);
        }
    }

    public function history(Server $server): JsonResponse
    {
        $this->authorize('view-console', $server);

        $history = $this->aiChatService->getChatHistory($server, auth()->user());

        return response()->json([
            'success' => true,
            'history' => $history
        ]);
    }
}
<?php

namespace Pterodactyl\Http\Requests\Api\Client\Servers;

use Pterodactyl\Http\Requests\Api\Client\ClientApiRequest;

class AiChatRequest extends ClientApiRequest
{
    public function rules(): array
    {
        return [
            'message' => 'required|string|max:2000',
            'include_logs' => 'boolean',
            'file_path' => 'nullable|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'message.required' => 'A message is required.',
            'message.max' => 'Message cannot exceed 2000 characters.',
            'file_path.max' => 'File path cannot exceed 500 characters.',
        ];
    }
}
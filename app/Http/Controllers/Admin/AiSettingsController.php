<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Contracts\Repository\SettingsRepositoryInterface;

class AiSettingsController extends Controller
{
    private SettingsRepositoryInterface $settings;

    public function __construct(SettingsRepositoryInterface $settings)
    {
        $this->settings = $settings;
    }

    public function index()
    {
        return view('admin.ai.index', [
            'gemini_api_key' => $this->settings->get('ai::gemini_api_key', ''),
            'ai_enabled' => $this->settings->get('ai::enabled', true),
            'max_tokens' => $this->settings->get('ai::max_tokens', 1000),
            'temperature' => $this->settings->get('ai::temperature', 0.7),
        ]);
    }

    public function update(Request $request): RedirectResponse
    {
        $request->validate([
            'gemini_api_key' => 'nullable|string|max:255',
            'ai_enabled' => 'boolean',
            'max_tokens' => 'integer|min:100|max:4000',
            'temperature' => 'numeric|min:0|max:2',
        ]);

        $this->settings->set('ai::gemini_api_key', $request->input('gemini_api_key'));
        $this->settings->set('ai::enabled', $request->boolean('ai_enabled'));
        $this->settings->set('ai::max_tokens', $request->integer('max_tokens'));
        $this->settings->set('ai::temperature', $request->input('temperature'));

        return redirect()->route('admin.ai.index')->with('success', 'AI settings updated successfully.');
    }
}
@extends('layouts.admin')

@section('title')
    AI Settings
@endsection

@section('content-header')
    <h1>AI Assistant Settings<small>Configure AI integration settings</small></h1>
    <ol class="breadcrumb">
        <li><a href="{{ route('admin.index') }}">Admin</a></li>
        <li class="active">AI Settings</li>
    </ol>
@endsection

@section('content')
    <div class="row">
        <div class="col-xs-12">
            <div class="box box-primary">
                <div class="box-header with-border">
                    <h3 class="box-title">AI Configuration</h3>
                </div>
                <form action="{{ route('admin.ai.update') }}" method="POST">
                    @csrf
                    <div class="box-body">
                        <div class="row">
                            <div class="form-group col-md-4">
                                <label class="control-label">AI Assistant Enabled</label>
                                <div>
                                    <input type="checkbox" name="ai_enabled" value="1" @if($ai_enabled) checked @endif />
                                    <p class="text-muted small">Enable or disable the AI assistant feature globally.</p>
                                </div>
                            </div>
                        </div>
                        <div class="row">
                            <div class="form-group col-md-6">
                                <label for="gemini_api_key" class="control-label">Google Gemini API Key</label>
                                <input type="password" id="gemini_api_key" name="gemini_api_key" class="form-control" value="{{ $gemini_api_key }}" />
                                <p class="text-muted small">Your Google Gemini API key. Get one from <a href="https://makersuite.google.com/app/apikey" target="_blank">Google AI Studio</a>.</p>
                            </div>
                        </div>
                        <div class="row">
                            <div class="form-group col-md-3">
                                <label for="max_tokens" class="control-label">Max Tokens</label>
                                <input type="number" id="max_tokens" name="max_tokens" class="form-control" value="{{ $max_tokens }}" min="100" max="4000" />
                                <p class="text-muted small">Maximum number of tokens for AI responses (100-4000).</p>
                            </div>
                            <div class="form-group col-md-3">
                                <label for="temperature" class="control-label">Temperature</label>
                                <input type="number" id="temperature" name="temperature" class="form-control" value="{{ $temperature }}" min="0" max="2" step="0.1" />
                                <p class="text-muted small">AI creativity level (0.0-2.0). Lower = more focused, Higher = more creative.</p>
                            </div>
                        </div>
                    </div>
                    <div class="box-footer">
                        <button type="submit" class="btn btn-primary">Save Settings</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-xs-12">
            <div class="box">
                <div class="box-header with-border">
                    <h3 class="box-title">AI Usage Statistics</h3>
                </div>
                <div class="box-body">
                    <div class="row">
                        <div class="col-md-3 col-sm-6 col-xs-12">
                            <div class="info-box">
                                <span class="info-box-icon bg-aqua"><i class="fa fa-comments"></i></span>
                                <div class="info-box-content">
                                    <span class="info-box-text">Total Chats</span>
                                    <span class="info-box-number">{{ \Illuminate\Support\Facades\Cache::get('ai_total_chats', 0) }}</span>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-3 col-sm-6 col-xs-12">
                            <div class="info-box">
                                <span class="info-box-icon bg-green"><i class="fa fa-users"></i></span>
                                <div class="info-box-content">
                                    <span class="info-box-text">Active Users</span>
                                    <span class="info-box-number">{{ \Illuminate\Support\Facades\Cache::get('ai_active_users', 0) }}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection
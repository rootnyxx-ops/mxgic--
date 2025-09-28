import http from '@/api/http';

export interface AiChatRequest {
    message: string;
    include_logs?: boolean;
    file_path?: string;
}

export interface AiChatResponse {
    success: boolean;
    response: string;
}

export interface AiHistoryItem {
    timestamp: string;
    user_message: string;
    ai_response: string;
}

export const sendAiMessage = async (uuid: string, data: AiChatRequest): Promise<AiChatResponse> => {
    const { data: response } = await http.post(`/api/client/servers/${uuid}/ai/chat`, data);
    return response;
};

export const getAiHistory = async (uuid: string): Promise<AiHistoryItem[]> => {
    const { data } = await http.get(`/api/client/servers/${uuid}/ai/history`);
    return data.history || [];
};
import React, { useState, useEffect, useRef } from 'react';
import { ServerContext } from '@/state/server';
import { httpErrorToHuman } from '@/api/http';
import { useFlashKey } from '@/plugins/useFlash';
import Spinner from '@/components/elements/Spinner';
import { Button } from '@/components/elements/button/index';
import Input from '@/components/elements/Input';

import { sendAiMessage, getAiHistory } from '@/api/server/ai';

interface Message {
    id: string;
    type: 'user' | 'ai';
    content: string;
    timestamp: string;
}

const AiChatContainer = () => {
    const uuid = ServerContext.useStoreState((state) => state.server.data!.uuid);
    const [messages, setMessages] = useState<Message[]>([]);
    const [inputMessage, setInputMessage] = useState('');
    const [filePath, setFilePath] = useState('');
    const [includeLogs, setIncludeLogs] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [isTyping, setIsTyping] = useState(false);
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const { addError } = useFlashKey('server:ai');

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    };

    useEffect(() => {
        scrollToBottom();
    }, [messages]);

    useEffect(() => {
        loadHistory();
    }, []);

    const loadHistory = async () => {
        setIsLoading(true);
        try {
            const history = await getAiHistory(uuid);
            const formattedMessages: Message[] = [];
            
            history.forEach((item: any, index: number) => {
                formattedMessages.push({
                    id: `user-${index}`,
                    type: 'user',
                    content: item.user_message,
                    timestamp: item.timestamp,
                });
                formattedMessages.push({
                    id: `ai-${index}`,
                    type: 'ai',
                    content: item.ai_response,
                    timestamp: item.timestamp,
                });
            });
            
            setMessages(formattedMessages);
        } catch (error) {
            addError(httpErrorToHuman(error), 'Failed to load chat history');
        } finally {
            setIsLoading(false);
        }
    };

    const handleSendMessage = async () => {
        if (!inputMessage.trim()) return;

        const userMessage: Message = {
            id: `user-${Date.now()}`,
            type: 'user',
            content: inputMessage,
            timestamp: new Date().toISOString(),
        };

        setMessages(prev => [...prev, userMessage]);
        setInputMessage('');
        setIsTyping(true);

        try {
            const response = await sendAiMessage(uuid, {
                message: inputMessage,
                include_logs: includeLogs,
                file_path: filePath || undefined,
            });

            const aiMessage: Message = {
                id: `ai-${Date.now()}`,
                type: 'ai',
                content: response.response,
                timestamp: new Date().toISOString(),
            };

            setMessages(prev => [...prev, aiMessage]);
        } catch (error) {
            addError(httpErrorToHuman(error), 'Failed to send message');
        } finally {
            setIsTyping(false);
        }
    };

    const handleKeyPress = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            handleSendMessage();
        }
    };

    if (isLoading) {
        return (
            <div className="flex items-center justify-center h-96">
                <Spinner size="large" />
            </div>
        );
    }

    return (
        <div className="flex flex-col h-full bg-gray-700">
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {messages.length === 0 ? (
                    <div className="text-center text-gray-400 mt-8">
                        <p>Start a conversation with AI about your server!</p>
                        <p className="text-sm mt-2">You can include console logs and file contents for better context.</p>
                    </div>
                ) : (
                    messages.map((message) => (
                        <div
                            key={message.id}
                            className={`flex ${message.type === 'user' ? 'justify-end' : 'justify-start'}`}
                        >
                            <div
                                className={`max-w-xs lg:max-w-md px-4 py-2 rounded-lg ${
                                    message.type === 'user'
                                        ? 'bg-blue-600 text-white'
                                        : 'bg-gray-600 text-gray-100'
                                }`}
                            >
                                <p className="whitespace-pre-wrap">{message.content}</p>
                                <p className="text-xs opacity-70 mt-1">
                                    {new Date(message.timestamp).toLocaleTimeString()}
                                </p>
                            </div>
                        </div>
                    ))
                )}
                {isTyping && (
                    <div className="flex justify-start">
                        <div className="bg-gray-600 text-gray-100 px-4 py-2 rounded-lg">
                            <p className="text-sm">AI is typing...</p>
                        </div>
                    </div>
                )}
                <div ref={messagesEndRef} />
            </div>

            <div className="border-t border-gray-600 p-4 space-y-3">
                <div className="flex space-x-4">
                    <div className="flex items-center space-x-2">
                        <input
                            type="checkbox"
                            id="includeLogs"
                            name="includeLogs"
                            checked={includeLogs}
                            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setIncludeLogs(e.target.checked)}
                            className="rounded border-gray-600 bg-gray-700 text-blue-600 focus:ring-blue-500"
                        />
                        <label htmlFor="includeLogs" className="text-sm text-gray-300">
                            Include recent console logs
                        </label>
                    </div>
                </div>
                
                <Input
                    placeholder="File path (e.g., server.properties, config/config.yml)"
                    value={filePath}
                    onChange={(e) => setFilePath(e.target.value)}
                />

                <div className="flex space-x-2">
                    <Input
                        placeholder="Type your message..."
                        value={inputMessage}
                        onChange={(e) => setInputMessage(e.target.value)}
                        onKeyPress={handleKeyPress}
                        disabled={isTyping}
                        className="flex-1"
                    />
                    <Button
                        onClick={handleSendMessage}
                        disabled={!inputMessage.trim() || isTyping}
                    >
                        Send
                    </Button>
                </div>
            </div>
        </div>
    );
};

export default AiChatContainer;
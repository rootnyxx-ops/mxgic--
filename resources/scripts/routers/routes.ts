import { lazy } from 'react';

// All of the individual server page components.
const ServerConsoleContainer = lazy(() => import('@/components/server/ServerConsoleContainer'));
const FileManagerContainer = lazy(() => import('@/components/server/files/FileManagerContainer'));
const FileEditContainer = lazy(() => import('@/components/server/files/FileEditContainer'));
const AiChatContainer = lazy(() => import('@/components/server/ai/AiChatContainer'));
const ScheduleContainer = lazy(() => import('@/components/server/schedules/ScheduleContainer'));
const ScheduleEditContainer = lazy(() => import('@/components/server/schedules/ScheduleEditContainer'));
const UsersContainer = lazy(() => import('@/components/server/users/UsersContainer'));
const BackupContainer = lazy(() => import('@/components/server/backups/BackupContainer'));
const NetworkContainer = lazy(() => import('@/components/server/network/NetworkContainer'));
const StartupContainer = lazy(() => import('@/components/server/startup/StartupContainer'));
const SettingsContainer = lazy(() => import('@/components/server/settings/SettingsContainer'));
const ServerActivityLogContainer = lazy(() => import('@/components/server/ServerActivityLogContainer'));

interface RouteDefinition {
    path: string;
    permission: string | string[] | null;
    name: string | undefined;
    component: React.ComponentType;
    exact?: boolean;
}

interface Routes {
    // All of the routes available for individual servers.
    server: RouteDefinition[];
}

export default {
    server: [
        {
            path: '/',
            permission: null,
            name: 'Console',
            component: ServerConsoleContainer,
            exact: true,
        },
        {
            path: '/files/*',
            permission: 'file.*',
            name: 'Files',
            component: FileManagerContainer,
        },
        {
            path: '/files/edit/*',
            permission: 'file.*',
            name: undefined,
            component: FileEditContainer,
        },
        {
            path: '/ai',
            permission: null,
            name: 'AI Assistant',
            component: AiChatContainer,
            exact: true,
        },
        {
            path: '/schedules',
            permission: 'schedule.*',
            name: 'Schedules',
            component: ScheduleContainer,
        },
        {
            path: '/schedules/:id',
            permission: 'schedule.*',
            name: undefined,
            component: ScheduleEditContainer,
        },
        {
            path: '/users',
            permission: 'user.*',
            name: 'Users',
            component: UsersContainer,
        },
        {
            path: '/backups',
            permission: 'backup.*',
            name: 'Backups',
            component: BackupContainer,
        },
        {
            path: '/network',
            permission: 'allocation.*',
            name: 'Network',
            component: NetworkContainer,
        },
        {
            path: '/startup',
            permission: 'startup.*',
            name: 'Startup',
            component: StartupContainer,
        },
        {
            path: '/settings',
            permission: ['settings.*', 'file.sftp'],
            name: 'Settings',
            component: SettingsContainer,
        },
        {
            path: '/activity',
            permission: 'activity.*',
            name: 'Activity',
            component: ServerActivityLogContainer,
        },
    ],
} as Routes;
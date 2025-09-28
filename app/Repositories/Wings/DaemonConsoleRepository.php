<?php

namespace Pterodactyl\Repositories\Wings;

use Webmozart\Assert\Assert;
use Pterodactyl\Models\Server;
use GuzzleHttp\Exception\TransferException;
use Pterodactyl\Exceptions\Http\Connection\DaemonConnectionException;

/**
 * @method \Pterodactyl\Repositories\Wings\DaemonConsoleRepository setNode(\Pterodactyl\Models\Node $node)
 * @method \Pterodactyl\Repositories\Wings\DaemonConsoleRepository setServer(\Pterodactyl\Models\Server $server)
 */
class DaemonConsoleRepository extends DaemonRepository
{
    /**
     * Get console logs from Wings daemon.
     *
     * @throws DaemonConnectionException
     */
    public function getLogs(int $lines = 100): string
    {
        Assert::isInstanceOf($this->server, Server::class);

        try {
            $response = $this->getHttpClient()->get(
                sprintf('/api/servers/%s/logs', $this->server->uuid),
                [
                    'query' => ['lines' => $lines],
                ]
            );

            return $response->getBody()->__toString();
        } catch (TransferException $exception) {
            // If the endpoint doesn't exist, return a message
            return "Console logs not available via API. Wings daemon may not support this endpoint.";
        }
    }
}
#!/bin/bash

# Fix the broken admin.php routes file
cat > /tmp/admin_routes_fix.php << 'EOF'
<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Admin Routes
|--------------------------------------------------------------------------
*/

Route::get('/', 'BaseController@index')->name('admin.index');

// AI Settings Routes
Route::get('/ai', 'AiSettingsController@index')->name('admin.ai.index');
Route::post('/ai', 'AiSettingsController@update')->name('admin.ai.update');

EOF

# Backup the original file
cp /var/www/pterodactyl/routes/admin.php /var/www/pterodactyl/routes/admin.php.backup

# Replace with fixed version
cp /tmp/admin_routes_fix.php /var/www/pterodactyl/routes/admin.php

echo "Admin routes file has been fixed!"
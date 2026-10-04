<?php

$demoMode = getenv('DEMO_MODE');
$demoMode = $demoMode === false ? '1' : $demoMode;
$configuredBasePath = trim((string) (getenv('APP_BASE_PATH') ?: ''), '/');
$basePath = $configuredBasePath === '' ? '/' : "/{$configuredBasePath}/";

if (!defined('DEMO_MODE')) {
    define(
        'DEMO_MODE',
        filter_var($demoMode, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE)
            ?? ((int) $demoMode === 1)
    );
}

$legacyConstants = [
    'EMAIL_ADDRESS',
    'EMAIL_PASSWORD',
    'EMAIL_NAME',
    'EMAIL_SERVER_NAME',
    'EMAIL_SERVER_HOST',
    'EMAIL_SERVER_PORT',
    'EMAIL_SERVER_ENCRYPTION',
    'CORPORATE_EMAIL_ADDRESS',
    'CORPORATE_EMAIL_NAME',
    'RECAPTCHA_SITE_KEY',
    'RECAPTCHA_SECRET_KEY',
];

foreach ($legacyConstants as $constantName) {
    if (!defined($constantName)) {
        define($constantName, getenv($constantName) ?: '');
    }
}

return [
    'view_manager' => [
        'base_path' => $basePath,
        'base_url' => $basePath,
    ],
    'db' => [
        'hostname' => getenv('DB_HOST') ?: 'db',
        'database' => getenv('DB_NAME') ?: 'horsesns_safari',
        'username' => getenv('DB_USER') ?: 'horsesns_safari',
        'password' => getenv('DB_PASSWORD') ?: '',
    ],
];

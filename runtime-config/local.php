<?php

$demoMode = getenv('DEMO_MODE');
$demoMode = $demoMode === false ? '1' : $demoMode;
$configuredBasePath = trim((string) (getenv('APP_BASE_PATH') ?: ''), '/');
$basePath = $configuredBasePath === '' ? '/' : "/{$configuredBasePath}/";
$publicPath = $configuredBasePath === '' ? '' : "/{$configuredBasePath}";
$secureBaseUrl = rtrim((string) (getenv('SECURE_BASE_URL') ?: ''), '/');
$mercuryCheckoutFrame = rtrim((string) (getenv('MERCURY_CHECKOUT_FRAME') ?: ''), '/');
$mercurySite = (string) (getenv('MERCURY_SITE') ?: '');
$mercuryTransSite = (string) (getenv('MERCURY_TRANS_SITE') ?: '');

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

if (!defined('SECURE_BASE_URL')) {
    define('SECURE_BASE_URL', $secureBaseUrl);
}

if (!defined('MERCURY_CHECKOUT_FRAME')) {
    define('MERCURY_CHECKOUT_FRAME', $mercuryCheckoutFrame);
}

if (!defined('MercurySite')) {
    define('MercurySite', $mercurySite);
}

if (!defined('MercuryTransSite')) {
    define('MercuryTransSite', $mercuryTransSite);
}

if (!defined('MERCURY_COMPLETE_URL')) {
    define(
        'MERCURY_COMPLETE_URL',
        rtrim($secureBaseUrl . $publicPath, '/') . '/payment/complete'
    );
}

if (!defined('MERCURY_ERROR_URL')) {
    define(
        'MERCURY_ERROR_URL',
        rtrim($secureBaseUrl . $publicPath, '/') . '/payment/error'
    );
}

// Temporary deployment mapping for the legacy document paths used by waivers.
if (!defined('DOCUMENT_ROOT_DIR')) {
    define('DOCUMENT_ROOT_DIR', '/var/www/html/data/documents');
}

if (!defined('WAIVERS_ROOT_DIR')) {
    define('WAIVERS_ROOT_DIR', DOCUMENT_ROOT_DIR . '/waivers');
}

if (!defined('PATH_TO_WAIVERS')) {
    define('PATH_TO_WAIVERS', '/data/documents/waivers');
}

// Temporary deployment mapping for legacy PDF asset paths.
if (!defined('ROOT_PATH')) {
    define('ROOT_PATH', '/var/www/html/public');
}

if (!defined('PATH_TO_IMAGE_FILES')) {
    define('PATH_TO_IMAGE_FILES', '/images/safari');
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

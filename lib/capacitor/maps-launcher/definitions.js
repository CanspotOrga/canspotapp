/**
 * A navigation app that can be launched.
 *
 * @since 0.1.0
 */
export var NavigationApp;
(function (NavigationApp) {
    /**
     * Apple Maps.
     *
     * Only available on iOS.
     *
     * @since 0.1.0
     */
    NavigationApp["AppleMaps"] = "APPLE_MAPS";
    /**
     * Google Maps.
     *
     * @since 0.1.0
     */
    NavigationApp["GoogleMaps"] = "GOOGLE_MAPS";
    /**
     * Waze.
     *
     * @since 0.1.0
     */
    NavigationApp["Waze"] = "WAZE";
})(NavigationApp || (NavigationApp = {}));
/**
 * @since 0.1.0
 */
export var ErrorCode;
(function (ErrorCode) {
    /**
     * The requested navigation app is not installed or cannot be launched.
     *
     * @since 0.1.0
     */
    ErrorCode["AppNotAvailable"] = "APP_NOT_AVAILABLE";
    /**
     * The navigation app could not be launched.
     *
     * @since 0.1.0
     */
    ErrorCode["LaunchFailed"] = "LAUNCH_FAILED";
})(ErrorCode || (ErrorCode = {}));

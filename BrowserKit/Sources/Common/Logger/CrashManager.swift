// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - CrashManager
public protocol CrashManager: Sendable {
    var crashedLastLaunch: Bool { get }
    func captureError(error: Error)
    func setup(sendCrashReports: Bool)
    func send(message: String,
              category: LoggerCategory,
              level: LoggerLevel,
              extraEvents: [String: String]?)
}

/**
 * Crash report for rust errors
 *
 * We implement this on exception classes that correspond to Rust errors to
 * customize how the crash reports look.
 *
 * CrashReporting implementors should test if exceptions implement this
 * interface.  If so, they should try to customize their crash reports to match.
 */
public protocol CustomCrashReport {
    var typeName: String { get set }
    var message: String { get set }
}

/// **Note**: This class is safely `@unchecked Sendable` because we protect the only mutable state (`enabled`) with a manual
/// synchronization method (a lock).
public final class DefaultCrashManager: CrashManager, @unchecked Sendable {
    enum Environment: String {
        case nightly = "Nightly"
        case production = "Production"
    }

    // MARK: - Properties
    private let deviceAppHashKey = "SentryDeviceAppHash"
    private let defaultDeviceAppHash = "0000000000000000000000000000000000000000"
    private let deviceAppHashLength = UInt(20)

    // We are using a lock to manually protect our mutable state to make this class @unchecked Sendable
    private let enabledLock = NSLock()
    private var enabled = false

    private var shouldSetup: Bool {
        enabledLock.lock()
        defer { enabledLock.unlock() }

        return !enabled
                && !isSimulator
                && isValidReleaseName
    }

    private var isValidReleaseName: Bool {
        if skipReleaseNameCheck { return true }

        return AppInfo.bundleIdentifier == "org.mozilla.ios.Firefox"
                || AppInfo.bundleIdentifier == "org.mozilla.ios.FirefoxBeta"
    }

    private var environment: Environment {
        var environment = Environment.production
        if AppInfo.appVersion == appInfo.nightlyAppVersion, appInfo.buildChannel == .beta {
            environment = Environment.nightly
        }
        return environment
    }

    private var releaseName: String {
        return "\(AppInfo.bundleIdentifier)@\(AppInfo.appVersion)"
    }

    private let appInfo: BrowserKitInformation
    private let isSimulator: Bool
    private let skipReleaseNameCheck: Bool

    // Only enable app hang tracking in Beta for now
    private var shouldEnableAppHangTracking: Bool {
        return appInfo.buildChannel == .beta
    }

    private var shouldEnableMetricKit: Bool {
        return appInfo.buildChannel == .beta
    }

    private var shouldEnableTraceProfiling: Bool {
        return appInfo.buildChannel == .beta
    }

    // MARK: - Init

    public init(appInfo: BrowserKitInformation = BrowserKitInformation.shared,
                isSimulator: Bool = DeviceInfo.isSimulator(),
                skipReleaseNameCheck: Bool = false) {
        self.appInfo = appInfo
        self.isSimulator = isSimulator
        self.skipReleaseNameCheck = skipReleaseNameCheck
    }

    // MARK: - CrashManager protocol
    public var crashedLastLaunch: Bool {
        return false
    }

    public func setup(sendCrashReports: Bool) {
        enabledLock.lock()
        defer { enabledLock.unlock() }
        enabled = true

        configureScope()
        configureIdentifier()
        setupIgnoreException()
    }

    public func send(message: String,
                     category: LoggerCategory,
                     level: LoggerLevel,
                     extraEvents: [String: String]?) {
        enabledLock.lock()
        defer { enabledLock.unlock() }
        guard enabled else { return }

        guard shouldSendEventFor(level) else {
            addBreadcrumb(message: message,
                          category: category,
                          level: level)
            return
        }
    }

    // MARK: - Private

    public func captureError(error: Error) {
        // Using `shouldSendEventFor` below to prevent errors being sent
        // in channels other than beta or release so there's only one place
        // to control what gets sent.
        guard shouldSendEventFor(.fatal) else { return }

    }

    private func addBreadcrumb(message: String, category: LoggerCategory, level: LoggerLevel) {
        
    }

    /// Do not send messages to Sentry if disabled OR if we are not on beta and the severity isnt severe
    /// This is the behaviour we want for Sentry logging
    ///       .info .warning .fatal
    /// Debug      n        n          n
    /// Beta         n         n          y
    /// Release   n         n          y
    private func shouldSendEventFor(_ level: LoggerLevel) -> Bool {
        let shouldSendRelease = appInfo.buildChannel == .release && level.isGreaterOrEqualThanLevel(.fatal)
        let shouldSendBeta = appInfo.buildChannel == .beta && level.isGreaterOrEqualThanLevel(.fatal)

        return shouldSendBeta || shouldSendRelease
    }

    private func configureScope() {
        
        
    }

    /// If we have not already for this install, generate a completely random identifier for this device.
    /// It is stored in the app group so that the same value will be used for both the main application
    /// and the app extensions.
    private func configureIdentifier() {
        guard let defaults = UserDefaults(suiteName: appInfo.sharedContainerIdentifier),
              defaults.string(forKey: deviceAppHashKey) == nil else { return }

        defaults.set(Bytes.generateRandomBytes(deviceAppHashLength).hexEncodedString,
                     forKey: deviceAppHashKey)
    }

    /// Ignore SIGPIPE exceptions globally.
    /// https://stackoverflow.com/questions/108183/how-to-prevent-sigpipes-or-handle-them-properly
    private func setupIgnoreException() {
        signal(SIGPIPE, SIG_IGN)
    }
}

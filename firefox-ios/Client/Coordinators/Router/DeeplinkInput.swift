// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// An enumeration of possible input parameters for handling deep links in the Mozilla Firefox browser.
enum DeeplinkInput {
    /// An enumeration of possible hosts for deep links.
    enum Host: String {
        case deepLink = "deep-link"
        case openUrl = "open-url"
        case openText = "open-text"
        case sharesheet = "share-sheet"
        case glean
        case widgetMediumTopSitesOpenUrl = "widget-medium-topsites-open-url"
        case widgetSmallQuickLinkOpenUrl = "widget-small-quicklink-open-url"
        case widgetMediumQuickLinkOpenUrl = "widget-medium-quicklink-open-url"
        case widgetSmallQuickLinkOpenCopied = "widget-small-quicklink-open-copied"
        case widgetMediumQuickLinkOpenCopied = "widget-medium-quicklink-open-copied"
        case widgetSmallQuickLinkClosePrivateTabs = "widget-small-quicklink-close-private-tabs"
        case widgetMediumQuickLinkClosePrivateTabs = "widget-medium-quicklink-close-private-tabs"

        var shouldRouteDeeplinkToSpecificIPadWindow: Bool {
            switch self {
            default:
                return false
            }
        }

        /// Checks if we have a valid URL and returns false if we received an invalid URL.
        /// Some cases don't need to be handled, so we return true directly.
        /// For specific cases, if we don't have a URL query, then we return true.
        /// If we have a URL query, then make sure to check it's a webpage.
        ///
        /// - Parameter urlQuery: the URL that will be used to route
        /// - Returns: true if we don't need need to handle the case, the urlQuery is null, or if the URL is a valid webPage
        func isValidURL(
            urlQuery: URL?
        ) -> Bool {
            switch self {
            case .openText,
                    .openUrl, .sharesheet,
                    .widgetMediumTopSitesOpenUrl,
                    .widgetSmallQuickLinkOpenUrl, .widgetMediumQuickLinkOpenUrl,
                    .widgetSmallQuickLinkOpenCopied, .widgetMediumQuickLinkOpenCopied:
                return urlQuery?.isWebPage() ?? true
            case .deepLink, .glean,
                    .widgetSmallQuickLinkClosePrivateTabs, .widgetMediumQuickLinkClosePrivateTabs:
                return true
            }
        }
    }

    /// An enumeration of possible paths for deep links.
    enum Path: String {
        case settings = "settings"
        case homepanel = "homepanel"
        case defaultBrowser = "default-browser"
        case action
    }

    enum Shortcut: String {
        case newTab = "NewTab"
        case newPrivateTab = "NewPrivateTab"
        case openLastBookmark = "OpenLastBookmark"
        case qrCode = "QRCode"
    }
}

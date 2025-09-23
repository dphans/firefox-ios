// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WidgetKit
import ActivityKit
import Common
import Shared

@available(iOS 17, *)
class DownloadLiveActivityWrapper: DownloadProgressDelegate {
    private struct UX {
        static let updateCooldown = 0.75 // Update Cooldown in Seconds
    }

    enum DurationToDismissal: UInt64 {
        case none = 0
        case delayed = 3_000_000_000 // Milliseconds to dismissal
    }

    let throttler = ConcurrencyThrottler(seconds: UX.updateCooldown)

    var downloadProgressManager: DownloadProgressManager

    let windowUUID: String

    init(downloadProgressManager: DownloadProgressManager, windowUUID: String) {
        self.downloadProgressManager = downloadProgressManager
        self.windowUUID = windowUUID
    }

    func start() -> Bool {
        return false
    }

    func end(durationToDismissal: DurationToDismissal) {
        Task {
            await update()
        }
    }

    private func update() async {
        
    }

    func updateCombinedBytesDownloaded(value: Int64) {
        throttler.throttle {
            Task {
                await self.update()
            }
        }
    }

    func updateCombinedTotalBytesExpected(value: Int64?) {
        throttler.throttle {
            Task {
                await self.update()
            }
        }
    }
}

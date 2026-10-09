//
//  AppleWatchPreference.swift
//  CortiFree
//
//  Whether the user has an Apple Watch, asked once (the first pulse measure) and then
//  changed only in Profile. Without a watch, the pulse is always measured with the flash
//  and the app stops offering watch features.
//

import Foundation

enum AppleWatchPreference {
    /// "" = not asked yet, "yes" / "no" afterwards.
    static let storageKey = "pulse.appleWatch"
    static let yes = "yes"
    static let no = "no"
}

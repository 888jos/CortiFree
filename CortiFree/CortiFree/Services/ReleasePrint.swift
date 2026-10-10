//
//  ReleasePrint.swift
//  CortiFree
//
//  Release builds must not write to the device console: many `print` calls log user
//  ids, names or health values. This module-level `print` shadows `Swift.print` for
//  the whole app target, so they only print in debug builds.
//

import Foundation

func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    Swift.print(items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
    #endif
}

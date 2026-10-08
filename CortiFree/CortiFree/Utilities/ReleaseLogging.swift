//
//  ReleaseLogging.swift
//  CortiFree
//
//  Release builds must not write to the device log (some messages contained user data such
//  as e-mail addresses). This module-level `print` shadows Swift.print for the whole app
//  target outside DEBUG, so every existing print(...) becomes a no-op in production.
//

#if !DEBUG
@inline(__always)
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {}
#endif

//
//  DeviceActivityMonitorExtension.swift
//  CortiFreeActivityMonitor
//
//  Woken by iOS when the 10-minute pass that follows a breathing pause ends: shields the
//  picked apps again (the app itself may not be running at that moment).
//

import DeviceActivity
import ManagedSettings

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == ScreenTimeShield.passActivity else { return }
        ScreenTimeShield.endPass()
    }
}

//
//  CortiFreeWidgetBundle.swift
//  CortiFreeWidget
//
//  Created by Josselin Biot on 23/02/2026.
//

import WidgetKit
import SwiftUI

@main
struct CortiFreeWidgetBundle: WidgetBundle {
    var body: some Widget {
        CortiFreeWidget()
        LockScreenWidget()
        CortiFreeWidgetControl()
        CortiFreeWidgetLiveActivity()
    }
}

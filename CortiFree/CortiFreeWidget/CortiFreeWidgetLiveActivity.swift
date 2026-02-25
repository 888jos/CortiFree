//
//  CortiFreeWidgetLiveActivity.swift
//  CortiFreeWidget
//
//  Created by Josselin Biot on 23/02/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CortiFreeWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CortiFreeWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CortiFreeWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension CortiFreeWidgetAttributes {
    fileprivate static var preview: CortiFreeWidgetAttributes {
        CortiFreeWidgetAttributes(name: "World")
    }
}

extension CortiFreeWidgetAttributes.ContentState {
    fileprivate static var smiley: CortiFreeWidgetAttributes.ContentState {
        CortiFreeWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CortiFreeWidgetAttributes.ContentState {
         CortiFreeWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CortiFreeWidgetAttributes.preview) {
   CortiFreeWidgetLiveActivity()
} contentStates: {
    CortiFreeWidgetAttributes.ContentState.smiley
    CortiFreeWidgetAttributes.ContentState.starEyes
}

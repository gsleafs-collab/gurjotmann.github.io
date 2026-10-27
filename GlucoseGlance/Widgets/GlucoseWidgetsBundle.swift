import SwiftUI
import WidgetKit

@main
struct GlucoseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GlucoseWidget()
        GlucoseLiveActivity()
    }
}

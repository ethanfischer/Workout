//
//  WorkoutWidgetBundle.swift
//  WorkoutWidget
//
//  Created by Work on 1/16/26.
//

import WidgetKit
import SwiftUI

@main
struct WorkoutWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutWidget()
        WorkoutWidgetControl()
        WorkoutWidgetLiveActivity()
    }
}

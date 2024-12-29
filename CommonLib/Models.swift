//
//  Models.swift
//  ScreenBreakers
//
//  Created by Alex Saveliev on 12/29/24.
//

import SwiftData
import Foundation

@Model
class DailyActivity {
    @Attribute(.unique) var date: Date
    //var id: UUID = UUID()
    var totalScreenMinutes: Double
    // This app open and recording
    var totalMonitoringMinutes: Double

    init(date: Date, totalScreenMinutes: Double, totalMonitoringMinutes: Double) {
        self.date = date
        self.totalScreenMinutes = totalScreenMinutes
        self.totalMonitoringMinutes = totalMonitoringMinutes
    }
}


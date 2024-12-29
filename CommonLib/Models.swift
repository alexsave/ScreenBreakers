//
//  Models.swift
//  ScreenBreakers
//
//  Created by Alex Saveliev on 12/29/24.
//

import SwiftData
import Foundation

@Model
class AppActivity {
    @Attribute(.unique) var id: UUID = UUID()
    var launchTime: Date
    var closeTime: Date?
    var minutesOfActivity: Double = 0
    
    init(launchTime: Date, closeTime: Date? = nil, minutesOfActivity: Double = 0) {
        self.launchTime = launchTime
        self.closeTime = closeTime
        self.minutesOfActivity = minutesOfActivity
    }
}

@Model
class DailyActivity {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var totalMinutesOfActivity: Double
    // This app open and recording
    var totalActiveTime: Double?

    init(date: Date, totalMinutesOfActivity: Double, totalActiveTime: Double? = 0) {
        self.date = date
        self.totalMinutesOfActivity = totalMinutesOfActivity
        self.totalActiveTime = totalActiveTime
    }
}


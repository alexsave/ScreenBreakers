//
//  ContentView.swift
//  UsageMonitor
//
//  Created by You on [Date].
//

import SwiftUI
import FamilyControls

struct ContentView: View {
    
    @StateObject private var screenTimeManager = ScreenTimeManager()
    @State private var thresholdInput = "30" // Default threshold
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Screen Time Monitoring")
                .font(.largeTitle)
                .padding(.top, 40)
            
            Button("Request Screen Time Authorization") {
                Task {
                    await screenTimeManager.requestAuthorization()
                }
            }
            
            Button("Select Apps to Monitor") {
                screenTimeManager.isPickerPresented = true
            }
            
            HStack {
                Text("Threshold (minutes):")
                TextField("Threshold", text: $thresholdInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 60)
            }
            .padding(.horizontal)
            
            Button("Start Monitoring") {
                let threshold = Int(thresholdInput) ?? 30
                screenTimeManager.startDailyMonitoring(thresholdMinutes: threshold)
            }
            
            Spacer()
        }
        .familyActivityPicker(
            isPresented: $screenTimeManager.isPickerPresented,
            selection: $screenTimeManager.activitySelection
        )
        .onChange(of: screenTimeManager.activitySelection) { newSelection in
            // Store each time user picks new apps/categories
            screenTimeManager.storeSelection(newSelection)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

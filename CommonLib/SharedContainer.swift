//
//  SharedContainer.swift
//  ScreenBreakers
//
//  Created by Alex Saveliev on 12/29/24.
//

import SwiftData
import Foundation
import os.log

// copied these. which funcs do we need
struct SharedContainer {
    
    private static var container: ModelContainer?
    
    static func makeConfiguration() -> ModelContainer? {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier("group.com.alexs.ScreenBreakers")
        )
        do {
            let container = try ModelContainer(
                for: DailyActivity.self,
                configurations: configuration
            )
            return container
        } catch {}
        return nil
    }
    
    @MainActor
    static func getContext() throws -> ModelContext {
        guard let container = container else {
            throw NSError(domain: "container_uninitialized", code: 500, userInfo: [NSLocalizedDescriptionKey: "ModelContainer is not initialized"])
        }
        return container.mainContext
    }
}

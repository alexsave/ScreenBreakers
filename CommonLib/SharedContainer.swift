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
    
    static func makeConfiguration() -> ModelContainer {
        let groupIdentifier = "group.com.alexs.ScreenBreakers"

        /*let fileManager = FileManager.default
        let storeURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)?
            .appendingPathComponent("Library/Application Support/default.store")
        
        // Remove the existing store if it exists
        if let storeURL = storeURL, fileManager.fileExists(atPath: storeURL.path) {
            do {
                try fileManager.removeItem(at: storeURL)
                print("Successfully wiped existing database at \(storeURL.path)")
            } catch {
                fatalError("Failed to remove existing database: \(error)")
            }
        }*/
        
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier(groupIdentifier)
        )
        do {
            // Attempt to create and return the ModelContainer
            let container = try ModelContainer(
                for: DailyActivity.self,
                configurations: configuration
            )
            return container
        } catch {
            // Handle the error appropriately
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    
    @MainActor
    static func getContext() throws -> ModelContext {
        guard let container = container else {
            throw NSError(domain: "container_uninitialized", code: 500, userInfo: [NSLocalizedDescriptionKey: "ModelContainer is not initialized"])
        }
        return container.mainContext
    }
}

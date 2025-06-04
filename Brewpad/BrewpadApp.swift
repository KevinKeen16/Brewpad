//
//  BrewpadApp.swift
//  Brewpad
//
//  Created by Kevin Keen on 12/28/24.
//

import SwiftUI

@main
struct BrewpadApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var notesManager = NotesManager()
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var recipeStore = RecipeStore()
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsManager)
                .environmentObject(notesManager)
                .environmentObject(favoritesManager)
                .environmentObject(recipeStore)
                .environmentObject(appState)
                .preferredColorScheme(settingsManager.theme.colorScheme)
                .animation(.easeInOut, value: settingsManager.theme)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.pathExtension == "brewpadrecipe" else { return }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let recipe = try decoder.decode(Recipe.self, from: data)
            appState.importedRecipe = recipe
            appState.shouldShowImport = true
            appState.reinitialize(for: .recipeImported)
        } catch {
            print("Error handling incoming recipe: \(error)")
        }
    }
}

// Update AppState
class AppState: ObservableObject {
    @Published var importedRecipe: Recipe?
    @Published var shouldShowImport = false
    @Published var shouldReinitialize = false
    @Published var lastAction: AppAction?
    
    enum AppAction {
        case recipeDeleted
        case recipeImported
        case recipeEdited
        case recipeCreated
        
        var quip: String {
            switch self {
            case .recipeDeleted:
                return "Cleaning up the recipe book..."
            case .recipeImported:
                return "Adding a new recipe to your collection..."
            case .recipeEdited:
                return "Perfecting your recipe..."
            case .recipeCreated:
                return "Creating your masterpiece..."
            }
        }
    }
    
    func reinitialize(for action: AppAction) {
        lastAction = action
        shouldReinitialize = true
        
        // Auto-reset after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.shouldReinitialize = false
            self.lastAction = nil
        }
    }
}

//
//  ContentView.swift
//  Brewpad
//
//  Created by Kevin Keen on 12/28/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var appState: AppState
    // Start the app on the Recipes tab instead of Featured
    @State private var selectedTab = 1
    
    var body: some View {
        Group {
            if !settingsManager.hasCompletedOnboarding {
                OnboardingView()
            } else if appState.shouldReinitialize {
                SplashScreen(action: appState.lastAction)
            } else if recipeStore.isInitialized {
                TabView(selection: $selectedTab) {
                    NavigationView {
                        FeaturedRecipesView()
                    }
                    .tabItem {
                        Label("Featured", systemImage: "star.fill")
                    }
                    .tag(0)

                    NavigationView {
                        RecipesView()
                    }
                    .tabItem {
                        Label("Recipes", systemImage: "book.fill")
                    }
                    .tag(1)

                    RecipeManagerView()
                        .tabItem {
                            Label("Manage", systemImage: "square.and.pencil")
                        }
                        .tag(2)

                    InfoView()
                        .tabItem {
                            Label("Info", systemImage: "info.circle.fill")
                        }
                        .tag(3)

                    NavigationView {
                        SettingsView()
                            .navigationTitle("Settings")
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
                }
                .sheet(isPresented: $appState.shouldShowImport) {
                    if let recipe = appState.importedRecipe {
                        RecipeEditorView(recipe: recipe, isImporting: true)
                    }
                }
                .tint(settingsManager.colors.accent)
            } else {
                SplashScreen()
            }
        }
        .background(settingsManager.colors.background)
        .animation(.easeInOut(duration: 0.3), value: recipeStore.isInitialized)
        .animation(.easeInOut(duration: 0.3), value: settingsManager.hasCompletedOnboarding)
        .alert("Server Not Reachable", isPresented: $recipeStore.showServerError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to reach the Brewpad recipe server.")
        }
    }
}

#Preview {
    ContentView()
}

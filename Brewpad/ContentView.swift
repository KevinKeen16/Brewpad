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
    @State private var selectedTab: Tab = .recipes
    @State private var selectedCategory = 0

    enum Tab: Int, CaseIterable, Identifiable {
        case featured, recipes, manage, info, settings

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .featured: return "Featured"
            case .recipes: return "Recipes"
            case .manage: return "Manage"
            case .info: return "Info"
            case .settings: return "Settings"
            }
        }

        var systemImage: String {
            switch self {
            case .featured: return "star.fill"
            case .recipes: return "book.fill"
            case .manage: return "square.and.pencil"
            case .info: return "info.circle.fill"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        Group {
            if !settingsManager.hasCompletedOnboarding {
                OnboardingView()
            } else if appState.shouldReinitialize {
                SplashScreen(action: appState.lastAction)
            } else if recipeStore.isInitialized {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadBody
                        .tint(settingsManager.colors.accent)
                } else {
                    phoneBody
                        .tint(settingsManager.colors.accent)
                }
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

    private var phoneBody: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                FeaturedRecipesView()
            }
            .tabItem {
                Label("Featured", systemImage: Tab.featured.systemImage)
            }
            .tag(Tab.featured)

            NavigationView {
                RecipesView(selectedCategory: $selectedCategory)
            }
            .tabItem {
                Label("Recipes", systemImage: Tab.recipes.systemImage)
            }
            .tag(Tab.recipes)

            RecipeManagerView()
                .tabItem {
                    Label("Manage", systemImage: Tab.manage.systemImage)
                }
                .tag(Tab.manage)

            InfoView()
                .tabItem {
                    Label("Info", systemImage: Tab.info.systemImage)
                }
                .tag(Tab.info)

            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: Tab.settings.systemImage)
            }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $appState.shouldShowImport) {
            if let recipe = appState.importedRecipe {
                RecipeEditorView(recipe: recipe, isImporting: true)
            }
        }
    }

    private var iPadBody: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Section(header: Text("Tabs")) {
                    ForEach(Tab.allCases) { tab in
                        Label(tab.title, systemImage: tab.systemImage)
                            .tag(tab)
                    }
                }

                if selectedTab == .recipes {
                    Section(header: Text("Categories")) {
                        let categories = ["All"] + Recipe.Category.allCases.map(\.rawValue)
                        ForEach(categories.indices, id: \.self) { index in
                            Text(categories[index])
                                .tag(index)
                                .onTapGesture {
                                    selectedCategory = index
                                }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        } detail: {
            switch selectedTab {
            case .featured:
                NavigationView { FeaturedRecipesView() }
            case .recipes:
                RecipesView(selectedCategory: $selectedCategory)
            case .manage:
                RecipeManagerView()
            case .info:
                InfoView()
            case .settings:
                NavigationView {
                    SettingsView()
                        .navigationTitle("Settings")
                }
            }
        }
        .sheet(isPresented: $appState.shouldShowImport) {
            if let recipe = appState.importedRecipe {
                RecipeEditorView(recipe: recipe, isImporting: true)
            }
        }
    }
}

#Preview {
    ContentView()
}

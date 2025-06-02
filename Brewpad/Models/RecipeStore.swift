import Foundation
import SwiftUI

class RecipeStore: ObservableObject {
    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var userRecipes: [Recipe] = []
    @Published private(set) var isInitialized = false
    private let recipesDirectoryName = "Recipes"
    private var hasLoadedRecipes = false
    private var minimumSplashTimeElapsed = false
    
    init() {
        // Start loading immediately
        loadRecipes()
        
        // Ensure minimum splash screen duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.minimumSplashTimeElapsed = true
            self.checkInitialization()
        }
    }
    
    private func checkInitialization() {
        if hasLoadedRecipes && minimumSplashTimeElapsed {
            DispatchQueue.main.async {
                self.isInitialized = true
            }
        }
    }
    
    func loadRecipes() {
        print("📚 Starting recipe load process")
        var allRecipes: [Recipe] = []
        
        // Load bundled recipes
        print("📦 Loading bundled recipes...")
        loadBundledRecipes(into: &allRecipes)
        
        // Load user-created recipes
        print("👤 Loading user recipes...")
        loadUserRecipes(into: &allRecipes)
        
        // Update the published recipes array
        recipes = allRecipes.sorted(by: { $0.name < $1.name })
        
        print("📊 Loaded \(recipes.count) total recipes:")
        print("📝 Recipe names: \(recipes.map { $0.name })")
        
        // Mark recipes as loaded and check initialization
        hasLoadedRecipes = true
        checkInitialization()
        print("✅ Recipe load process complete")
    }
    
    private func loadBundledRecipes(into recipes: inout [Recipe]) {
        let recipeFiles = ["cappuccino", "earl_grey"]
        
        for filename in recipeFiles {
            if let url = Bundle.main.url(forResource: filename, withExtension: "json"),
               let data = try? Data(contentsOf: url),
               var recipe = try? JSONDecoder().decode(Recipe.self, from: data) {
                // Force built-in status and Brewpad creator for bundled recipes
                recipe = Recipe(
                    name: recipe.name,
                    category: recipe.category,
                    description: recipe.description,
                    ingredients: recipe.ingredients,
                    preparations: recipe.preparations,
                    isBuiltIn: true,
                    creator: "Brewpad"  // Set Brewpad as creator for system recipes
                )
                recipes.append(recipe)
            }
        }
    }
    
    private func loadUserRecipes(into recipes: inout [Recipe]) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let recipesDirectory = documentsDirectory.appendingPathComponent(recipesDirectoryName)
        
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(
            at: recipesDirectory,
            includingPropertiesForKeys: nil
        ).filter({ $0.pathExtension == "json" }) else {
            return
        }
        
        var loadedUserRecipes: [Recipe] = []
        for url in fileURLs {
            if let recipe = try? loadRecipe(from: url) {
                recipes.append(recipe)
                loadedUserRecipes.append(recipe)
            }
        }
        userRecipes = loadedUserRecipes
    }
    
    private func loadRecipe(from url: URL) throws -> Recipe {
        let data = try Data(contentsOf: url)
        let recipe = try JSONDecoder().decode(Recipe.self, from: data)
        print("Successfully loaded recipe: \(recipe.name)")
        return recipe
    }
    
    func getRecipesForCategory(_ category: String) -> [Recipe] {
        if category == "All" {
            return recipes
        }
        return recipes.filter { $0.category.rawValue == category }
    }
    
    private func generateFilename(for recipe: Recipe) -> String {
        let uuidSuffix = recipe.id.uuidString.suffix(8)
        return "\(recipe.name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(uuidSuffix).json"
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        print("🗑️ Starting deletion process for recipe: \(recipe.name)")
        
        // Only allow deletion of user recipes
        guard !recipe.isBuiltIn else {
            print("❌ Cannot delete built-in recipe: \(recipe.name)")
            return
        }
        
        print("📝 Recipe is user-created, proceeding with deletion")
        
        // Remove from memory
        let initialCount = recipes.count
        recipes.removeAll { $0.id == recipe.id }
        userRecipes.removeAll { $0.id == recipe.id }
        print("🗄️ Removed from memory - Recipes count before: \(initialCount), after: \(recipes.count)")
        
        // Remove file from disk
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Failed to access documents directory")
            return
        }
        
        let recipesDirectory = documentsDirectory.appendingPathComponent("Recipes", isDirectory: true)
        let filename = generateFilename(for: recipe)
        let fileURL = recipesDirectory.appendingPathComponent(filename)
        print("📂 Attempting to delete file at: \(fileURL.path)")
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("✅ Successfully deleted recipe file from disk")
        } catch {
            print("❌ Failed to delete recipe file: \(error.localizedDescription)")
        }
        
        // Force reload
        print("🔄 Forcing recipe store reload")
        isInitialized = false
        loadRecipes()
        print("✅ Deletion process complete")
    }
} 
import Foundation
import SwiftUI

class RecipeStore: ObservableObject {
    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var userRecipes: [Recipe] = []
    @Published private(set) var isInitialized = false
    @Published var showServerError = false
    @Published var serverResponse: String?
    @Published var serverFetchedRecipes: [String] = []
    private let recipesDirectoryName = "Recipes"
    private let serverBaseURL = "https://bprs.mirreravencd.com/recipes/"
    private var hasLoadedRecipes = false
    private var hasFetchedServerRecipes = false
    private var minimumSplashTimeElapsed = false
    
    init() {
        // Start loading immediately
        loadRecipes()
        fetchServerRecipes()
        checkServerConnection()
        
        // Ensure minimum splash screen duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.minimumSplashTimeElapsed = true
            self.checkInitialization()
        }
    }
    
    private func checkInitialization() {
        if hasLoadedRecipes && minimumSplashTimeElapsed && hasFetchedServerRecipes {
            DispatchQueue.main.async {
                self.isInitialized = true
            }
        }
    }

    func checkServerConnection() {
        guard let url = URL(string: "https://bprs.mirreravencd.com") else { return }

        URLSession.shared.dataTask(with: url) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    self.serverResponse = "Status: \(statusCode)"
                    self.showServerError = !(200...299).contains(statusCode) || error != nil
                } else if let error = error {
                    self.serverResponse = "Error: \(error.localizedDescription)"
                    self.showServerError = true
                } else {
                    self.serverResponse = "No response"
                    self.showServerError = true
                }
            }
        }.resume()
    }

    /// Fetches the list of recipes from the Brewpad remote server and downloads
    /// all files found in the index. After downloading, the local recipe list
    /// will be reloaded.
    private func fetchServerRecipes() {
        guard let listingURL = URL(string: serverBaseURL) else { return }

        URLSession.shared.dataTask(with: listingURL) { data, response, error in
            guard let data = data, error == nil,
                  let content = String(data: data, encoding: .utf8) else {
                print("❌ Failed to fetch recipe listing: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.hasFetchedServerRecipes = true
                    self.checkInitialization()
                }
                return
            }

            let fileNames = self.extractRecipeFileNames(from: content)

            DispatchQueue.main.async {
                self.serverFetchedRecipes = fileNames
            }

            let dispatchGroup = DispatchGroup()

            for name in fileNames {
                dispatchGroup.enter()
                self.downloadRecipe(named: name) {
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.hasFetchedServerRecipes = true
                self.loadRecipes()
            }
        }.resume()
    }

    private func extractRecipeFileNames(from content: String) -> [String] {
        let pattern = "[A-Za-z0-9_./-]+\\.brewpadrecipe"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let range = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, options: [], range: range)
        let names = matches.compactMap { match -> String? in
            guard let range = Range(match.range, in: content) else { return nil }
            var name = String(content[range])
            if let last = name.split(separator: "/").last { name = String(last) }
            return name
        }
        return Array(Set(names))
    }
    /// Downloads a single recipe file from the server and stores it locally.
    /// Any existing file with the same name will be overwritten.
    private func downloadRecipe(named fileName: String, completion: @escaping () -> Void) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let downloadURL = URL(string: "\(serverBaseURL)/\(fileName)") else {
            completion()
            return
        }

        let recipesDirectory = documentsDirectory.appendingPathComponent(recipesDirectoryName)

        if !FileManager.default.fileExists(atPath: recipesDirectory.path) {
            try? FileManager.default.createDirectory(at: recipesDirectory, withIntermediateDirectories: true)
        }

        let destinationURL = recipesDirectory.appendingPathComponent(fileName)

        URLSession.shared.dataTask(with: downloadURL) { data, _, error in
            guard let data = data, error == nil else {
                print("❌ Failed to download recipe \(fileName): \(error?.localizedDescription ?? "Unknown error")")
                completion()
                return
            }

            var recipeData = data
            if var recipe = try? JSONDecoder().decode(Recipe.self, from: data),
               recipe.creator == "Unknown" {
                // Default creator when missing
                recipe = Recipe(
                    id: recipe.id,
                    name: recipe.name,
                    category: recipe.category,
                    description: recipe.description,
                    ingredients: recipe.ingredients,
                    preparations: recipe.preparations,
                    isBuiltIn: recipe.isBuiltIn,
                    creator: "Brewpad",
                    isFeatured: recipe.isFeatured
                )
                recipeData = (try? JSONEncoder().encode(recipe)) ?? data
            }

            do {
                try recipeData.write(to: destinationURL)
                completion()
            } catch {
                print("❌ Failed to save recipe \(fileName): \(error.localizedDescription)")
                completion()
            }
        }.resume()
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
        ).filter({
            $0.pathExtension == "json" || $0.pathExtension == "brewpadrecipe"
        }) else {
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

    /// Returns all recipes marked as featured.
    func getFeaturedRecipes() -> [Recipe] {
        recipes.filter { $0.isFeatured }
    }
    
    private func generateFilename(for recipe: Recipe, withExtension fileExtension: String = "json") -> String {
        let uuidSuffix = recipe.id.uuidString.suffix(8)
        return "\(recipe.name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(uuidSuffix).\(fileExtension)"
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        print("🗑️ Starting deletion process for recipe: \(recipe.name)")
        
        // Only allow deletion of user recipes that are not published by Brewpad
        guard !recipe.isBuiltIn && recipe.creator != "Brewpad" else {
            print("❌ Cannot delete Brewpad recipe: \(recipe.name)")
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
        let jsonFilename = generateFilename(for: recipe, withExtension: "json")
        let brewpadFilename = generateFilename(for: recipe, withExtension: "brewpadrecipe")
        let jsonURL = recipesDirectory.appendingPathComponent(jsonFilename)
        let brewpadURL = recipesDirectory.appendingPathComponent(brewpadFilename)
        print("📂 Attempting to delete files:\n - \(jsonURL.path)\n - \(brewpadURL.path)")

        var deleted = false

        if FileManager.default.fileExists(atPath: jsonURL.path) {
            do {
                try FileManager.default.removeItem(at: jsonURL)
                deleted = true
                print("✅ Deleted .json file")
            } catch {
                print("❌ Failed to delete .json file: \(error.localizedDescription)")
            }
        }

        if FileManager.default.fileExists(atPath: brewpadURL.path) {
            do {
                try FileManager.default.removeItem(at: brewpadURL)
                deleted = true
                print("✅ Deleted .brewpadrecipe file")
            } catch {
                print("❌ Failed to delete .brewpadrecipe file: \(error.localizedDescription)")
            }
        }

        if !deleted {
            print("⚠️ No recipe file found to delete")
        }
        
        // Force reload
        print("🔄 Forcing recipe store reload")
        isInitialized = false
        loadRecipes()
        print("✅ Deletion process complete")
    }
} 

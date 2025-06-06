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
    private var minimumSplashDuration: TimeInterval = 2
    
    init() {
        // Determine if today is the user's birthday. If so, extend the
        // minimum splash screen duration to three seconds instead of two.
        if let birthday = UserDefaults.standard.object(forKey: "birthdate") as? Date {
            let calendar = Calendar.current
            let today = calendar.dateComponents([.month, .day], from: Date())
            let components = calendar.dateComponents([.month, .day], from: birthday)
            if today.month == components.month && today.day == components.day {
                minimumSplashDuration = 3
            }
        }

        // Start loading immediately
        loadRecipes()
        updateFromServer()
        checkServerConnection()

        // Ensure minimum splash screen duration
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumSplashDuration) {
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

    /// Public method to manually refresh recipes from the Brewpad server.
    /// - Parameter completion: Called once the refresh operation has finished.
    func updateFromServer(completion: (() -> Void)? = nil) {
        fetchServerRecipes(completion: completion)
    }

    /// Fetches the list of recipes from the Brewpad remote server and downloads
    /// all files found in the index. After downloading, the local recipe list
    /// will be reloaded.
    private func fetchServerRecipes(completion: (() -> Void)? = nil) {
        guard let listingURL = URL(string: serverBaseURL) else {
            completion?()
            return
        }

        print("🔎 Fetching server recipe list from \(listingURL.absoluteString)")

        URLSession.shared.dataTask(with: listingURL) { data, response, error in
            guard let data = data, error == nil,
                  let content = String(data: data, encoding: .utf8) else {
                print("❌ Failed to fetch recipe listing: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.hasFetchedServerRecipes = true
                    self.checkInitialization()
                }
                completion?()
                return
            }

            print("📄 Recipe listing fetched")

            let fileNames = self.extractRecipeFileNames(from: content)

            print("📜 Found \(fileNames.count) recipes: \(fileNames)")

            // Remove any server-imported recipes that are no longer listed
            self.removeDeletedServerRecipes(keeping: fileNames)
            DispatchQueue.main.async {
                self.loadRecipes()
            }

            DispatchQueue.main.async {
                self.serverFetchedRecipes = fileNames
            }

            print("⬇️ Beginning download of server recipes")
            self.downloadRecipesSequentially(fileNames) {
                print("✅ Finished downloading server recipes")
                DispatchQueue.main.async {
                    self.hasFetchedServerRecipes = true
                    self.loadRecipes()
                    completion?()
                }
            }
        }.resume()
    }

    /// Downloads a list of recipes sequentially. Each recipe will be downloaded
    /// one by one to avoid overwhelming the network session. Once all downloads
    /// are complete the provided completion handler will be called. Uses an
    /// iterative loop rather than recursion to avoid stack growth.
    private func downloadRecipesSequentially(_ names: [String], completion: @escaping () -> Void) {
        guard !names.isEmpty else {
            print("🏁 Completed sequential downloads")
            completion()
            return
        }

        Task { [weak self] in
            guard let self = self else { return }

            for (index, name) in names.enumerated() {
                print("⬇️ Downloading recipe \(name) (\(index + 1)/\(names.count))")

                await withCheckedContinuation { continuation in
                    self.downloadRecipe(named: name) {
                        print("✅ Finished download of \(name)")
                        continuation.resume()
                    }
                }
            }

            print("🏁 Completed sequential downloads")
            await MainActor.run {
                completion()
            }
        }
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

    /// Removes any server-provided recipes that no longer exist on the server.
    /// - Parameter serverNames: The list of recipe filenames currently available on the server.
    private func removeDeletedServerRecipes(keeping serverNames: [String]) {
        // Convert to a set for O(1) lookups
        let serverNameSet = Set(serverNames)
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let recipesDirectory = documentsDirectory.appendingPathComponent(recipesDirectoryName)
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: recipesDirectory, includingPropertiesForKeys: nil) else { return }

        let localServerFiles = fileURLs.filter { $0.pathExtension.lowercased() == "brewpadrecipe" }

        for url in localServerFiles {
            let name = url.lastPathComponent
            if !serverNameSet.contains(name) {
                do {
                    try FileManager.default.removeItem(at: url)
                    print("🗑️ Removed server-deleted recipe: \(name)")
                } catch {
                    print("❌ Failed to remove server-deleted recipe \(name): \(error.localizedDescription)")
                }
            }
        }
    }
    /// Downloads a single recipe file from the server and stores it locally.
    /// Any existing file with the same name will be overwritten.
    /// The file is fetched from `https://bprs.mirreravencd.com/recipes/` using
    /// the provided name with the `.brewpadrecipe` extension.
    private func downloadRecipe(named fileName: String, completion: @escaping () -> Void) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not locate documents directory for \(fileName)")
            completion()
            return
        }

        let recipeName = fileName.lowercased().hasSuffix(".brewpadrecipe")
            ? fileName
            : "\(fileName).brewpadrecipe"
        guard let downloadURL = URL(string: "\(serverBaseURL)\(recipeName)") else {
            print("❌ Invalid download URL for \(fileName)")
            completion()
            return
        }

        let recipesDirectory = documentsDirectory.appendingPathComponent(recipesDirectoryName)

        if !FileManager.default.fileExists(atPath: recipesDirectory.path) {
            try? FileManager.default.createDirectory(at: recipesDirectory, withIntermediateDirectories: true)
        }

        let destinationURL = recipesDirectory.appendingPathComponent(recipeName)

        print("🌐 Fetching \(recipeName) from \(downloadURL.absoluteString)")

        URLSession.shared.dataTask(with: downloadURL) { data, _, error in
            guard let data = data, error == nil else {
                print("❌ Failed to download recipe \(fileName): \(error?.localizedDescription ?? "Unknown error")")
                completion()
                return
            }

            guard data.count <= FileLimits.maxRecipeFileSize else {
                print("❌ Recipe \(fileName) exceeds size limit and was skipped")
                completion()
                return
            }

            print("📥 Downloaded data for \(fileName)")

            var recipeData = data
            if var recipe = try? JSONDecoder().decode(Recipe.self, from: data) {
                // Overwrite creator for server-imported recipes
                recipe = Recipe(
                    id: recipe.id,
                    name: recipe.name,
                    category: recipe.category,
                    description: recipe.description,
                    ingredients: recipe.ingredients,
                    preparations: recipe.preparations,
                    isBuiltIn: recipe.isBuiltIn,
                    creator: recipe.isCommunityHighlight ? recipe.creator : "Brewpad",
                    isWeeklyFeature: recipe.isWeeklyFeature,
                    isCommunityHighlight: recipe.isCommunityHighlight
                )
                recipeData = (try? JSONEncoder().encode(recipe)) ?? data
            }

            do {
                print("💾 Saving \(recipeName) to \(destinationURL.path)")
                try recipeData.write(to: destinationURL)
                print("✅ Saved \(recipeName)")
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
                // Force built-in status and Brewpad creator while
                // stripping the feature flags. Only server-downloaded
                // recipes may retain featured states.
                recipe = Recipe(
                    id: recipe.id,
                    name: recipe.name,
                    category: recipe.category,
                    description: recipe.description,
                    ingredients: recipe.ingredients,
                    preparations: recipe.preparations,
                    isBuiltIn: true,
                    creator: "Brewpad",  // Set Brewpad as creator for system recipes
                    isWeeklyFeature: false,
                    isCommunityHighlight: false
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
            let ext = $0.pathExtension.lowercased()
            return ext == "json" || ext == "brewpadrecipe"
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
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[.size] as? NSNumber,
           fileSize.int64Value > FileLimits.maxRecipeFileSize {
            throw NSError(domain: "RecipeStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Recipe file too large"])
        }

        let data = try Data(contentsOf: url)
        var recipe = try JSONDecoder().decode(Recipe.self, from: data)

        // Only allow the feature flags for recipes downloaded from the server
        // which are stored with the `.brewpadrecipe` extension.
        if url.pathExtension.lowercased() != "brewpadrecipe" {
            recipe = Recipe(
                id: recipe.id,
                name: recipe.name,
                category: recipe.category,
                description: recipe.description,
                ingredients: recipe.ingredients,
                preparations: recipe.preparations,
                isBuiltIn: recipe.isBuiltIn,
                creator: recipe.creator,
                isWeeklyFeature: false,
                isCommunityHighlight: false
            )
        }

        print("Successfully loaded recipe: \(recipe.name)")
        return recipe
    }
    
    func getRecipesForCategory(_ category: String) -> [Recipe] {
        if category == "All" {
            return recipes
        }
        return recipes.filter { $0.category.rawValue == category }
    }

    /// Returns all recipes marked as weekly features.
    func getWeeklyFeatures() -> [Recipe] {
        recipes.filter { $0.isWeeklyFeature }
    }

    /// Returns all recipes marked as community highlights.
    func getCommunityHighlights() -> [Recipe] {
        recipes.filter { $0.isCommunityHighlight }
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

    /// Saves a recipe to the user's documents directory using the
    /// `.brewpadrecipe` extension and reloads the recipe list.
    func importRecipeToPermanent(_ recipe: Recipe) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Failed to access documents directory")
            return
        }

        let recipesDirectory = documentsDirectory.appendingPathComponent(recipesDirectoryName)
        if !FileManager.default.fileExists(atPath: recipesDirectory.path) {
            try? FileManager.default.createDirectory(at: recipesDirectory, withIntermediateDirectories: true)
        }

        // Create a fresh copy of the recipe with a new ID and without any
        // featured flags. The creator is updated so the UI can display the
        // original author.
        let copiedRecipe = Recipe(
            name: recipe.name,
            category: recipe.category,
            description: recipe.description,
            ingredients: recipe.ingredients,
            preparations: recipe.preparations,
            isBuiltIn: false,
            creator: "Copied from \(recipe.creator)",
            isWeeklyFeature: false,
            isCommunityHighlight: false
        )

        let filename = generateFilename(for: copiedRecipe, withExtension: "brewpadrecipe")
        let destinationURL = recipesDirectory.appendingPathComponent(filename)

        do {
            let data = try JSONEncoder().encode(copiedRecipe)
            try data.write(to: destinationURL)
            print("✅ Imported recipe to \(destinationURL.path)")
            loadRecipes()
        } catch {
            print("❌ Failed to import recipe: \(error.localizedDescription)")
        }
    }
}

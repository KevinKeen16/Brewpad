import SwiftUI

struct RecipeEditorView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var settingsManager: SettingsManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    // If recipe is provided, we're in edit mode
    let existingRecipe: Recipe?
    let isImporting: Bool
    
    @State private var recipeName: String
    @State private var category: Recipe.Category
    @State private var description: String
    @State private var ingredients: [String]
    @State private var preparations: [String]
    @State private var showingSaveAlert = false
    @State private var saveError: String?
    @State private var showingDeleteConfirmation = false
    
    // Initialize with optional existing recipe
    init(recipe: Recipe? = nil, isImporting: Bool = false) {
        self.existingRecipe = recipe
        self.isImporting = isImporting
        _recipeName = State(initialValue: recipe?.name ?? "")
        _category = State(initialValue: recipe?.category ?? .coffee)
        _description = State(initialValue: recipe?.description ?? "")
        _ingredients = State(initialValue: recipe?.ingredients ?? [""])
        _preparations = State(initialValue: recipe?.preparations ?? [""])
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Basic Information")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        TextField("Recipe Name", text: $recipeName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Picker("Category", selection: $category) {
                            ForEach(Recipe.Category.allCases, id: \.self) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05)))
                    
                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Ingredients")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Spacer()
                            Button(action: { ingredients.append("") }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        ForEach(ingredients.indices, id: \.self) { index in
                            HStack {
                                TextField("Ingredient \(index + 1)", text: $ingredients[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                if ingredients.count > 1 {
                                    Button(action: { ingredients.remove(at: index) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05)))
                    
                    // Preparation Steps Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Preparation Steps")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Spacer()
                            Button(action: { preparations.append("") }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        ForEach(preparations.indices, id: \.self) { index in
                            HStack {
                                Text("\(index + 1).")
                                    .foregroundColor(.blue)
                                    .frame(width: 25, alignment: .leading)
                                
                                TextField("Step \(index + 1)", text: $preparations[index], axis: .vertical)
                                    .lineLimit(2...4)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                if preparations.count > 1 {
                                    Button(action: { preparations.remove(at: index) }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05)))
                    
                    // Save Button
                    Button(action: saveRecipe) {
                        Text(isImporting ? "Import Recipe" : "Save Recipe")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(isFormValid ? 1 : 0.5))
                            )
                    }
                    .disabled(!isFormValid)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle(existingRecipe == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if existingRecipe != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .alert("Save Recipe", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            if let error = saveError {
                Text("Error: \(error)")
            } else {
                Text("Recipe saved successfully!")
            }
        }
        .alert("Delete Recipe", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let recipe = existingRecipe {
                    recipeStore.deleteRecipe(recipe)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this recipe? This action cannot be undone.")
        }
    }
    
    private var isFormValid: Bool {
        !recipeName.isEmpty &&
        !description.isEmpty &&
        !ingredients.contains(where: { $0.isEmpty }) &&
        !preparations.contains(where: { $0.isEmpty })
    }
    
    private func generateFilename(for recipe: Recipe) -> String {
        // Get last 8 characters of UUID as suffix
        let uuidSuffix = recipe.id.uuidString.suffix(8)
        // Combine name and UUID suffix
        return "\(recipe.name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(uuidSuffix).json"
    }
    
    private func saveRecipe() {
        print("💾 Starting recipe save process")
        
        let recipe = Recipe(
            id: existingRecipe?.id ?? UUID(),
            name: recipeName,
            category: category,
            description: description,
            ingredients: ingredients.filter { !$0.isEmpty },
            preparations: preparations.filter { !$0.isEmpty },
            isBuiltIn: existingRecipe?.isBuiltIn ?? false,
            creator: isImporting ? existingRecipe?.creator ?? "Unknown" : settingsManager.username ?? "Unknown",
            isFeatured: existingRecipe?.isFeatured ?? false
        )
        print("📝 Created recipe object: \(recipe.name)")
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(recipe)
            
            // Create filename with UUID suffix
            let filename = generateFilename(for: recipe)
            print("📄 Generated filename: \(filename)")
            
            // Get the documents directory
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let recipesDirectory = documentsDirectory.appendingPathComponent("Recipes")
                print("📂 Recipes directory: \(recipesDirectory.path)")
                
                // Create Recipes directory if it doesn't exist
                if !FileManager.default.fileExists(atPath: recipesDirectory.path) {
                    try FileManager.default.createDirectory(at: recipesDirectory, withIntermediateDirectories: true)
                    print("📁 Created Recipes directory")
                }
                
                let fileURL = recipesDirectory.appendingPathComponent(filename)
                print("💾 Saving recipe to: \(fileURL.path)")
                
                // If we're editing and the name changed, delete the old file
                if let oldRecipe = existingRecipe,
                   oldRecipe.name != recipe.name {
                    let oldFilename = generateFilename(for: oldRecipe)
                    let oldFileURL = recipesDirectory.appendingPathComponent(oldFilename)
                    if FileManager.default.fileExists(atPath: oldFileURL.path) {
                        try FileManager.default.removeItem(at: oldFileURL)
                        print("🗑️ Deleted old recipe file: \(oldFileURL.path)")
                    }
                }
                
                // Write the new file
                try data.write(to: fileURL)
                print("✅ Successfully saved recipe file")
                
                // Reload recipes to include the changes
                recipeStore.loadRecipes()
                print("🔄 Reloaded recipe store")
                
                saveError = nil
                showingSaveAlert = true
                
                // Add reinitialization at the end of successful save
                appState.reinitialize(for: existingRecipe == nil ? .recipeCreated : .recipeEdited)
                dismiss()
                print("✅ Save process complete")
            }
        } catch {
            print("❌ Error saving recipe: \(error.localizedDescription)")
            saveError = error.localizedDescription
            showingSaveAlert = true
        }
    }
} 
import SwiftUI

struct RecipeDebugView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // System Recipes Section
                Section("System Recipes") {
                    ForEach(recipeStore.recipes.filter { $0.isBuiltIn }, id: \.id) { recipe in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name)
                                .font(.headline)
                            Text("UUID: \(recipe.id.uuidString)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("File: \(generateFilename(for: recipe))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // User Recipes Section
                Section("User Recipes") {
                    ForEach(recipeStore.recipes.filter { !$0.isBuiltIn }, id: \.id) { recipe in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name)
                                .font(.headline)
                            Text("UUID: \(recipe.id.uuidString)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("File: \(generateFilename(for: recipe))")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Server Response Section
                Section("Server Response") {
                    if let response = recipeStore.serverResponse {
                        Text(response)
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("No response yet")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    if !recipeStore.serverFetchedRecipes.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fetched Recipes:")
                                .font(.subheadline)
                            ForEach(recipeStore.serverFetchedRecipes, id: \.self) { recipe in
                                Text(recipe)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recipe Debug Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                recipeStore.checkServerConnection()
            }
        }
    }
    
    private func generateFilename(for recipe: Recipe) -> String {
        let uuidSuffix = recipe.id.uuidString.suffix(8)
        return "\(recipe.name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(uuidSuffix).json"
    }
} 
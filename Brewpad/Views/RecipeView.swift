import SwiftUI

struct RecipeView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @State private var selectedCategory = "All"
    @State private var expandedRecipeId: UUID?
    @State private var searchText = ""
    
    private var filteredRecipes: [Recipe] {
        let categoryRecipes = recipeStore.getRecipesForCategory(selectedCategory)
        if searchText.isEmpty {
            return categoryRecipes
        }
        return categoryRecipes.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Category Picker
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag("All")
                    ForEach(Recipe.Category.allCases, id: \.rawValue) { category in
                        Text(category.rawValue).tag(category.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Recipe List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredRecipes) { recipe in
                            RecipeCard(
                                recipe: recipe,
                                isExpanded: expandedRecipeId == recipe.id,
                                onTap: {
                                    withAnimation {
                                        expandedRecipeId = expandedRecipeId == recipe.id ? nil : recipe.id
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes")
            .id(recipeStore.recipes.count)
        }
    }
} 
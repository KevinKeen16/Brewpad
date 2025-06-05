import SwiftUI

struct FeaturedRecipesView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @State private var expandedRecipe: UUID?
    @State private var selectedCategory: Category = .weekly

    enum Category: String, CaseIterable, Identifiable {
        case weekly = "Weekly Recommendations"
        case community = "Community Highlights"
        case favorites = "Our Favorites"

        var id: Self { self }
    }

    private var weeklyRecommendations: [Recipe] {
        recipeStore.getFeaturedRecipes()
    }

    private var communityHighlights: [Recipe] {
        recipeStore.userRecipes
    }

    private var favoriteRecipes: [Recipe] {
        favoritesManager.favorites(in: recipeStore.recipes)
    }

    private var displayedRecipes: [Recipe] {
        switch selectedCategory {
        case .weekly: return weeklyRecommendations
        case .community: return communityHighlights
        case .favorites: return favoriteRecipes
        }
    }

    var body: some View {
        ScrollView {
            Picker("Category", selection: $selectedCategory) {
                ForEach(Category.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            LazyVStack(spacing: 12) {
                ForEach(displayedRecipes) { recipe in
                    RecipeCard(
                        recipe: recipe,
                        isExpanded: expandedRecipe == recipe.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                expandedRecipe = expandedRecipe == recipe.id ? nil : recipe.id
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Featured")
    }
}

#Preview {
    FeaturedRecipesView()
        .environmentObject(RecipeStore())
        .environmentObject(FavoritesManager())
}

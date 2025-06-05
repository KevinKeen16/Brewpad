import SwiftUI

struct FeaturedRecipesView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @State private var expandedRecipe: UUID?

    private var weeklyRecommendations: [Recipe] {
        recipeStore.getFeaturedRecipes()
    }

    private var communityHighlights: [Recipe] {
        recipeStore.userRecipes
    }

    private var favoriteRecipes: [Recipe] {
        favoritesManager.favorites(in: recipeStore.recipes)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                categorySection(title: "Weekly Recommendations", recipes: weeklyRecommendations)
                categorySection(title: "Community Highlights", recipes: communityHighlights)
                categorySection(title: "Our Favorites", recipes: favoriteRecipes)
            }
            .padding(.vertical)
        }
        .navigationTitle("Featured")
    }

    @ViewBuilder
    private func categorySection(title: String, recipes: [Recipe]) -> some View {
        if !recipes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .padding(.leading)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recipes) { recipe in
                            RecipeCard(
                                recipe: recipe,
                                isExpanded: expandedRecipe == recipe.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        expandedRecipe = expandedRecipe == recipe.id ? nil : recipe.id
                                    }
                                }
                            )
                            .frame(width: 300)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    FeaturedRecipesView()
        .environmentObject(RecipeStore())
        .environmentObject(FavoritesManager())
}

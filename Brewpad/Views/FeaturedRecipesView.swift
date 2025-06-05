import SwiftUI

struct FeaturedRecipesView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var favoritesManager: FavoritesManager
    // Track which recipes are expanded. New cards start expanded by default.
    @State private var expandedRecipes: Set<UUID> = []

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
        .navigationBarTitleDisplayMode(.inline)
    }

    private func explainer(for title: String) -> String {
        switch title {
        case "Weekly Recommendations":
            return "Hand-picked by the Brewpad team."
        case "Community Highlights":
            return "Popular creations from the community."
        case "Our Favorites":
            return "Recipes you've starred." 
        default:
            return ""
        }
    }

    @ViewBuilder
    private func categorySection(title: String, recipes: [Recipe]) -> some View {
        if !recipes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .padding(.leading)

                Text(explainer(for: title))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recipes) { recipe in
                            RecipeCard(
                                recipe: recipe,
                                isExpanded: expandedRecipes.contains(recipe.id),
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if expandedRecipes.contains(recipe.id) {
                                            expandedRecipes.remove(recipe.id)
                                        } else {
                                            expandedRecipes.insert(recipe.id)
                                        }
                                    }
                                }
                            )
                            .frame(width: 300)
                            .onAppear {
                                // Expand cards when first shown
                                expandedRecipes.insert(recipe.id)
                            }
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

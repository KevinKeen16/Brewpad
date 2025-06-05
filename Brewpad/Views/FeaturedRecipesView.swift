import SwiftUI

struct FeaturedRecipesView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var favoritesManager: FavoritesManager
    // Track which categories are collapsed
    @State private var collapsedCategories: Set<String> = []

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
            VStack(spacing: 24) {
                categorySection(title: "Weekly Recommendations", recipes: weeklyRecommendations)
                categorySection(title: "Community Highlights", recipes: communityHighlights)
                categorySection(title: "Our Favorites", recipes: favoriteRecipes)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Featured")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func explainer(for title: String) -> String {
        switch title {
        case "Weekly Recommendations":
            return "Hand-picked suggestions from the Brewpad team to inspire your next brew."
        case "Community Highlights":
            return "Popular creations from fellow users. See what the community is enjoying."
        case "Our Favorites":
            return "Recipes you've starred for quick access to the drinks you love most."
        default:
            return ""
        }
    }

    @ViewBuilder
    private func categorySection(title: String, recipes: [Recipe]) -> some View {
        if !recipes.isEmpty {
            VStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut) {
                        if collapsedCategories.contains(title) {
                            collapsedCategories.remove(title)
                        } else {
                            collapsedCategories.insert(title)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.headline)
                        Image(systemName: collapsedCategories.contains(title) ? "chevron.down" : "chevron.up")
                    }
                    .frame(maxWidth: .infinity)
                }

                if !collapsedCategories.contains(title) {
                    Text(explainer(for: title))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Spacer(minLength: 0)
                            ForEach(recipes) { recipe in
                                RecipeCard(
                                    recipe: recipe,
                                    isExpanded: true,
                                    onTap: {}
                                )
                                .frame(width: 300)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    FeaturedRecipesView()
        .environmentObject(RecipeStore())
        .environmentObject(FavoritesManager())
}

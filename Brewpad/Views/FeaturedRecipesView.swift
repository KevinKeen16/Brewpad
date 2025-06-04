import SwiftUI

struct FeaturedRecipesView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @State private var expandedRecipe: UUID?

    private var featuredRecipes: [Recipe] {
        recipeStore.getFeaturedRecipes()
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(featuredRecipes) { recipe in
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
}

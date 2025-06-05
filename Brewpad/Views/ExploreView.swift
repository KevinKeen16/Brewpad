import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var recipeStore: RecipeStore

    var featuredRecipes: [Recipe] {
        recipeStore.recipes.filter { $0.isWeeklyFeature }
    }

    var body: some View {
        ScrollView {
            VStack {
                if !featuredRecipes.isEmpty {
                    Text("Featured Recipes")
                        .font(.headline)
                        .padding()

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(featuredRecipes) { recipe in
                                FeaturedRecipeCard(recipe: recipe)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Other content can go here
            }
        }
        .navigationTitle("Explore")
    }
}

struct FeaturedRecipeCard: View {
    let recipe: Recipe
    @EnvironmentObject private var recipeStore: RecipeStore

    var body: some View {
        VStack {
            Image(systemName: "photo") // Placeholder for recipe image
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .shadow(radius: 5)

            Text(recipe.name)
                .fontWeight(.semibold)

            Button("Import") {
                recipeStore.importRecipeToPermanent(recipe)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
} 
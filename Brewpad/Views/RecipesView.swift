import SwiftUI

struct RecipesView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedCategory = 0
    @State private var expandedRecipe: UUID?
    @State private var slideDirection: SlideDirection = .none
    @Namespace private var animation
    @State private var showAgeRestrictionAlert = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var selectedRecipeId: UUID?
    
    enum SlideDirection {
        case left, right, none
    }
    
    let categories = ["All"] + Recipe.Category.allCases.map(\.rawValue)

    private var displayedRecipes: [Recipe] {
        var base: [Recipe]
        if isSearching && !searchText.isEmpty {
            base = recipeStore.recipes.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        } else {
            base = recipeStore.getRecipesForCategory(categories[selectedCategory])
        }

        if showFavoritesOnly {
            base = favoritesManager.favorites(in: base)
        }

        // Hide featured recipes unless they are a favorite
        base.removeAll {
            ($0.isWeeklyFeature || $0.isCommunityHighlight) &&
            !favoritesManager.isFavorite($0.id)
        }

        return base
    }
    
    private var selectedRecipe: Recipe? {
        guard let id = selectedRecipeId else { return nil }
        return recipeStore.recipes.first { $0.id == id }
    }

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadBody
            } else {
                phoneBody
            }
        }
        .alert("Age Restriction", isPresented: $showAgeRestrictionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You must be 18 or older to view alcoholic beverage recipes. Please verify your age in Settings.")
        }
    }

    private var headerView: some View {
        VStack(spacing: 0) {
            if isSearching {
                HStack {
                    TextField("Search recipes", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut) { isSearching.toggle() }
                            if !isSearching { searchText = "" }
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .padding(.trailing)
                    }
                    .padding(.vertical, 8)
                    .background(settingsManager.colors.divider.opacity(0.1))
                    .transition(.move(edge: .trailing))
                } else {
                    HStack(spacing: 0) {
                        Button {
                            withAnimation { showFavoritesOnly.toggle() }
                        } label: {
                            Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                                .padding(.leading)
                                .foregroundColor(settingsManager.colors.accent)
                        }
                        .padding(.trailing)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 2) {
                                ForEach(0..<categories.count, id: \.self) { index in
                                    CategoryTab(
                                        title: categories[index],
                                        isSelected: selectedCategory == index,
                                        animation: animation
                                    ) {
                                        if categories[index] == "Alcohol" && !settingsManager.isOver18 {
                                            showAgeRestrictionAlert = true
                                        } else {
                                            updateCategory(to: index)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        Button {
                            withAnimation(.easeInOut) { isSearching.toggle() }
                            if !isSearching { searchText = "" }
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .padding(.leading)
                        .padding(.trailing)
                    }
                    .padding(.vertical, 8)
                    .background(settingsManager.colors.divider.opacity(0.1))

                    if let description = categoryDescriptions[categories[selectedCategory]] {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(settingsManager.colors.textSecondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(settingsManager.colors.divider.opacity(0.2))
                            .transition(.opacity)
                            .animation(.easeInOut, value: selectedCategory)
                    }
                }
        }
    }

    private var phoneBody: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                if horizontalSizeClass == .regular {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12)], spacing: 12) {
                        ForEach(displayedRecipes) { recipe in
                            RecipeCard(
                                recipe: recipe,
                                isExpanded: expandedRecipe == recipe.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        expandedRecipe = expandedRecipe == recipe.id ? nil : recipe.id
                                    }
                                },
                                showsDownloadButton: false
                            )
                        }
                    }
                    .padding()
                    if showFavoritesOnly && displayedRecipes.isEmpty {
                        Text("You have no favorites for this category")
                            .foregroundColor(settingsManager.colors.textSecondary)
                            .padding()
                    }
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(displayedRecipes) { recipe in
                            RecipeCard(
                                recipe: recipe,
                                isExpanded: expandedRecipe == recipe.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        expandedRecipe = expandedRecipe == recipe.id ? nil : recipe.id
                                    }
                                },
                                showsDownloadButton: false
                            )
                        }
                        if showFavoritesOnly && displayedRecipes.isEmpty {
                            Text("You have no favorites for this category")
                                .foregroundColor(settingsManager.colors.textSecondary)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var iPadBody: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                headerView
                List(displayedRecipes, selection: $selectedRecipeId) { recipe in
                    HStack {
                        Text(recipe.name)
                        Spacer()
                        if favoritesManager.isFavorite(recipe.id) {
                            Image(systemName: "star.fill")
                                .foregroundColor(settingsManager.colors.accent)
                        }
                    }
                    .contentShape(Rectangle())
                    .tag(recipe.id)
                }
                .listStyle(.plain)
            }
        } detail: {
            if let recipe = selectedRecipe {
                ScrollView {
                    RecipeCard(
                        recipe: recipe,
                        isExpanded: true,
                        onTap: {},
                        showsDownloadButton: false
                    )
                    .padding()
                }
                .navigationTitle(recipe.name)
            } else {
                Text("Select a recipe")
                    .foregroundColor(.secondary)
                    .navigationTitle("Recipe")
            }
        }
    }
    
    private func updateCategory(to newIndex: Int) {
        slideDirection = newIndex > selectedCategory ? .right : .left
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedCategory = newIndex
            expandedRecipe = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            slideDirection = .none
        }
    }
    
    private func deleteRecipe(_ recipe: Recipe) {
        withAnimation {
            recipeStore.deleteRecipe(recipe)
            appState.reinitialize(for: .recipeDeleted)
        }
    }
}

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    @EnvironmentObject private var settingsManager: SettingsManager
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? settingsManager.colors.accent : .primary)
        }
    }
}

let categoryDescriptions = [
    "All": "Browse through our complete collection of handcrafted beverage recipes. From morning pick-me-ups to evening delights, find the perfect drink for any moment.",
    "Coffee": "Explore our selection of coffee-based beverages, from classic espresso drinks to creative coffee concoctions. Perfect for coffee enthusiasts seeking their next favorite brew.",
    "Tea": "Discover traditional and modern tea preparations that bring out the best flavors of different tea varieties. Relaxing and refreshing options for tea lovers.",
    "Green Tea": "Experience the subtle flavors and health benefits of green tea and matcha-based drinks. Fresh, earthy, and perfectly balanced recipes.",
    "Milk": "Indulge in our creamy milk-based beverages, from classic steamers to innovative milk drinks. Comforting and satisfying options for any time of day.",
    "Chocolate": "Dive into rich and decadent chocolate-based drinks, from classic hot chocolate to creative mocha variations. Pure chocolate bliss in every sip.",
    "Alcohol": "Explore our collection of spirited beverages that combine various ingredients with alcohol. Perfect for social gatherings and evening enjoyment."
] 
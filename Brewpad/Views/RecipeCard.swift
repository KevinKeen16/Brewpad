import SwiftUI

struct RecipeCard: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var notesManager: NotesManager
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @State private var showingNoteSheet = false
    @State private var selectedSection = 0
    @State private var showingDeleteConfirmation = false
    @State private var favoriteScale: CGFloat = 1.0
    @State private var favoriteRotation: Double = 0

    let recipe: Recipe
    let isExpanded: Bool
    let onTap: () -> Void
    /// When true, a download button will be shown while the card is expanded.
    /// This defaults to `false` so the button only appears when explicitly
    /// requested (e.g. from the Featured tab).
    let showsDownloadButton: Bool

    init(
        recipe: Recipe,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        showsDownloadButton: Bool = false
    ) {
        self.recipe = recipe
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.showsDownloadButton = showsDownloadButton
    }
    
    private let expandedHeight: CGFloat = 300
    
    var body: some View {
        ZStack(alignment: .top) {
            if isExpanded {
                VStack(spacing: 0) {
                    Spacer(minLength: 70)
                    
                    TabView(selection: $selectedSection) {
                        ScrollView {
                            descriptionView
                        }
                        .tag(0)
                        
                        ScrollView {
                            ingredientsView
                        }
                        .tag(1)
                        
                        ScrollView {
                            preparationView
                        }
                        .tag(2)
                        
                        ScrollView {
                            notesView
                        }
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: expandedHeight)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(selectedSection == index ? settingsManager.colors.accent : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .background(settingsManager.colors.divider.opacity(0.2))
                .cornerRadius(10)
                .transition(
                    .asymmetric(
                        insertion:
                            .opacity
                            .combined(with: .scale(scale: 0.9, anchor: .top))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8)),
                        removal:
                            .opacity
                            .combined(with: .scale(scale: 0.9, anchor: .top))
                            .animation(.spring(response: 0.35, dampingFraction: 1.0))
                    )
                )
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .font(.headline)
                    HStack {
                        Text(recipe.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(settingsManager.colors.textSecondary)
                        Text("•")
                            .foregroundColor(settingsManager.colors.textSecondary)
                        let creatorText: String = {
                            if recipe.creator.lowercased().hasPrefix("copied from") {
                                return recipe.creator
                            } else {
                                return "by \(recipe.creator)"
                            }
                        }()
                        Text(creatorText)
                            .font(.subheadline)
                            .foregroundColor(settingsManager.colors.textSecondary)
                    }
                }
                Spacer()
                if isExpanded {
                    Button {
                        favoritesManager.toggleFavorite(recipe.id)
                        animateFavorite()
                    } label: {
                        Image(systemName: favoritesManager.isFavorite(recipe.id) ? "star.fill" : "star")
                            .foregroundColor(settingsManager.colors.accent)
                            .rotationEffect(.degrees(favoriteRotation))
                            .scaleEffect(favoriteScale)
                    }

                    if showsDownloadButton {
                        Button {
                            recipeStore.importRecipeToPermanent(recipe)
                        } label: {
                            Image(systemName: "tray.and.arrow.down")
                                .foregroundColor(settingsManager.colors.accent)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(settingsManager.colors.divider.opacity(0.1))
            .cornerRadius(10)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .contextMenu {
                if !recipe.isBuiltIn && recipe.creator != "Brewpad" {
                    Button(role: .destructive) {
                        print("🗑️ Delete button tapped for recipe: \(recipe.name)")
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                }
            }
        }
        .zIndex(isExpanded ? 1 : 0)
        .sheet(isPresented: $showingNoteSheet) {
            AddNoteView(recipe: recipe)
        }
        .alert("Delete Recipe", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                print("⚠️ Delete confirmed for recipe: \(recipe.name)")
                withAnimation {
                    recipeStore.deleteRecipe(recipe)
                }
            }
        } message: {
            Text("Are you sure you want to delete this recipe? This action cannot be undone.")
        }
    }
    
    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundColor(settingsManager.colors.accent)
            Text(recipe.description)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var ingredientsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.headline)
                .foregroundColor(settingsManager.colors.accent)
            ForEach(recipe.ingredients, id: \.self) { ingredient in
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(settingsManager.colors.accent)
                    Text(
                        MeasurementConverter.convert(
                            ingredient,
                            toImperial: !settingsManager.useMetricUnits
                        )
                    )
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var preparationView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preparation")
                .font(.headline)
                .foregroundColor(settingsManager.colors.accent)
            ForEach(Array(recipe.preparations.enumerated()), id: \.element) { index, step in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .foregroundColor(settingsManager.colors.accent)
                        .frame(width: 25, alignment: .leading)
                    Text(
                        MeasurementConverter.convert(
                            step,
                            toImperial: !settingsManager.useMetricUnits
                        )
                    )
                }
                .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var notesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(settingsManager.colors.accent)
                
                Spacer()
                
                Button(action: { showingNoteSheet = true }) {
                    Label("Add Note", systemImage: "square.and.pencil")
                        .foregroundColor(settingsManager.colors.accent)
                }
            }
            
            if notesManager.getNotesForRecipe(recipe.id).isEmpty {
                Text("No notes yet")
                    .font(.subheadline)
                    .foregroundColor(settingsManager.colors.textSecondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
            } else {
                ForEach(notesManager.getNotesForRecipe(recipe.id)) { note in
                    NoteBubble(note: note)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .animation(.spring(response: 0.3), value: notesManager.getNotesForRecipe(recipe.id))
    }

    private func animateFavorite() {
        favoriteScale = 1.3
        favoriteRotation = 0
        withAnimation(.easeInOut(duration: 0.1)) {
            favoriteScale = 1.5
        }
        withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
            favoriteRotation = 15
        }
        withAnimation(.easeOut(duration: 0.2).delay(0.3)) {
            favoriteScale = 1.0
            favoriteRotation = 0
        }
    }
}

struct NoteBubble: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var notesManager: NotesManager
    @State private var showingDeleteConfirmation = false
    let note: RecipeNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.text)
                .font(.subheadline)
            
            Text(note.dateCreated.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(settingsManager.colors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(settingsManager.colors.divider.opacity(0.1))
        )
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete Note", systemImage: "trash")
            }
        }
        .alert("Delete Note", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    notesManager.deleteNote(note)
                }
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
}

struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var notesManager: NotesManager
    @State private var noteText = ""
    
    let recipe: Recipe
    
    var body: some View {
        NavigationView {
            Form {
                Section("Add Note") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Recipe Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        notesManager.addNote(to: recipe.id, text: noteText)
                        dismiss()
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
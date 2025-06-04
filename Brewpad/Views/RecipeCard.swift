import SwiftUI

struct RecipeCard: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var notesManager: NotesManager
    @EnvironmentObject private var recipeStore: RecipeStore
    @State private var showingNoteSheet = false
    @State private var selectedSection = 0
    @State private var showingDeleteConfirmation = false
    
    let recipe: Recipe
    let isExpanded: Bool
    let onTap: () -> Void
    
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
                                .fill(selectedSection == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
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
            
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(recipe.name)
                            .font(.headline)
                        HStack {
                            Text(recipe.category.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("•")
                                .foregroundColor(.gray)
                            Text("by \(recipe.creator)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                        .animation(.spring(response: 0.2), value: isExpanded)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
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
                .foregroundColor(.blue)
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
                .foregroundColor(.blue)
            ForEach(recipe.ingredients, id: \.self) { ingredient in
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(.blue)
                    Text(ingredient)
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
                .foregroundColor(.blue)
            ForEach(Array(recipe.preparations.enumerated()), id: \.element) { index, step in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .foregroundColor(.blue)
                        .frame(width: 25, alignment: .leading)
                    Text(step)
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
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button(action: { showingNoteSheet = true }) {
                    Label("Add Note", systemImage: "square.and.pencil")
                        .foregroundColor(.blue)
                }
            }
            
            if notesManager.getNotesForRecipe(recipe.id).isEmpty {
                Text("No notes yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
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
}

struct NoteBubble: View {
    @EnvironmentObject private var notesManager: NotesManager
    @State private var showingDeleteConfirmation = false
    let note: RecipeNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.text)
                .font(.subheadline)
            
            Text(note.dateCreated.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
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
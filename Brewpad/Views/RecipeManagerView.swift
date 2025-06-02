import SwiftUI
import UniformTypeIdentifiers

struct ShareSheet: UIViewControllerRepresentable {
    let recipe: Recipe
    let data: Data
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "\(recipe.name.lowercased().replacingOccurrences(of: " ", with: "_")).brewpadrecipe"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        // Write data to temp file
        try? data.write(to: fileURL)
        
        let controller = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // Clean up temp file after sharing
        controller.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct RecipeManagerView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @EnvironmentObject private var appState: AppState
    @State private var selectedAction: RecipeAction?
    @State private var recipeToEdit: Recipe?
    @State private var recipeToExport: Recipe?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showImportError = false
    @State private var importedRecipe: Recipe?
    @State private var showingShareSheet = false
    @State private var shareData: Data?
    @State private var recipeToShare: Recipe?
    @State private var notificationObserver: NSObjectProtocol?
    
    enum RecipeAction: Identifiable {
        case add, edit, export, `import`
        var id: Self { self }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Create Recipe Button
                Button {
                    selectedAction = .add
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Create Recipe")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Edit Recipe Button
                Button {
                    selectedAction = .edit
                } label: {
                    HStack {
                        Image(systemName: "pencil.circle")
                        Text("Edit Recipe")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Import Button
                Button {
                    selectedAction = .import
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Recipes")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                // Export Button
                Button {
                    selectedAction = .export
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Recipes")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // Disclaimer
                VStack(spacing: 12) {
                    Text("Recipe Management")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Create, edit, import, and export your custom recipes. Imported recipes will be added to your personal collection.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("Important Information")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                    
                    Text("• Importing recipes is done at your own risk. Only import files from trusted sources.\n\n• Editing recipe files outside the app is not supported and may cause errors.\n\n• Sharing recipes with others is your responsibility. Be mindful of what you share.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.05))
                        .padding(.horizontal)
                )
            }
            .padding()
            .navigationTitle("Recipe Manager")
        }
        .onAppear {
            // Set up notification observer
            notificationObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name("ImportRecipe"),
                object: nil,
                queue: .main
            ) { notification in
                if let recipe = notification.object as? Recipe {
                    importedRecipe = recipe
                }
            }
        }
        .onDisappear {
            // Clean up observer
            if let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        .sheet(item: $selectedAction) { action in
            switch action {
            case .add:
                RecipeEditorView()
            case .edit:
                RecipeListView(
                    title: "Select Recipe to Edit",
                    recipes: recipeStore.userRecipes,
                    action: { recipe in
                        selectedAction = nil
                        recipeToEdit = recipe
                    },
                    deleteAction: deleteRecipe
                )
            case .export:
                RecipeListView(
                    title: "Select Recipe to Export",
                    recipes: recipeStore.userRecipes,
                    action: { recipe in
                        selectedAction = nil
                        prepareRecipeForSharing(recipe)
                    },
                    deleteAction: deleteRecipe
                )
            case .import:
                EmptyView()
            }
        }
        .onChange(of: selectedAction) { oldValue, newValue in
            if newValue == .import {
                isImporting = true
                selectedAction = nil
            }
        }
        .sheet(item: $recipeToEdit) { recipe in
            RecipeEditorView(recipe: recipe)
        }
        .sheet(item: $importedRecipe) { recipe in
            RecipeEditorView(recipe: recipe, isImporting: true)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let data = shareData, let recipe = recipeToShare {
                ShareSheet(recipe: recipe, data: data)
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json, .brewpadRecipe],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selectedFile = urls.first else { return }
                
                guard selectedFile.startAccessingSecurityScopedResource() else {
                    importError = "Cannot access the selected file."
                    showImportError = true
                    return
                }
                
                defer {
                    selectedFile.stopAccessingSecurityScopedResource()
                }
                
                do {
                    let data = try Data(contentsOf: selectedFile)
                    let decoder = JSONDecoder()
                    var recipe = try decoder.decode(Recipe.self, from: data)
                    
                    // Create new recipe while preserving the original creator
                    recipe = Recipe(
                        name: recipe.name,
                        category: recipe.category,
                        description: recipe.description,
                        ingredients: recipe.ingredients,
                        preparations: recipe.preparations,
                        isBuiltIn: false,
                        creator: recipe.creator  // Preserve the original creator
                    )
                    
                    importedRecipe = recipe
                    selectedAction = nil
                    appState.reinitialize(for: .recipeImported)
                } catch {
                    importError = "The selected file is not a valid recipe file."
                    showImportError = true
                }
                
            case .failure(let error):
                importError = error.localizedDescription
                showImportError = true
            }
        }
        .alert("Import Error", isPresented: $showImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importError ?? "An unknown error occurred")
        }
    }
    
    private func prepareRecipeForSharing(_ recipe: Recipe) {
        do {
            // Create a clean version of the recipe for sharing
            let shareableRecipe = Recipe(
                name: recipe.name,
                category: recipe.category,
                description: recipe.description,
                ingredients: recipe.ingredients,
                preparations: recipe.preparations,
                isBuiltIn: false,  // Always false for shared recipes
                creator: recipe.creator
            )
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(shareableRecipe)
            self.shareData = data
            self.recipeToShare = shareableRecipe
            self.showingShareSheet = true
        } catch {
            print("❌ Error preparing recipe for sharing: \(error.localizedDescription)")
        }
    }
    
    private func deleteRecipe(_ recipe: Recipe) {
        recipeStore.deleteRecipe(recipe)
        appState.reinitialize(for: .recipeDeleted)
    }
}

// Helper view for consistent button styling
struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .foregroundColor(.blue)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

// Helper view for displaying recipe lists
struct RecipeListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var recipeStore: RecipeStore
    @State private var showingDeleteConfirmation = false
    @State private var recipeToDelete: Recipe?
    
    let title: String
    let recipes: [Recipe]
    let action: (Recipe) -> Void
    let deleteAction: (Recipe) -> Void
    
    var body: some View {
        NavigationView {
            List(recipes) { recipe in
                Button(action: { action(recipe) }) {
                    VStack(alignment: .leading) {
                        Text(recipe.name)
                            .font(.headline)
                        Text(recipe.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .contextMenu {
                    Button(role: .destructive) {
                        recipeToDelete = recipe
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(title)
            .alert("Delete Recipe", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let recipe = recipeToDelete {
                        dismiss()  // Dismiss first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {  // Short delay
                            deleteAction(recipe)  // Then delete and show splash
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this recipe? This action cannot be undone.")
            }
        }
    }
}

// Add this to support JSON file type
extension UTType {
    static var json: UTType {
        UTType(importedAs: "public.json")
    }
}

// Document type for exporting
struct RecipeDocument: FileDocument {
    let recipe: Recipe?
    
    static var readableContentTypes: [UTType] { [.json] }
    
    init(recipe: Recipe?) {
        self.recipe = recipe
    }
    
    init(configuration: ReadConfiguration) throws {
        recipe = nil
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let recipe = recipe else {
            throw CocoaError(.fileWriteUnknown)
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(recipe)
        
        return .init(regularFileWithContents: data)
    }
} 
import Foundation

class NotesManager: ObservableObject {
    @Published private(set) var notes: [UUID: [RecipeNote]] = [:]
    private let fileManager = FileManager.default
    
    init() {
        loadNotes()
    }
    
    private var notesDirectory: URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let notesDirectory = documentsDirectory.appendingPathComponent("Notes", isDirectory: true)
        
        // Create notes directory if it doesn't exist
        if !fileManager.fileExists(atPath: notesDirectory.path) {
            try? fileManager.createDirectory(at: notesDirectory, withIntermediateDirectories: true)
        }
        
        return notesDirectory
    }
    
    private func loadNotes() {
        guard let notesDirectory = notesDirectory else { return }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: notesDirectory,
                                                             includingPropertiesForKeys: nil)

            for fileURL in fileURLs {
                guard fileURL.pathExtension == "json" else { continue }

                let data = try Data(contentsOf: fileURL)
                let note = try JSONDecoder().decode(RecipeNote.self, from: data)

                notes[note.recipeId, default: []].append(note)
            }

            // Sort notes for each recipe after collecting all of them
            for recipeId in notes.keys {
                notes[recipeId]?.sort { $0.dateCreated > $1.dateCreated }
            }
        } catch {
            print("Error loading notes: \(error)")
        }
    }
    
    func addNote(to recipeId: UUID, text: String) {
        let note = RecipeNote(recipeId: recipeId, text: text)
        notes[recipeId, default: []].append(note)
        notes[recipeId]?.sort { $0.dateCreated > $1.dateCreated }
        
        saveNote(note)
    }
    
    private func saveNote(_ note: RecipeNote) {
        guard let notesDirectory = notesDirectory else { return }
        
        do {
            let data = try JSONEncoder().encode(note)
            let fileURL = notesDirectory.appendingPathComponent("\(note.id).json")
            try data.write(to: fileURL)
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    func deleteNote(_ note: RecipeNote) {
        guard let notesDirectory = notesDirectory else { return }
        
        notes[note.recipeId]?.removeAll { $0.id == note.id }
        
        let fileURL = notesDirectory.appendingPathComponent("\(note.id).json")
        try? fileManager.removeItem(at: fileURL)
    }
    
    func getNotesForRecipe(_ recipeId: UUID) -> [RecipeNote] {
        return notes[recipeId] ?? []
    }
} 
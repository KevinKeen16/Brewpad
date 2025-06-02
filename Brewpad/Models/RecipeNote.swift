import Foundation

struct RecipeNote: Codable, Identifiable, Equatable {
    let id: UUID
    let recipeId: UUID
    let text: String
    let dateCreated: Date
    
    init(recipeId: UUID, text: String) {
        self.id = UUID()
        self.recipeId = recipeId
        self.text = text
        self.dateCreated = Date()
    }
    
    // Implement Equatable
    static func == (lhs: RecipeNote, rhs: RecipeNote) -> Bool {
        lhs.id == rhs.id &&
        lhs.recipeId == rhs.recipeId &&
        lhs.text == rhs.text &&
        lhs.dateCreated == rhs.dateCreated
    }
} 
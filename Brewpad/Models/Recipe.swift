struct Recipe: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: Category
    let description: String
    private let _ingredients: [String]
    private let _preparations: [String]
    let isBuiltIn: Bool
    let creator: String
    let isFeatured: Bool

    // Existing code...
} 
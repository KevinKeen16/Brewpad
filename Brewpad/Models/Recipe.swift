import Foundation

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

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case description
        case _ingredients = "ingredients"
        case _preparations = "preparations"
        case isBuiltIn
        case creator
        case isFeatured
    }

    enum Category: String, CaseIterable, Codable {
        case coffee = "Coffee"
        case tea = "Tea"
        case greenTea = "Green Tea"
        case milk = "Milk"
        case chocolate = "Chocolate"
        case alcohol = "Alcohol"
    }

    var ingredients: [String] { _ingredients }
    var preparations: [String] { _preparations }

    init(id: UUID = UUID(),
         name: String,
         category: Category,
         description: String,
         ingredients: [String],
         preparations: [String],
         isBuiltIn: Bool = false,
         creator: String,
         isFeatured: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self._ingredients = ingredients
        self._preparations = preparations
        self.isBuiltIn = isBuiltIn
        self.creator = creator
        self.isFeatured = isFeatured
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(Category.self, forKey: .category)
        description = try container.decode(String.self, forKey: .description)
        _ingredients = try container.decode([String].self, forKey: ._ingredients)
        _preparations = try container.decode([String].self, forKey: ._preparations)
        isBuiltIn = try container.decodeIfPresent(Bool.self, forKey: .isBuiltIn) ?? false
        creator = try container.decodeIfPresent(String.self, forKey: .creator) ?? "Unknown"
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(description, forKey: .description)
        try container.encode(_ingredients, forKey: ._ingredients)
        try container.encode(_preparations, forKey: ._preparations)
        try container.encode(isBuiltIn, forKey: .isBuiltIn)
        try container.encode(creator, forKey: .creator)
        try container.encode(isFeatured, forKey: .isFeatured)
    }
}

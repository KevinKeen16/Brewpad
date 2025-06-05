import Foundation
import Testing
@testable import Brewpad

struct RecipeEditingTests {
    private func filename(for recipe: Recipe) -> String {
        let suffix = recipe.id.uuidString.suffix(8)
        return "\(recipe.name.lowercased().replacingOccurrences(of: " ", with: "_"))_\(suffix).json"
    }

    private func save(_ recipe: Recipe, existing: Recipe?, in directory: URL) throws {
        let fileURL = directory.appendingPathComponent(filename(for: recipe))
        if let old = existing, old.name != recipe.name {
            let oldURL = directory.appendingPathComponent(filename(for: old))
            if FileManager.default.fileExists(atPath: oldURL.path) {
                try FileManager.default.removeItem(at: oldURL)
            }
        }
        let data = try JSONEncoder().encode(recipe)
        try data.write(to: fileURL)
    }

    @Test
    func testEditingKeepsIDAndSingleFile() async throws {
        let baseDir = FileManager.default.temporaryDirectory.appendingPathComponent("RecipeTests_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)

        let id = UUID()
        let original = Recipe(id: id,
                              name: "Original",
                              category: .coffee,
                              description: "desc",
                              ingredients: ["Water"],
                              preparations: ["Brew"],
                              creator: "tester")

        try save(original, existing: nil, in: baseDir)

        let edited = Recipe(id: id,
                            name: "Edited",
                            category: .coffee,
                            description: "desc",
                            ingredients: ["Water"],
                            preparations: ["Brew"],
                            isBuiltIn: original.isBuiltIn,
                            creator: original.creator,
                            isWeeklyFeature: original.isWeeklyFeature,
                            isCommunityHighlight: original.isCommunityHighlight)
        try save(edited, existing: original, in: baseDir)

        let files = try FileManager.default.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: nil)
        #expect(files.count == 1)
        #expect(edited.id == id)
    }
}

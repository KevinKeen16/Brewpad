import Testing
@testable import Brewpad

struct RecipeStoreBundledRecipesTests {
    @Test
    func testBundledRecipesPreserveIDAndFeatured() async throws {
        let store = RecipeStore()
        // Wait a moment for recipes to load
        // In tests we assume loading completes synchronously for bundled recipes
        let cappuccino = store.recipes.first { $0.name == "Cappuccino" }
        let earlGrey = store.recipes.first { $0.name == "Earl Grey Tea" }
        #expect(cappuccino?.creator == "Brewpad")
        #expect(cappuccino?.isBuiltIn == true)
        #expect(cappuccino?.id.uuidString == "1b4f8a2e-3d5c-4e6f-9a7b-8c2d1e0f3456")
        #expect(cappuccino?.isFeatured == false)

        #expect(earlGrey?.creator == "Brewpad")
        #expect(earlGrey?.isBuiltIn == true)
        #expect(earlGrey?.id.uuidString == "2c5b9b3f-4e6d-5f7a-8a9c-1d2e3f4a5678")
        #expect(earlGrey?.isFeatured == false)
    }
}

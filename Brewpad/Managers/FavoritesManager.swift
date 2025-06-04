import Foundation
import SwiftUI

class FavoritesManager: ObservableObject {
    @Published private(set) var favorites: Set<UUID> = []
    private let favoritesKey = "favoriteRecipes"

    init() {
        loadFavorites()
    }

    private func loadFavorites() {
        if let saved = UserDefaults.standard.array(forKey: favoritesKey) as? [String] {
            favorites = Set(saved.compactMap { UUID(uuidString: $0) })
        }
    }

    private func saveFavorites() {
        let values = favorites.map { $0.uuidString }
        UserDefaults.standard.set(values, forKey: favoritesKey)
    }

    func isFavorite(_ id: UUID) -> Bool {
        favorites.contains(id)
    }

    func toggleFavorite(_ id: UUID) {
        if favorites.contains(id) {
            favorites.remove(id)
        } else {
            favorites.insert(id)
        }
        saveFavorites()
    }

    func favorites(in recipes: [Recipe]) -> [Recipe] {
        recipes.filter { favorites.contains($0.id) }
    }
}

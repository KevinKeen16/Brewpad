import SwiftUI

struct TutorialCardsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var currentCardIndex = 0
    
    let cards: [TutorialCard]
    
    var body: some View {
        ZStack {
            settingsManager.colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Welcome Icon
                Image(systemName: "mug.fill")
                    .font(.system(size: 60))
                    .foregroundColor(settingsManager.colors.accent)

                // Tutorial Cards displayed horizontally
                TabView(selection: $currentCardIndex) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                        CardView(card: card)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Skip/Continue Button
                Button(currentCardIndex == cards.count - 1 ? "Get Started" : "Skip") {
                    finishTutorial()
                }
                .padding()
            }
            .padding()
        }
    }
    
    private func finishTutorial() {
        withAnimation {
            settingsManager.hasCompletedOnboarding = true
            settingsManager.isReplayingTutorial = false
        }
    }
}

struct CardView: View {
    let card: TutorialCard
    @EnvironmentObject private var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: card.icon)
                .font(.system(size: 50))
                .foregroundColor(settingsManager.colors.accent)
            
            VStack(spacing: 10) {
                Text(card.title)
                    .font(.title2)
                    .bold()
                
                Text(card.description)
                    .font(.body)
                    .foregroundColor(settingsManager.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(radius: 10)
        )
    }
}

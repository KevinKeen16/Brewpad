import SwiftUI

struct TutorialCardsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var currentCardIndex = 0
    @State private var offset = CGSize.zero
    @GestureState private var dragState = DragState.inactive
    
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
                
                // Tutorial Cards
                ZStack {
                    ForEach(cards.indices.reversed(), id: \.self) { index in
                        CardView(card: cards[index])
                            .offset(x: calculateOffset(for: index))
                            .scaleEffect(calculateScale(for: index))
                            .opacity(calculateOpacity(for: index))
                            .zIndex(Double(index))
                            .gesture(
                                DragGesture()
                                    .updating($dragState) { value, state, _ in
                                        if index == currentCardIndex {
                                            state = .dragging(translation: value.translation)
                                        }
                                    }
                                    .onEnded { value in
                                        if index == currentCardIndex {
                                            onDragEnded(drag: value)
                                        }
                                    }
                            )
                    }
                }
                .padding(.horizontal)
                
                // Skip/Continue Button
                Button(currentCardIndex == cards.count - 1 ? "Get Started" : "Skip") {
                    finishTutorial()
                }
                .padding()
            }
            .padding()
        }
    }
    
    private func calculateOffset(for index: Int) -> CGFloat {
        if index == currentCardIndex {
            return dragState.translation.width
        } else if index > currentCardIndex {
            return CGFloat(index - currentCardIndex) * 40 // Stack cards to the right
        }
        return -UIScreen.main.bounds.width // Move previous cards off screen to the left
    }
    
    private func calculateScale(for index: Int) -> CGFloat {
        let diff = index - currentCardIndex
        if diff < 0 {
            return 0.8 // Smaller scale for previous cards
        } else if diff == 0 {
            return 1.0 // Full size for current card
        }
        return 0.95 - CGFloat(diff) * 0.05 // Gradually smaller for stacked cards
    }
    
    private func calculateOpacity(for index: Int) -> Double {
        let diff = index - currentCardIndex
        if diff < 0 {
            return 0 // Hide previous cards
        } else if diff == 0 {
            return 1.0 // Full opacity for current card
        }
        return 1.0 - Double(diff) * 0.3 // Fade out stacked cards
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        let dragThreshold: CGFloat = 100
        if drag.translation.width > dragThreshold && currentCardIndex > 0 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentCardIndex -= 1
            }
        } else if drag.translation.width < -dragThreshold && currentCardIndex < cards.count - 1 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentCardIndex += 1
            }
        } else if currentCardIndex == cards.count - 1 && drag.translation.width < -dragThreshold {
            finishTutorial()
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

enum DragState {
    case inactive
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
} 
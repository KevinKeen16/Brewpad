import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var currentStep = 0
    @State private var username = ""
    @State private var dragState = DragState.inactive
    
    private let tutorialCards = [
        TutorialCard(
            title: "Browse Recipes",
            description: "Discover a curated collection of beverage recipes from classic coffee drinks to creative concoctions. Filter by category, save your favorites, and find the perfect drink for any moment.",
            icon: "book.fill"
        ),
        TutorialCard(
            title: "Save Favorites",
            description: "Found a recipe you love? Add it to your favorites for quick access. Rate your drinks, add personal notes, and build your own collection of go-to beverages.",
            icon: "star.fill"
        ),
        TutorialCard(
            title: "Create Custom Recipes",
            description: "Have a special recipe? Share it with the Brewpad community! Add detailed ingredients, precise measurements, and step-by-step instructions to help others recreate your masterpiece.",
            icon: "square.and.pencil"
        ),
        TutorialCard(
            title: "Convert Measurements",
            description: "No more conversion headaches! Switch seamlessly between metric and imperial units. Whether you prefer milliliters or ounces, Brewpad adapts to your preferred measurement system.",
            icon: "ruler"
        ),
        TutorialCard(
            title: "Growing Collection",
            description: "Brewpad is constantly evolving! Look forward to regular recipe additions, seasonal specials, and community favorites. Check back often to discover new drinks and brewing techniques.",
            icon: "sparkles"
        )
    ]
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            if settingsManager.isReplayingTutorial {
                // Show only tutorial cards
                TutorialCardsView(cards: tutorialCards)
            } else {
                // Show full onboarding with user setup first
                TabView(selection: $currentStep) {
                    // User Setup
                    UserSetupView(username: $username)
                        .tag(0)
                    
                    // Tutorial Cards
                    ForEach(Array(tutorialCards.enumerated()), id: \.element.id) { index, card in
                        TutorialCardView(card: card)
                            .tag(index + 1)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Navigation Buttons
                VStack {
                    Spacer()
                    
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(currentStep == tutorialCards.count ? "Get Started" : "Next") {
                            if currentStep == tutorialCards.count {
                                finishOnboarding()
                            } else {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                        .disabled(currentStep == 0 && username.isEmpty)
                    }
                    .padding()
                }
            }
        }
    }
    
    private func finishOnboarding() {
        withAnimation {
            settingsManager.username = username.isEmpty ? nil : username
            settingsManager.hasCompletedOnboarding = true
            settingsManager.isReplayingTutorial = false
        }
    }
}

struct UserSetupView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @Binding var username: String
    @FocusState private var isUsernameFocused: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "mug.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Welcome to Brewpad")
                .font(.title)
                .bold()
            
            VStack(spacing: 20) {
                Text("Your Personal Beverage Guide")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("Join our community of beverage enthusiasts and start your journey to creating perfect drinks.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What should we call you?")
                            .font(.headline)
                        
                        TextField("Enter your name", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                            .focused($isUsernameFocused)
                        
                        Text("Your name will be used to personalize your experience")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Age Verification
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age Verification")
                            .font(.headline)
                        
                        Toggle(isOn: $settingsManager.isOver18) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .foregroundColor(.blue)
                                Text("I am 18 or older")
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        Text("Required for accessing alcoholic beverage recipes. You can change this later in settings.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .onChange(of: username) { oldValue, newValue in
            if newValue.isEmpty {
                isUsernameFocused = true
            }
        }
    }
}

struct TutorialCardView: View {
    let card: TutorialCard
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: card.icon)
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            VStack(spacing: 10) {
                Text(card.title)
                    .font(.title2)
                    .bold()
                
                Text(card.description)
                    .font(.body)
                    .foregroundColor(.gray)
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
        .padding()
    }
} 
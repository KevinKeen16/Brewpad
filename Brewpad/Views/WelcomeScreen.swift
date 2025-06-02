import SwiftUI

struct WelcomeScreen: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var username = ""
    @State private var currentStep = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Welcome Icon
            Image(systemName: "mug.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            // Welcome Text
            Text("Welcome to Brewpad")
                .font(.title)
                .bold()
            
            // Step Content
            Group {
                switch currentStep {
                case 0:
                    // User Setup
                    VStack(spacing: 20) {
                        Text("Let's get you set up!")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What should we call you?")
                                    .font(.subheadline)
                                
                                TextField("Enter your name", text: $username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                            
                            // Age Verification
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $settingsManager.isOver18) {
                                    HStack {
                                        Image(systemName: "person.crop.circle.badge.checkmark")
                                            .foregroundColor(.blue)
                                        Text("I am 18 or older")
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                
                                Text("Required for accessing alcoholic beverage recipes")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                case 1:
                    // Features Introduction
                    VStack(spacing: 16) {
                        Text("With Brewpad, you can:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "book.fill", text: "Browse drink recipes")
                            FeatureRow(icon: "star.fill", text: "Save your favorites")
                            FeatureRow(icon: "square.and.pencil", text: "Create custom recipes")
                            FeatureRow(icon: "ruler", text: "Convert measurements")
                        }
                    }
                    
                default:
                    // Final Step
                    VStack(spacing: 16) {
                        Text("You're all set!")
                            .font(.headline)
                        
                        Text("Start exploring recipes and create your perfect brew.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                }
                
                Spacer()
                
                Button(currentStep == 2 ? "Get Started" : "Next") {
                    if currentStep == 2 {
                        settingsManager.username = username.isEmpty ? nil : username
                        settingsManager.hasCompletedOnboarding = true
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
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
        }
    }
} 
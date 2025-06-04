import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var recipeStore: RecipeStore
    @State private var isDownloading = false
    @State private var showDownloadComplete = false
    @State private var isEditingUsername = false
    @State private var newUsername = ""
    @State private var showingTutorialConfirmation = false
    @State private var debugTapCount = 0
    @State private var lastTapTime = Date()
    @State private var cupRotation = 0.0
    @State private var cupScale = 1.0
    @State private var showingDebugMenu = false
    
    private var cupColor: Color {
        if settingsManager.isDebugModeEnabled {
            return .gold // Active debug mode
        } else {
            switch debugTapCount {
            case 0:
                return .gray // Default state
            case 1:
                return .lightBlue // First tap
            case 2:
                return .blue // Second tap
            case 3:
                return .gold // Third tap (activation)
            default:
                return .gray
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // User Section
                VStack(spacing: 16) {
                    Text("User Settings")
                        .font(.title2)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                        
                        if isEditingUsername {
                            HStack {
                                TextField("Enter your name", text: $newUsername)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button("Save") {
                                    if !newUsername.isEmpty {
                                        settingsManager.username = newUsername
                                        isEditingUsername = false
                                    }
                                }
                                .disabled(newUsername.isEmpty)
                                
                                Button("Cancel") {
                                    isEditingUsername = false
                                    newUsername = settingsManager.username ?? ""
                                }
                            }
                        } else {
                            HStack {
                                Text(settingsManager.username ?? "Not set")
                                    .foregroundColor(settingsManager.username == nil ? .gray : .primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    newUsername = settingsManager.username ?? ""
                                    isEditingUsername = true
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(settingsManager.colors.accent)
                                }
                            }
                        }
                        
                        Text("Your display name in the app")
                            .font(.caption)
                            .foregroundColor(settingsManager.colors.textSecondary)
                    }
                    
                    Divider()
                    
                    // Birth Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Birthday")
                            .font(.headline)

                        DatePicker(
                            "Select your birth date",
                            selection: Binding<Date>(
                                get: {
                                    settingsManager.birthdate ?? Calendar.current.date(byAdding: .year, value: -18, to: Date())!
                                },
                                set: { settingsManager.birthdate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)

                        Text("Required for accessing alcoholic beverage recipes")
                            .font(.caption)
                            .foregroundColor(settingsManager.colors.textSecondary)
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(settingsManager.colors.divider.opacity(0.2)))
                
                // App Settings Section
                VStack(spacing: 16) {
                    Text("App Settings")
                        .font(.title2)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Theme Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App Theme")
                                .font(.headline)
                            
                            Picker("Select Theme", selection: $settingsManager.theme) {
                                ForEach(SettingsManager.Theme.allCases, id: \.self) { theme in
                                    Text(theme.rawValue).tag(theme)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            Text("Choose your preferred app appearance")
                                .font(.caption)
                                .foregroundColor(settingsManager.colors.textSecondary)
                        }
                        
                        Divider()
                        
                        // Measurement Units Toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Measurement Units")
                                .font(.headline)
                            
                            Toggle(isOn: $settingsManager.useMetricUnits) {
                                HStack {
                                    Image(systemName: "ruler")
                                        .foregroundColor(settingsManager.colors.accent)
                                    Text(settingsManager.useMetricUnits ? "Metric (ml, g)" : "Imperial (oz, cups)")
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: settingsManager.colors.accent))
                            
                            Text("Switch between metric and imperial units for recipe measurements")
                                .font(.caption)
                                .foregroundColor(settingsManager.colors.textSecondary)
                        }
                        
                        Divider()
                        
                        // Recipe Download Button
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recipe Updates")
                                .font(.headline)
                            
                            Button(action: downloadRecipes) {
                                HStack {
                                    if isDownloading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "arrow.down.circle")
                                    }
                                    Text(isDownloading ? "Downloading..." : "Check for New Recipes")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isDownloading ? Color.gray : settingsManager.colors.buttonBackground)
                                .cornerRadius(10)
                            }
                            .disabled(isDownloading)
                            
                            Text("Download new recipes from our collection")
                                .font(.caption)
                                .foregroundColor(settingsManager.colors.textSecondary)
                        }
                        
                        Divider()
                        
                        // Tutorial Replay Button
                        VStack(alignment: .leading, spacing: 8) {
                            Text("App Tutorial")
                                .font(.headline)
                            
                            Button(action: { showingTutorialConfirmation = true }) {
                                HStack {
                                    Image(systemName: "book.circle.fill")
                                    Text("Replay Tutorial")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(settingsManager.colors.buttonBackground)
                                .cornerRadius(10)
                            }
                            
                            Text("View the feature introduction cards again")
                                .font(.caption)
                                .foregroundColor(settingsManager.colors.textSecondary)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(settingsManager.colors.divider.opacity(0.2)))
                
                // Debug Section
                if settingsManager.isDebugModeEnabled {
                    VStack(spacing: 16) {
                        Text("Debug Settings")
                            .font(.title2)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // Holiday Override
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Holiday Override")
                                    .font(.headline)
                                
                                Picker("Select Holiday", selection: $settingsManager.debugHoliday) {
                                    ForEach(SettingsManager.Holiday.allCases, id: \.self) { holiday in
                                        Text(holiday.rawValue).tag(Optional(holiday))
                                    }
                                }
                                .pickerStyle(.menu)
                                
                                Text("Override the current date for testing holiday messages")
                                    .font(.caption)
                                    .foregroundColor(settingsManager.colors.textSecondary)
                            }
                            
                            Divider()
                            
                            // Full Onboarding Reset
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Onboarding")
                                    .font(.headline)
                                
                                Button(action: {
                                    withAnimation {
                                        // Reset all onboarding-related settings
                                        settingsManager.hasCompletedOnboarding = false
                                        settingsManager.username = nil
                                        settingsManager.birthdate = nil
                                        settingsManager.isReplayingTutorial = false // Ensure full onboarding
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise.circle.fill")
                                        Text("Reset Full Onboarding")
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(settingsManager.colors.buttonBackground)
                                    .cornerRadius(10)
                                }
                                
                                Text("Restart the complete onboarding process, including username and age verification")
                                    .font(.caption)
                                    .foregroundColor(settingsManager.colors.textSecondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    showingDebugMenu = true
                                } label: {
                                    HStack {
                                        Image(systemName: "list.bullet.rectangle.portrait")
                                        Text("Recipe Debug Info")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(settingsManager.colors.textSecondary)
                                    }
                                }

                                Text("View detailed recipe information")
                                    .font(.caption)
                                    .foregroundColor(settingsManager.colors.textSecondary)
                            }

                            // Server Response
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Server Response")
                                    .font(.headline)

                                if let response = recipeStore.serverResponse {
                                    Text(response)
                                        .font(.caption)
                                        .foregroundColor(settingsManager.colors.textSecondary)
                                } else {
                                    Text("No response yet")
                                        .font(.caption)
                                        .foregroundColor(settingsManager.colors.textSecondary)
                                }

                                if !recipeStore.serverFetchedRecipes.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Fetched Recipes:")
                                            .font(.subheadline)
                                        ForEach(recipeStore.serverFetchedRecipes, id: \.self) { recipe in
                                            Text(recipe)
                                                .font(.caption2)
                                                .foregroundColor(settingsManager.colors.textSecondary)
                                        }
                                    }
                                }

                                Button(action: { recipeStore.checkServerConnection() }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise.circle.fill")
                                        Text("Check Server Connection")
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(settingsManager.colors.buttonBackground)
                                    .cornerRadius(10)
                                }
                            }

                            Divider()
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(settingsManager.colors.divider.opacity(0.2)))
                }
                
                // Copyright Notice
                VStack(spacing: 4) {
                    Text("© \(Calendar.current.component(.year, from: Date()))")
                        .font(.footnote)
                        .foregroundColor(settingsManager.colors.textSecondary)
                    
                    Text("MirreRaven Coding And Design")
                        .font(.footnote)
                        .bold()
                        .foregroundColor(settingsManager.colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .padding()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "mug.fill")
                    .font(.title2)
                    .foregroundColor(cupColor)
                    .rotationEffect(.degrees(cupRotation))
                    .scaleEffect(cupScale)
                    .onTapGesture {
                        handleDebugTap()
                    }
            }
        }
        .alert("Download Complete", isPresented: $showDownloadComplete) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("New recipes have been added to your collection.")
        }
        .alert("Replay Tutorial", isPresented: $showingTutorialConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Replay") {
                withAnimation {
                    // Reset all onboarding-related settings
                    settingsManager.hasCompletedOnboarding = false
                    settingsManager.username = nil
                    settingsManager.birthdate = nil
                    settingsManager.isReplayingTutorial = false // Ensure full onboarding
                }
            }
        } message: {
            Text("This will restart the complete onboarding process, including username and age verification. Would you like to continue?")
        }
        .sheet(isPresented: $showingDebugMenu) {
            RecipeDebugView()
        }
    }
    
    private func downloadRecipes() {
        isDownloading = true
        
        // Simulate download with 3 second delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isDownloading = false
            showDownloadComplete = true
        }
    }
    
    private func handleDebugTap() {
        let now = Date()
        
        // If debug mode is active, deactivate it immediately on any tap
        if settingsManager.isDebugModeEnabled {
            withAnimation {
                settingsManager.isDebugModeEnabled = false
                debugTapCount = 0
            }
            
            // Still do the animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                cupRotation += 360
                cupScale = 0.8
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) {
                cupScale = 1.0
            }
            
            return
        }
        
        // Reset count if more than 2 seconds have passed
        if now.timeIntervalSince(lastTapTime) > 2.0 {
            debugTapCount = 0
        }
        
        // Animate the cup
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            cupRotation += 360
            cupScale = 0.8
        }
        
        // Reset scale
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) {
            cupScale = 1.0
        }
        
        debugTapCount += 1
        lastTapTime = now
        
        // Enable debug mode after 3 taps
        if debugTapCount == 3 {
            withAnimation {
                settingsManager.isDebugModeEnabled = true
            }
        }
    }
} 
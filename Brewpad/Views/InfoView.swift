import SwiftUI

struct InfoView: View {
    @EnvironmentObject private var settingsManager: SettingsManager

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Welcome Section
                VStack(spacing: 16) {
                    Image(systemName: "mug.fill")
                        .font(.system(size: 60))
                        .foregroundColor(settingsManager.colors.accent)
                    
                    Text("Welcome to Brewpad")
                        .font(.title)
                        .bold()
                    
                    VStack(spacing: 12) {
                        Text("Your Personal Beverage Recipe Collection")
                            .font(.headline)
                            .foregroundColor(settingsManager.colors.accent)
                        
                        Text("Brewpad is your go-to companion for crafting perfect drinks. Whether you're a professional barista or an enthusiastic home brewer, this app helps you discover, organize, and create a variety of beverages.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(settingsManager.colors.textSecondary)
                        
                        Text("Browse through our carefully curated collection of recipes across different categories - from coffee and tea to chocolate and specialty drinks. Each recipe includes detailed instructions, ingredients, and preparation steps to help you make the perfect drink every time.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(settingsManager.colors.textSecondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(settingsManager.colors.divider.opacity(0.2)))
                
                // Credits & Base Recipe Section
                VStack(spacing: 16) {
                    Text("Recipe Credits")
                        .font(.title2)
                        .bold()
                    
                    VStack(spacing: 12) {
                        Text("Base Espresso Recipe")
                            .font(.headline)
                            .foregroundColor(settingsManager.colors.accent)
                        
                        Text("All coffee-based recipes use the base espresso recipe from Artisti Coffee Roasters:")
                            .multilineTextAlignment(.center)
                            .foregroundColor(settingsManager.colors.textSecondary)
                            .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(MeasurementConverter.convert(
                                "• 22.5g ground coffee (21g basket)",
                                toImperial: !settingsManager.useMetricUnits
                            ))
                            Text("• Prep puck as usual")
                            Text(MeasurementConverter.convert(
                                "• Extract 45g espresso (double shot)",
                                toImperial: !settingsManager.useMetricUnits
                            ))
                        }
                        .font(.subheadline)
                        .foregroundColor(settingsManager.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 8) {
                            Link(destination: URL(string: "https://www.youtube.com/watch?v=8IZCoCk224Q")!) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                    Text("Watch Their Espresso Tutorial")
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(settingsManager.colors.accent.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .foregroundColor(settingsManager.colors.accent)
                            .frame(maxWidth: .infinity)
                            
                            Link(destination: URL(string: "https://www.youtube.com/@ArtistiCoffeeRoasters")!) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                    Text("Visit Their YouTube Channel")
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(settingsManager.colors.accent.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .foregroundColor(settingsManager.colors.accent)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(settingsManager.colors.divider.opacity(0.2)))
            }
            .padding()
        }
    }
} 
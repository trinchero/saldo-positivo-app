import SwiftUI

// Add Identifiable conformance to SpendingInsight from AnalyticsViewModel
extension SpendingInsight: Identifiable {
    public var id: String { title }
}

/// A component that displays key spending statistics
struct KeyStatisticsView: View {
    let biggestExpenseCategory: (category: Category, amount: Double)?
    let totalSpent: Double
    let mostActiveSpendingPeriod: String?
    let currencyCode: String
    
    init(
        biggestExpenseCategory: (category: Category, amount: Double)?,
        totalSpent: Double,
        mostActiveSpendingPeriod: String?,
        currencyCode: String? = nil
    ) {
        self.biggestExpenseCategory = biggestExpenseCategory
        self.totalSpent = totalSpent
        self.mostActiveSpendingPeriod = mostActiveSpendingPeriod
        self.currencyCode = currencyCode ?? SettingsViewModel.getAppCurrency()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Statistics")
                .font(.headline)
            
            // Biggest expense category
            if let (category, amount) = biggestExpenseCategory {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top Spending Category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 10, height: 10)
                            
                            Text(category.displayName)
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if totalSpent > 0 {
                        Text(String(format: NSLocalizedString("%d%% of total", comment: "Percent of total"), Int((amount / totalSpent) * 100)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        Text(amount, format: .currency(code: currencyCode))
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            
            // Most active spending period
            if let period = mostActiveSpendingPeriod {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Most Active Days")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(period)
                            .font(.system(size: 18, weight: .bold))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }
}

/// A component that displays a collection of spending insights
struct InsightsCardView: View {
    let insights: [SpendingInsight]
    var onViewExpenses: ((Category?) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Insights")
                .font(.headline)
            
            if insights.isEmpty {
                Text("No insights available yet")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
            } else {
                ForEach(insights) { insight in
                    insightCard(insight: insight)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: insights.count)
    }
    
    private func insightCard(insight: SpendingInsight) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: insight.icon)
                    .font(.system(size: 26))
                    .foregroundColor(insight.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                    
                    Text(insight.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(badgeText(for: insight.type))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor(for: insight.type).opacity(0.18))
                    .foregroundColor(badgeColor(for: insight.type))
                    .clipShape(Capsule())
            }
            
            if let onViewExpenses, let category = insight.category {
                Button(action: { onViewExpenses(category) }) {
                    HStack(spacing: 6) {
                        Text(String(format: NSLocalizedString("View %@", comment: "View category CTA"), category.displayName))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(PressableButtonStyle(scale: 0.98, opacity: 0.95))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func badgeText(for type: SpendingInsight.InsightType) -> String {
        switch type {
        case .positive:
            return NSLocalizedString("On track", comment: "Positive insight badge")
        case .neutral:
            return NSLocalizedString("Heads up", comment: "Neutral insight badge")
        case .negative:
            return NSLocalizedString("Watch this", comment: "Negative insight badge")
        }
    }

    private func badgeColor(for type: SpendingInsight.InsightType) -> Color {
        switch type {
        case .positive:
            return .green
        case .neutral:
            return .orange
        case .negative:
            return .red
        }
    }
}

/// A component that displays spending pattern analysis
struct SpendingPatternView: View {
    struct PatternAnalysis {
        let title: String
        let description: String
        let icon: String
        let color: Color
    }
    
    let weekdayVsWeekendAnalysis: PatternAnalysis?
    let monthlyPatternAnalysis: PatternAnalysis?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Patterns")
                .font(.headline)
            
            if weekdayVsWeekendAnalysis == nil && monthlyPatternAnalysis == nil {
                Text("Not enough data")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Analyze weekdays vs weekends
                if let analysis = weekdayVsWeekendAnalysis {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekday vs Weekend")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(analysis.title)
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text(analysis.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: analysis.icon)
                            .font(.system(size: 24))
                            .foregroundColor(analysis.color)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
                
                // Analyze beginning vs end of month
                if let analysis = monthlyPatternAnalysis {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Monthly Pattern")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(analysis.title)
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text(analysis.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: analysis.icon)
                            .font(.system(size: 24))
                            .foregroundColor(analysis.color)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // Key Statistics preview
        KeyStatisticsView(
            biggestExpenseCategory: (Category.food, 450.50),
            totalSpent: 1850.25,
            mostActiveSpendingPeriod: "Wednesday"
        )
        
        // Insights preview
        InsightsCardView(insights: [
            SpendingInsight(
                type: .positive,
                title: "Weekend Spending Trend",
                description: "You tend to spend 45% more on weekends compared to weekdays",
                icon: "calendar.badge.exclamationmark",
                color: .orange,
                category: nil
            ),
            SpendingInsight(
                type: .negative,
                title: "Food Spending Increasing",
                description: "Your food spending has increased by 20% compared to last month",
                icon: "fork.knife",
                color: .red,
                category: .food
            )
        ])
        
        // Patterns preview
        SpendingPatternView(
            weekdayVsWeekendAnalysis: SpendingPatternView.PatternAnalysis(
                title: "Weekend Spender",
                description: "You spend 145% more on weekends compared to weekdays",
                icon: "party.popper",
                color: .orange
            ),
            monthlyPatternAnalysis: SpendingPatternView.PatternAnalysis(
                title: "End of Month Spender",
                description: "Your spending increases toward the end of the month",
                icon: "calendar.badge.exclamationmark",
                color: .red
            )
        )
    }
    .padding()
} 

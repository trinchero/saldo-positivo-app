import SwiftUI

struct InlineMonthYearPicker: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    var allowFutureMonths: Bool = false
    var monthsToShow: Int? = nil
    var onMonthYearChanged: (() -> Void)? = nil

    private var monthName: String {
        Calendar.current.monthSymbols[max(0, min(11, selectedMonth - 1))]
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: { moveMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
            }
            .disabled(!canMove(-1))
            .opacity(canMove(-1) ? 1 : 0.35)

            VStack(spacing: 0) {
                Text(monthName)
                    .font(.subheadline.weight(.semibold))
                Text(String(selectedYear))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: { moveMonth(1) }) {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
            }
            .disabled(!canMove(1))
            .opacity(canMove(1) ? 1 : 0.35)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
    }

    private func canMove(_ delta: Int) -> Bool {
        guard let candidate = shiftedDate(by: delta) else { return false }
        if allowFutureMonths {
            return withinHistoryLimit(candidate)
        }
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        let candidateMonth = calendar.component(.month, from: candidate)
        let candidateYear = calendar.component(.year, from: candidate)

        let notFuture = candidateYear < currentYear || (candidateYear == currentYear && candidateMonth <= currentMonth)
        return notFuture && withinHistoryLimit(candidate)
    }

    private func moveMonth(_ delta: Int) {
        guard let candidate = shiftedDate(by: delta) else { return }
        guard canMove(delta) else {
            HapticFeedback.error()
            return
        }
        let calendar = Calendar.current
        selectedMonth = calendar.component(.month, from: candidate)
        selectedYear = calendar.component(.year, from: candidate)
        onMonthYearChanged?()
    }

    private func shiftedDate(by delta: Int) -> Date? {
        let calendar = Calendar.current
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: 1)
        guard let current = calendar.date(from: components) else { return nil }
        return calendar.date(byAdding: .month, value: delta, to: current)
    }

    private func withinHistoryLimit(_ candidate: Date) -> Bool {
        guard let monthsToShow, monthsToShow > 0 else { return true }
        let calendar = Calendar.current
        guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())),
              let earliest = calendar.date(byAdding: .month, value: -(monthsToShow - 1), to: startOfCurrentMonth) else {
            return true
        }
        return candidate >= earliest
    }
}

#Preview {
    InlineMonthYearPicker(selectedMonth: .constant(2), selectedYear: .constant(2026))
        .padding()
}

import Foundation

func currentCurrencyCode() -> String {
    Locale.current.currency?.identifier ?? "USD"
}

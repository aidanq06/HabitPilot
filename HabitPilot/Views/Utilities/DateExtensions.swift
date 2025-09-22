import Foundation

extension Date {
    func fileNameString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: self)
    }
} 
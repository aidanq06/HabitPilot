import SwiftUI

struct ErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()

    @Published var currentError: ErrorAlert?
    @Published var showError = false

    private init() {}

    func handle(_ error: Error, title: String = "Error") {
        DispatchQueue.main.async { [weak self] in
            self?.currentError = ErrorAlert(
                title: title,
                message: error.localizedDescription
            )
            self?.showError = true
        }
    }

    func showSuccess(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.currentError = ErrorAlert(
                title: "Success",
                message: message
            )
            self?.showError = true
        }
    }

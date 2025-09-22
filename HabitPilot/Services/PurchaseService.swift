import Foundation
import StoreKit

@MainActor
class PurchaseService: ObservableObject {
    static let shared = PurchaseService()
    
    @Published var isUnlimitedPurchased = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var promoCodeMessage: String?

    
    private let monthlyProductID = "com.habitpilot.pro.monthly"
    private let yearlyProductID = "com.habitpilot.pro.yearly"
    private let lifetimeProductID = "com.habitpilot.pro.lifetime"
    private let userDefaults = UserDefaults.standard
    private let unlimitedKey = "UnlimitedHabitsPurchased"
    private let promoCodeKey = "PromoCodeRedeemed"
    
    private init() {
        loadPurchaseStatus()
    }
    
    var products: [Product] = []
    var monthlyProduct: Product? {
        products.first(where: { $0.id == monthlyProductID })
    }
    var yearlyProduct: Product? {
        products.first(where: { $0.id == yearlyProductID })
    }
    var lifetimeProduct: Product? {
        products.first(where: { $0.id == lifetimeProductID })
    }
    
    func loadProducts() async {
        do {
            let productIdentifiers = Set([monthlyProductID, yearlyProductID, lifetimeProductID])
            products = try await Product.products(for: productIdentifiers)
        } catch {
            #if DEBUG
            #endif
        }
    }
    
    func purchaseMonthly() async {
        guard let product = monthlyProduct else {
            errorMessage = "Monthly subscription not available"
            return
        }
        
        await purchaseProduct(product)
    }
    
    func purchaseLifetime() async {
        guard let product = lifetimeProduct else {
            errorMessage = "Lifetime purchase not available"
            return
        }
        
        await purchaseProduct(product)
    }
    
    func purchaseYearly() async {
        guard let product = yearlyProduct else {
            errorMessage = "Yearly subscription not available"
            return
        }
        
        await purchaseProduct(product)
    }
    

    
    private func purchaseProduct(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the purchase
                switch verification {
                case .verified(let transaction):
                    // Purchase is verified
                    await transaction.finish()
                    isUnlimitedPurchased = true
                    savePurchaseStatus()
                case .unverified:
                    errorMessage = "Purchase verification failed"
                }
            case .userCancelled:
                errorMessage = "Purchase cancelled"
            case .pending:
                errorMessage = "Purchase is pending"
            @unknown default:
                errorMessage = "Unknown purchase result"
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            // Check if any pro product was previously purchased
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == monthlyProductID || transaction.productID == lifetimeProductID {
                        isUnlimitedPurchased = true
                        savePurchaseStatus()
                        break
                    }
                }
            }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Promo Code System
    
    func redeemPromoCode(_ code: String) {
        let normalizedCode = code.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch normalizedCode {
        case "quack":
            if !userDefaults.bool(forKey: promoCodeKey) {
                isUnlimitedPurchased = true
                savePurchaseStatus()
                userDefaults.set(true, forKey: promoCodeKey)
                promoCodeMessage = "🎉 Promo code redeemed! You now have access to all premium features!"
            } else {
                promoCodeMessage = "This promo code has already been redeemed."
            }
        default:
            promoCodeMessage = "Invalid promo code. Please try again."
        }
        
        // Clear the message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.promoCodeMessage = nil
        }
    }
    
    private func loadPurchaseStatus() {
        isUnlimitedPurchased = userDefaults.bool(forKey: unlimitedKey) || userDefaults.bool(forKey: promoCodeKey)
    }
    
    private func savePurchaseStatus() {
        userDefaults.set(isUnlimitedPurchased, forKey: unlimitedKey)
    }
} 
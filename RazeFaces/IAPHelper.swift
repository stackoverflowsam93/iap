/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
  static let IAPHelperPurchaseNotification = Notification.Name("IAPHelperPurchaseNotification")
}

open class IAPHelper: NSObject  {
  
  private let productIdentifiers: Set<ProductIdentifier>
  private var purchasedProductIdentifiers: Set<ProductIdentifier> = []  //Tracks which items have been purchased
  private var productsRequest: SKProductsRequest?   //Used by SKProductsRequest to perform requests to Apple
  private var productsRequestCompletionHandler: ProductsRequestCompletionHandler? //Used by SKProductsRequest to perform requests to Apple
  private var products = [SKProduct]()
  var request: SKProductsRequest!
  
  public init(productIds: Set<ProductIdentifier>) {
      productIdentifiers = productIds
      for productIdentifier in productIds {
        //For each product identifier you check whether it's stored in UserDefaults
        let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
        if purchased {
          //If it is you insert that identifier into the purchasedProductIdentifiers set
          purchasedProductIdentifiers.insert(productIdentifier)
          print("Previously purchased: \(productIdentifier)")
        } else {
          print("Not purchased: \(productIdentifier)")
        }
      }
      super.init()
      SKPaymentQueue.default().add(self)
    let productIdentifiers = Set(Premium.store.productIdentifiers)

      request = SKProductsRequest(productIdentifiers: productIdentifiers)
      request.delegate = self
      request.start()
  }
}

// MARK: - StoreKit API

extension IAPHelper: SKProductsRequestDelegate {

  //Called when list is successfully retrieved
  //Receives an array of SKProduct objects and passes them to previously saved completion handler
  //Handler reloads table with new data
  //request(_:didFailWithError:) is called if a problem occurs
  //when the request finishes, both the request and completion handler are cleared with clearRequestAndHandler()
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
      print("Loaded list of products...")
      self.products = response.products
      productsRequestCompletionHandler?(true, products)
      clearRequestAndHandler()
      print(products)
      for p in products {
        print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
      }
  }
  
    public func request(_ request: SKRequest, didFailWithError error: Error) {
      print("Failed to load list of products.")
      print("Error: \(error.localizedDescription)")
      productsRequestCompletionHandler?(false, nil)
      clearRequestAndHandler()
    }

    private func clearRequestAndHandler() {
      productsRequest = nil
      productsRequestCompletionHandler = nil
    }
  
  

  /**
   
   */
  public func requestProducts(completionHandler: @escaping ProductsRequestCompletionHandler) {
    productsRequest?.cancel()
    productsRequestCompletionHandler = completionHandler  //save user's completion handler for future execution

    productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers) //Create and initialize a request to apple
    productsRequest!.delegate = self
    productsRequest!.start()
  }


  public func buyProduct(_ product: SKProduct) {
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }
  


  //Checks locally if product is purchased, to avoid making requests to apples servers every time
  public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
    return purchasedProductIdentifiers.contains(productIdentifier)
  }
  
  public class func canMakePayments() -> Bool {
    return SKPaymentQueue.canMakePayments()
  }
  
  public func restorePurchases() {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
}


extension IAPHelper: SKPaymentTransactionObserver {
 
  /**
   Delegate method
   Gets Called when one or more transaction states change
   Evaluates the state of each transaction in an array of updated transactions
   Calls the relevant helper method (complete(transaction)), restore(transaction), or fail(transaction))
   */
  public func paymentQueue(_ queue: SKPaymentQueue,
                           updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        complete(transaction: transaction)
        break
      case .failed:
        fail(transaction: transaction)
        break
      case .restored:
        restore(transaction: transaction)
        break
      case .deferred:
        break
      case .purchasing:
        break
      }
    }
  }
 
  /**
   Adds to the set of purchases and saves the identifier in UserDefaults
   Also posts a notification with that transaction so any interested object in the app can listen for it to do things like update the user interface
   */
  private func complete(transaction: SKPaymentTransaction) {
    print("complete...")
    deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  /**
   Adds to the set of purchases and saves the identifier in UserDefaults
   Also posts a notification with that transaction so any interested object in the app can listen for it to do things like update the user interface
   */
  private func restore(transaction: SKPaymentTransaction) {
    guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
 
    print("restore... \(productIdentifier)")
    deliverPurchaseNotificationFor(identifier: productIdentifier)
    SKPaymentQueue.default().finishTransaction(transaction)
  }
 
  
  private func fail(transaction: SKPaymentTransaction) {
    print("fail...")
    if let transactionError = transaction.error as NSError?,
      let localizedDescription = transaction.error?.localizedDescription,
        transactionError.code != SKError.paymentCancelled.rawValue {
        print("Transaction Error: \(localizedDescription)")
      }

    SKPaymentQueue.default().finishTransaction(transaction)
  }
 
  private func deliverPurchaseNotificationFor(identifier: String?) {
    guard let identifier = identifier else { return }
 
    purchasedProductIdentifiers.insert(identifier)
    UserDefaults.standard.set(true, forKey: identifier)
    NotificationCenter.default.post(name: .IAPHelperPurchaseNotification, object: identifier)
  }
}

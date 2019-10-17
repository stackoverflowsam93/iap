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

import UIKit
import StoreKit

class MasterViewController: UIViewController {
  
  let productIdentifier = String(1196426)
  
  var products: [SKProduct] = []
  @IBOutlet weak var premiumLabel: UIButton!
  
  //Checks if we have the product and moves to the next picture if we do
  func shouldShowPremium() -> Bool {
      return Premium.store.isProductPurchased(self.productIdentifier)
   }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "RazeFaces"
        
    NotificationCenter.default.addObserver(self, selector: #selector(MasterViewController.handlePurchaseNotification(_:)),
                                           name: .IAPHelperPurchaseNotification,
                                           object: nil)
    if Premium.store.isProductPurchased(self.productIdentifier) {
      self.premiumVersion()
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
  @objc func restoreTapped(_ sender: AnyObject) {
    Premium.store.restorePurchases()
  }

  @objc func handlePurchaseNotification(_ notification: Notification) {

    self.premiumVersion()
    
  }
  
  func premiumVersion(){
        premiumLabel.removeFromSuperview()
  }
  
  @IBAction func buttonPressed(_ sender: UIButton) {
    sender.titleLabel?.text = "Button pressed"
  }
  
  
  @IBAction func buyPremium(_ sender: UIButton) {

    if Premium.store.isProductPurchased(self.productIdentifier){
      Premium.store.restorePurchases()
    //}else if IAPHelper.canMakePayments(){
    //  Premium.store.buyProduct(Premium.store.)
    }else{
      let alert = UIAlertController(title: "Not authorized to make payments", message: "You can not make purchases on this device", preferredStyle: .alert)
      let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
      alert.addAction(ok)
      self.present(alert, animated: true, completion: nil)
    }
  }
  
}

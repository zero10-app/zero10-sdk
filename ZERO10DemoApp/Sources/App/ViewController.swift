import UIKit
import ZERO10SDK

class ViewController: UIViewController {
    
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    private let session = ZERO10Session()

    override func viewDidLoad() {
        super.viewDidLoad()

        actionButton.addTarget(self, action: #selector(reload), for: .touchUpInside)
        prepare()
    }
    
    private func prepare() {
        indicatorView.startAnimating()
        titleLabel.text = "Preparing for Try On"
        actionButton.isHidden = true
        
        session.prepareForTryOn { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                self.downloadCollections()
            case .failure(let error):
                self.handle(error: error)
            }
        }
    }
    
    private func downloadCollections() {
        indicatorView.startAnimating()
        titleLabel.text = "Downloading collections"
        
        session.downloadCollections { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                self.presentTryOnSheet()
            case .failure(let error):
                self.handle(error: error)
            }
        }
    }
    
    private func presentTryOnSheet() {
        indicatorView.stopAnimating()
        titleLabel.text = "Press “Try on” to\nreopen the selector"
        actionButton.setTitle("Try On", for: .normal)
        actionButton.isHidden = false
        
        session.startTryOn(presentingController: self)
    }
    
    private func handle(error: Error) {
        indicatorView.stopAnimating()
        titleLabel.text = "Try On failed: \(error)"
        actionButton.setTitle("Reload", for: .normal)
        actionButton.isHidden = false
        
        switch error {
        case TryOnSessionError.validatingFailed:
            let alertController = UIAlertController(
                title: "SDK validation failed",
                message: "Invalid API Key. Please verify your API key is valid.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
            
            present(alertController, animated: true)
        default:
            break
        }
    }
    
    @objc
    private func reload() {
        if session.canStartTryOn {
            presentTryOnSheet()
        } else {
            prepare()
        }
    }
    
    @objc
    private func reopen() {
        session.startTryOn(presentingController: self)
    }
}

import ZERO10SDK
import UIKit

class ZERO10Session {
    enum SessionError: Error {
        case collectionListIsEmpty
    }
    
    var canStartTryOn: Bool {
        isPrepared && !garmentCollections.isEmpty
    }
    
    private let tryOnSession: TryOnSession = {
        let config = TryOnSessionConfiguration(apiKey: "aHVLtEbC.3YLAbCyf89H8nO2Q0RrszvF5tUWM1UfD")
        let session = TryOnSession(with: config)
        return session
    }()
    private let bottomSheetPresenter = BottomSheetPresenter()
    private var garmentCollections = [GarmentCollection]()
    private var isPrepared = false
    private weak var presentingController: UIViewController?

    func prepareForTryOn(completion: @escaping (Result<Void, Error>) -> Void) {
        isPrepared = false
        tryOnSession.prepare { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                switch result {
                case .success:
                    self.isPrepared = true
                    completion(.success(()))
                case .failure(let error):
                    self.isPrepared = false
                    completion(.failure(error))
                }
            }
        }
    }

    func downloadCollections(completion: @escaping (Result<Void, Error>) -> Void) {
        tryOnSession.receiveCollections { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                switch result {
                case .success(let collections) where !collections.isEmpty:
                    self.garmentCollections = collections
                    completion(.success(()))
                case .success:
                    self.garmentCollections = []
                    completion(.failure(SessionError.collectionListIsEmpty))
                case .failure(let error):
                    self.garmentCollections = []
                    completion(.failure(error))
                }
            }
        }
    }

    func startTryOn(presentingController: UIViewController) {
        guard canStartTryOn else {
            return
        }
        let garments = garmentCollections
            .flatMap(\.items)
            .enumerated()
            .map { index, garment in
                DisplaybleGarment(isAvailable: true, wrappedGarment: garment, index: index)
            }
        let tryOnData = CameraTryOnData(garments: garments, selectedIndex: 0)
        let viewController = TryOnSheetViewController.makeTryOnSheetViewController(tryOnData: tryOnData)
        viewController.delegate = self
        self.presentingController = presentingController
        bottomSheetPresenter.present(viewController, from: presentingController, background: .translucent, backgroundCornerRadius: 24)
    }
}

extension ZERO10Session: TryOnSheetViewControllerDelegate {
    public func tryOnSheetViewController(didSelectCamera controller: ZERO10SDK.TryOnSheetViewController) {
        let cameraController = CameraViewController(tryOnData: controller.tryOnData)
        let avController = AVFoundationViewController.makeTryOnViewController(tryOnSession: tryOnSession, overlay: cameraController)
        cameraController.delegate = avController

        if let avController = avController {
            avController.contentRecordingDelegate = cameraController

            presentingController?.dismiss(animated: true) {
                self.presentingController?.navigationController?.pushViewController(avController, animated: true)
            }
        }
    }

    public func tryOnSheetViewController(didSelectPhoto photo: UIImage, controller: ZERO10SDK.TryOnSheetViewController) {
        let share = PhotoTryOnViewController.makePhotoTryOnViewController(
            tryOnSession: tryOnSession,
            content: .photo(photo, controller.tryOnData.garment.model),
            tryOnData: controller.tryOnData,
            garmentNavigationDelegate: self
        )

        let container = ShareContainerViewController.makeShareContainerViewController(contentViewController: share)

        presentingController?.dismiss(animated: true) {
            self.presentingController?.navigationController?.pushViewController(container, animated: true)
        }
    }
}

extension ZERO10Session: PaidGarmentDelegate {
    func showPaidGarment(_ garment: ZERO10SDK.DisplaybleGarment) {}
}

import UIKit
import ZERO10SDK

/// Camera overlay
///
/// Use CameraUI protocol to show an app specific UI
class CameraViewController: UIViewController, CameraUI {
    weak var delegate: CameraUIDelegate? {
        didSet {
            self.delegate?.newGarmentSelected(self.tryOnData.garment, swiped: false)
        }
    }

    private let tryOnData: CameraTryOnData
    private let garmentNodeProvider: GarmentNodeProviding

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system, primaryAction: UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        button.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        button.tintColor = .white
        
        return button
    }()
    
    private lazy var recordingButton: RecordingButton = {
        let button = RecordingButton()

        button.onTouchDown = { [weak self] in
            self?.startARRecording()
        }
        button.addTarget(self, action: #selector(self.stopARRecording), for: .touchUpInside)
        button.addTarget(self, action: #selector(self.longARRecording), for: .touchUpOutside)
        button.addTarget(self, action: #selector(self.stopARRecording), for: .touchCancel)

        return button
    }()
    private lazy var garmentsListView = CameraItemsSelectionView.makeItemsSelectionView(
        tryOnData: self.tryOnData, delegate: self
    )

    init(tryOnData: CameraTryOnData) {
        self.tryOnData = tryOnData
        self.garmentNodeProvider = GarmentNodeProvider.makeGarmentNodeProvider()

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()

        view.addSubview(self.backButton)
        view.addSubview(self.garmentsListView)
        view.addSubview(self.recordingButton)
        
        self.backButton.translatesAutoresizingMaskIntoConstraints = false
        self.backButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20.0).isActive = true
        self.backButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20.0).isActive = true

        self.recordingButton.translatesAutoresizingMaskIntoConstraints = false
        self.recordingButton.widthAnchor.constraint(equalToConstant: 90.0).isActive = true
        self.recordingButton.heightAnchor.constraint(equalToConstant: 90.0).isActive = true
        self.recordingButton.bottomAnchor.constraint(
            equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
            constant: -20.0
        ).isActive = true
        self.recordingButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true

        self.garmentsListView.translatesAutoresizingMaskIntoConstraints = false
        self.garmentsListView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20.0).isActive = true
        self.garmentsListView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadClothNode(for: self.tryOnData.garment.model)
    }

    private func loadClothNode(for garment: Garment) {
        self.garmentNodeProvider.getNode(for: garment) { [weak self] progress in
            self?.garmentsListView.setLoadingProgress(progress, for: garment)
        } completion: { [weak self] result in
            guard let self = self else { return }

            self.garmentsListView.setLoadingProgress(1, for: garment)

            switch result {
            case .success(let clothNode):
                self.delegate?.setClothNode(clothNode)
            case .failure:
                break
            }
        }
    }

    @objc
    private func longARRecording() {
        let success = self.delegate?.longARRecording() ?? false

        if !success {
            self.stopARRecording()
        }
    }

    @objc
    private func startARRecording() {
        guard self.delegate?.startARRecording() == true else { return }

        self.recordingButton.recordingState = .recording
    }

    @objc
    private func stopARRecording() {
        self.recordingButton.recordingState = .loading


        self.delegate?.stopARRecording { [weak self] in
            self?.recordingButton.recordingState = .idle
        }
    }

    func showAccessDeniedError() {
        let alert = UIAlertController(title: "Access Denied", message: "We need to access your camera to provide AR experience to you. Please update app settings.", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(dismissAction)
        present(alert, animated: true)
    }

    func showOverheatingError(override: @escaping () -> Void) {}

    func showBodyTrackingMessage() {}

    func hideBodyTrackingMessage(animated: Bool) {}

    func hideBodyTrackingMessage(animated: Bool, force: Bool) {}

    func showDistanceMessage(tooFar: Bool) {}

    func hideDistanceMessage() {}

    func hideBuyItemPopup() {}

    func showBuyItemPopup(for garment: DisplaybleGarment, action: UIAction) {}

    func updatePerformanceLog(_ log: PerformanceLogger.Log) {}

    func subjectAreaDidChange() -> Bool {
        true
    }

    func updateSkeletonProjections(_ projections: SkeletonJointsProjections<SIMD2<Float>>) {
    }

    func updateCameraFrame(_ frame: CGRect) {}

    func hideSkeleton() {}

    func trackingDidStart() {}
}

extension CameraViewController: ContentRecordingDelegate {
    func showPreview(for result: ZERO10SDK.ContentRecordingResult, garment: ZERO10SDK.Garment?, shouldSave: Bool) {
        switch result {
        case let .video(url: url, preview: preview):
            showVideoPreview(for: url, firstFrame: preview, garment: garment)
        case let .photo(rendered: rendered, original: _):
            showPhotoPreview(for: rendered, garment: garment)
        @unknown default:
            break
        }
    }

    func showVideoPreview(for video: URL, firstFrame: UIImage?, garment: ZERO10SDK.Garment?) {
        let share = ShareContentViewController(content: ShareContentModel.video(video, garment), preview: firstFrame)
        let container = ShareContainerViewController.makeShareContainerViewController(contentViewController: share)

        self.navigationController?.pushViewController(container, animated: true)
    }

    func showPhotoPreview(for photo: UIImage, garment: ZERO10SDK.Garment?) {
        let share = ShareContentViewController(content: ShareContentModel.photo(photo, garment), preview: nil)
        let container = ShareContainerViewController.makeShareContainerViewController(contentViewController: share)

        self.navigationController?.pushViewController(container, animated: true)
    }
}

extension CameraViewController: CameraItemsSelectionViewDelegate {
    func cameraItemsSelectionView(
        _ view: ZERO10SDK.CameraItemsSelectionView,
        didDidSelectGarment garment: ZERO10SDK.DisplaybleGarment,
        swiped: Bool
    ) {
        self.delegate?.removeClothNode()
        self.delegate?.newGarmentSelected(garment, swiped: swiped)
        self.loadClothNode(for: garment.model)
    }
}

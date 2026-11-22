import SwiftUI
import UIKit

/// Calls `onAttempt` when someone swipes down on a sheet whose dismissal is
/// blocked by `interactiveDismissDisabled`, so the sheet can ask before closing.
/// Place it as a background inside the sheet's content.
struct SwipeDismissObserver: UIViewControllerRepresentable {
    let onAttempt: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        ObserverController(onAttempt: onAttempt)
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        (controller as? ObserverController)?.onAttempt = onAttempt
    }

    final class ObserverController: UIViewController, UIAdaptivePresentationControllerDelegate {
        var onAttempt: () -> Void

        init(onAttempt: @escaping () -> Void) {
            self.onAttempt = onAttempt
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        /// SwiftUI's own delegate, kept so every other call still reaches it.
        private weak var original: UIAdaptivePresentationControllerDelegate?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            // `presentationController` belongs to the sheet this view sits in.
            guard let sheet = presentationController, sheet.delegate !== self else { return }
            original = sheet.delegate
            sheet.delegate = self
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            original?.presentationControllerShouldDismiss?(presentationController) ?? true
        }

        func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
            original?.presentationControllerWillDismiss?(presentationController)
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            original?.presentationControllerDidDismiss?(presentationController)
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            original?.presentationControllerDidAttemptToDismiss?(presentationController)
            onAttempt()
        }
    }
}

import UIKit

enum OrientationLock {
    /// The loader starts in portrait; the browser enables rotation after appearing.
    static var current: UIInterfaceOrientationMask = UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait

    @MainActor
    static func apply(_ mask: UIInterfaceOrientationMask) {
        current = mask
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
    }
}

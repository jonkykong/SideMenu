//
//  SideMenuGestureManager.swift
//  SideMenu
//
//  Created by Jon Kent on 12/9/18.
//

import UIKit

internal protocol SideMenuGestureManagerDelegate: class {
    func gestureManagerWidthForMenu(_ gestureManager: SideMenuGestureManager) -> CGFloat?
    func gestureManager(_ gestureManager: SideMenuGestureManager, changedState state: SideMenuGestureManager.State, presenting: Bool)
}

internal class SideMenuGestureManager {

    enum State { case
        start(progress: CGFloat),
        update(progress: CGFloat),
        switching(progress: CGFloat),
        finish,
        cancel
    }

    private(set) var leftSide: Bool = false
    private weak var activeGesture: UIPanGestureRecognizer?

    weak var delegate: SideMenuGestureManagerDelegate?

    var isTracking: Bool {
        return activeGesture != nil
    }

    func addPresentScreenEdgePanGestures(to view: UIView, for sides: [UIRectEdge] = [.left, .right]) -> [UIScreenEdgePanGestureRecognizer] {
        return sides.map { edge in
            let gesture = addScreenEdgeGesture(toView: view, edge: edge)
            gesture.addTarget(self, action:#selector(handlePresentMenuScreenEdge(_:)))
            return gesture
        }
    }

    @discardableResult func addPresentPanGesture(to view: UIView) -> UIPanGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(self, action:#selector(handlePresentMenuPan(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        return panGestureRecognizer
    }

    @discardableResult func addDismissPanGesture(to view: UIView) -> UIPanGestureRecognizer {
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.cancelsTouchesInView = false
        panGestureRecognizer.addTarget(self, action:#selector(handleDismissMenuPan(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        return panGestureRecognizer
    }

    func addDismissGestures(to view: UIView?) {
        guard let view = view else { return }

        addDismissPanGesture(to: view)

        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(handleDismissMenuTap(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
}

private extension SideMenuGestureManager {

    var width: CGFloat {
        return delegate?.gestureManagerWidthForMenu(self) ?? 0
    }

    func factor(_ presenting: Bool) -> CGFloat {
        return presenting ? presentFactor : hideFactor
    }

    var presentFactor: CGFloat {
        return leftSide ? 1 : -1
    }

    var hideFactor: CGFloat {
        return -presentFactor
    }

    @objc func handlePresentMenuScreenEdge(_ gesture: UIScreenEdgePanGestureRecognizer) {
        handleMenuPan(gesture, presenting: true)
    }

    @objc func handleDismissMenuTap(_ tap: UITapGestureRecognizer) {
        guard let delegate = delegate else { return }
        delegate.gestureManager(self, changedState: .finish, presenting: false)
    }

    @objc func handlePresentMenuPan(_ gesture: UIPanGestureRecognizer) {
        handleMenuPan(gesture, presenting: true)
    }

    @objc func handleDismissMenuPan(_ gesture: UIPanGestureRecognizer) {
        handleMenuPan(gesture, presenting: false)
    }

    func addScreenEdgeGesture(toView: UIView, edge: UIRectEdge) -> UIScreenEdgePanGestureRecognizer {
        let screenEdgeGestureRecognizer = UIScreenEdgePanGestureRecognizer()
        screenEdgeGestureRecognizer.cancelsTouchesInView = true
        screenEdgeGestureRecognizer.edges = edge
        toView.addGestureRecognizer(screenEdgeGestureRecognizer)
        return screenEdgeGestureRecognizer
    }

    func handleMenuPan(_ gesture: UIPanGestureRecognizer, presenting: Bool) {
        guard let delegate = delegate else { return }

        if activeGesture == nil {
            if presenting {
                if let gesture = gesture as? UIScreenEdgePanGestureRecognizer {
                    leftSide = gesture.edges.contains(.left)
                } else {
                    // not sure which way the user is swiping yet, so do nothing
                    if gesture.xTranslation == 0 { return }
                    leftSide = gesture.xTranslation > 0
                }
            }

            activeGesture = gesture
        } else if gesture != activeGesture {
            gesture.isEnabled = false
            gesture.isEnabled = true
            return
        }

        let distance = gesture.xTranslation / width
        let progress = max(min(distance * factor(presenting), 1), 0)
        switch (gesture.state) {
        case .began:
            delegate.gestureManager(self, changedState: .start(progress: progress), presenting: presenting)
        case .changed:
            if presenting && gesture.canSwitch {
                let switching = (distance > 0 && !leftSide) || (distance < 0 && leftSide)
                if switching {
                    leftSide = !leftSide
                    delegate.gestureManager(self, changedState: .switching(progress: progress), presenting: presenting)
                    return
                }
            }
            delegate.gestureManager(self, changedState: .update(progress: progress), presenting: presenting)
        default:
            let velocity = gesture.xVelocity * factor(presenting)
            let finished = velocity >= 100 || velocity >= -50 && abs(distance) >= 0.5
            delegate.gestureManager(self, changedState: finished ? .finish : .cancel, presenting: presenting)
            self.activeGesture = nil
        }
    }
}

private extension UIPanGestureRecognizer {

    var canSwitch: Bool {
        return !(self is UIScreenEdgePanGestureRecognizer)
    }

    var presentDirection: SideMenuManager.PresentDirection {
        return xTranslation > 0 ? .left : .right
    }

    var xTranslation: CGFloat {
        return view?.untransform {
            return self.translation(in: view).x
            } ?? 0
    }

    var xVelocity: CGFloat {
        return view?.untransform {
            return self.velocity(in: view).x
            } ?? 0
    }
}

internal extension UIView {

    @discardableResult func untransform(_ code: () -> CGFloat) -> CGFloat {
        let transform = self.transform
        self.transform = .identity
        let value = code()
        self.transform = transform
        return value
    }

    func untransform(_ code: () -> Void) {
        untransform { () -> CGFloat in
            code()
            return 0
        }
    }

    func bringToFront() {
        self.superview?.bringSubviewToFront(self)
    }
}

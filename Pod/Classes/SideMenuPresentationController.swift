//
//  BasePresentationController.swift
//  SideMenu
//
//  Created by Jon Kent on 10/20/18.
//

import UIKit

public protocol SideMenuPresentationControllerDelegate {
    func presentationTransitionWillBegin()
    func presentationTransition()
    func presentationTransitionDidEnd(_ completed: Bool)
    func dismissalTransitionWillBegin()
    func dismissalTransition()
    func dismissalTransitionDidEnd(_ completed: Bool)
}

open class MenuPresentStyle: NSObject, SideMenuPresentationControllerDelegate {

    public struct Options {
        public var backgroundColor: UIColor? = nil
        public var fadeStatusBarStrength: CGFloat = 1
        public var menuFadeStrength: CGFloat = 0
        public var menuOnTop: Bool = false
        public var menuTransformTranslateFactor: CGFloat = 0
        public var menuTransformScaleFactor: CGFloat = 1
        public var onTopShadowColor: UIColor = .black
        public var onTopShadowRadius: CGFloat = 5
        public var onTopShadowOpacity: Float = 0.5
        public var onTopShadowOffset: CGSize = .zero
        public var presentingFadeStrength: CGFloat = 0
        public var presentingTransformTranslateFactor: CGFloat = 0
        public var presentingTransformScaleFactor: CGFloat = 1
        public var presentingParallaxStrength: CGSize = .zero

        public init() {}
    }

    public let options: Options

    public init(options: Options) {
        self.options = options
    }

    public convenience init(_ block: (inout Options) -> Void) {
        var options = Options()
        block(&options)
        self.init(options: options)
    }

    // Override with custom behaviors if desired
    open func presentationTransitionWillBegin() {}
    open func presentationTransition() {}
    open func presentationTransitionDidEnd(_ completed: Bool) {}
    open func dismissalTransitionWillBegin() {}
    open func dismissalTransition() {}
    open func dismissalTransitionDidEnd(_ completed: Bool) {}
}

public extension MenuPresentStyle {
    static let menuSlideIn = MenuPresentStyle {
        $0.menuOnTop = true
        $0.menuTransformTranslateFactor = -1
    }
    static let viewSlideOut = MenuPresentStyle {
        $0.presentingTransformTranslateFactor = 1
    }
    static let viewSlideOutMenuIn = MenuPresentStyle {
        $0.menuTransformTranslateFactor = -1
        $0.presentingTransformTranslateFactor = 1
    }
    @available(*, deprecated, renamed: "viewSlideOutMenuIn")
    static let viewSlideInOut = viewSlideOutMenuIn
    static let menuDissolveIn = MenuPresentStyle {
        $0.menuFadeStrength = 1
        $0.menuOnTop = true
    }
    static let viewSlideOutMenuPartialIn = MenuPresentStyle {
        $0.menuTransformTranslateFactor = -0.5
        $0.presentingTransformTranslateFactor = 1
    }
    static let viewSlideOutMenuOut = MenuPresentStyle {
        $0.menuTransformTranslateFactor = 1
        $0.presentingTransformTranslateFactor = 1
    }
    static let viewSlideOutMenuPartialOut = MenuPresentStyle {
        $0.menuTransformTranslateFactor = 0.5
        $0.presentingTransformTranslateFactor = 1
    }
    static let viewSlideOutMenuZoom = MenuPresentStyle {
        $0.presentingTransformTranslateFactor = 1
        $0.menuTransformScaleFactor = 0.95
    }
}

internal class SideMenuPresentationController: SideMenuPresentationControllerDelegate {

    private let style: MenuPresentStyle
    private let sideMenuNavigationController: Menu
    private let presentingViewController: UIViewController
    private let containerView: UIView
    private let presentingUserInteractionEnabled: Bool
    private var presentingViewControllerUseSnapshot: Bool

    private weak var originalSuperview: UIView?
    private var interactivePopGestureRecognizerEnabled: Bool?
    private var presented: Bool = false

    private var _tapView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
        }
    }
    
    internal var tapView: UIView? {
        if presentingUserInteractionEnabled { return nil }
        var tapView = _tapView
        if tapView == nil {
            tapView = presentingViewControllerUseSnapshot ? sideMenuNavigationController.view.snapshotView(afterScreenUpdates: true) : UIView()
            tapView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            _tapView = tapView
        }
        return tapView
    }

    private var _statusBarView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
        }
    }

    init(style: MenuPresentStyle,
         presented sideMenuNavigationController: Menu,
         presenting presentingViewController: UIViewController,
         containerView: UIView,
         presentingUserInteractionEnabled: Bool,
         presentingViewControllerUseSnapshot: Bool) {
        self.style = style
        self.sideMenuNavigationController = sideMenuNavigationController
        self.presentingViewController = presentingViewController
        self.containerView = containerView
        self.presentingUserInteractionEnabled = presentingUserInteractionEnabled
        self.presentingViewControllerUseSnapshot = presentingViewControllerUseSnapshot
    }

    deinit {
        guard presented else { return }
        fatalError("TEMPORARY: Presentation Controller destroyed without reversing presentation!")
    }
    
    open var frameOfPresentedViewInContainerView: CGRect {
        var rect = containerView.frame
        rect.origin.x = sideMenuNavigationController.leftSide ? 0 : rect.width - menuWidth
        rect.size.width = menuWidth
        return rect
    }
    
    open func containerViewWillLayoutSubviews() {
        sideMenuNavigationController.view.untransform {
            sideMenuNavigationController.view.frame = frameOfPresentedViewInContainerView
        }
        tapView?.frame = presentingViewController.view.bounds
        
        if let statusBarView = statusBarView {
            let statusBarOffset = containerView.frame.size.height - sideMenuNavigationController.view.bounds.height
            var statusBarFrame = UIApplication.shared.statusBarFrame
            
            // For in-call status bar, height is normally 40, which overlaps view. Instead, calculate height difference
            // of view and set height to fill in remaining space.
            if statusBarOffset >= CGFloat.ulpOfOne {
                statusBarFrame.size.height = statusBarOffset
            }

            statusBarView.frame = statusBarFrame
        }
    }
    
    open func presentationTransitionWillBegin() {
        presented = true

        if let backgroundColor = style.options.backgroundColor {
            containerView.backgroundColor = backgroundColor
        }

        originalSuperview = presentingViewController.view.superview
        containerView.addSubview(presentingViewController.view)
        containerView.addSubview(sideMenuNavigationController.view)
        
        layerViews()
        
        if let statusBarView = statusBarView {
            containerView.addSubview(statusBarView)
        }
        
        dismissalTransition()
        style.presentationTransitionWillBegin()
    }

    open func presentationTransition() {
        statusBarView?.alpha = style.options.fadeStatusBarStrength

        transition(
            to: sideMenuNavigationController,
            from: presentingViewController,
            fade: style.options.presentingFadeStrength,
            scale: style.options.presentingTransformScaleFactor,
            translate: style.options.presentingTransformTranslateFactor
        )

        style.presentationTransition()
    }
    
    open func presentationTransitionDidEnd(_ completed: Bool) {
        guard completed else {
            dismissalTransitionDidEnd(!completed)
            return
        }

        addParallax(to: presentingViewController.view)
        
        if let topNavigationController = presentingViewController as? UINavigationController {
            interactivePopGestureRecognizerEnabled = topNavigationController.interactivePopGestureRecognizer?.isEnabled
            topNavigationController.interactivePopGestureRecognizer?.isEnabled = false
        }

        if let tapView = tapView {
            presentingViewController.view.addSubview(tapView)
        }

        containerViewWillLayoutSubviews()
        style.presentationTransitionDidEnd(completed)
    }

    open func dismissalTransitionWillBegin() {
        presentationTransition()
        style.dismissalTransitionWillBegin()
    }

    open func dismissalTransition() {
        statusBarView?.alpha = 0

        transition(
            to: presentingViewController,
            from: sideMenuNavigationController,
            fade: style.options.menuFadeStrength,
            scale: style.options.menuTransformScaleFactor,
            translate: style.options.menuTransformTranslateFactor
        )

        style.dismissalTransition()
    }

    open func dismissalTransitionDidEnd(_ completed: Bool) {
        guard completed else { return }

        presented = false
        
        tapView?.removeFromSuperview()
        statusBarView?.removeFromSuperview()
        sideMenuNavigationController.view.removeFromSuperview()

        presentingViewController.view.motionEffects.removeAll()
        presentingViewController.view.layer.shadowOpacity = 0
        sideMenuNavigationController.view.layer.shadowOpacity = 0
        
        if let interactivePopGestureRecognizerEnabled = interactivePopGestureRecognizerEnabled,
            let topNavigationController = presentingViewController as? UINavigationController {
            topNavigationController.interactivePopGestureRecognizer?.isEnabled = interactivePopGestureRecognizerEnabled
        }

        originalSuperview?.addSubview(presentingViewController.view)

        style.dismissalTransitionDidEnd(completed)
    }
}

private extension SideMenuPresentationController {

    private var statusBarView: UIView? {
        guard style.options.fadeStatusBarStrength != 0 else { return nil }
        var statusBarView = _statusBarView
        if statusBarView == nil {
            statusBarView = UIView()
            statusBarView?.backgroundColor = style.options.backgroundColor ?? .black
            statusBarView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            statusBarView?.isUserInteractionEnabled = false
            _statusBarView = statusBarView
        }
        return statusBarView
    }

    var menuWidth: CGFloat {
        return sideMenuNavigationController.menuWidth
    }

    func transition(to: UIViewController, from: UIViewController, fade: CGFloat, scale: CGFloat, translate: CGFloat) {
        containerViewWillLayoutSubviews()
        
        to.view.transform = .identity
        to.view.alpha = 1

        from.view.alpha = 1 - fade
        from.view.transform = CGAffineTransform.identity
            .scaledBy(
                x: scale,
                y: scale
            ).translatedBy(
                x: (sideMenuNavigationController.leftSide ? 1 : -1) * menuWidth * translate,
                y: 0
        )
    }

    func layerViews() {
        statusBarView?.layer.zPosition = 2

        if style.options.menuOnTop {
            addShadow(to: sideMenuNavigationController.view)
            sideMenuNavigationController.view.bringToFront()
            sideMenuNavigationController.view.layer.zPosition = 1
            presentingViewController.view.layer.zPosition = 0
        } else {
            addShadow(to: presentingViewController.view)
            presentingViewController.view.bringToFront()
            presentingViewController.view.layer.zPosition = 1
            sideMenuNavigationController.view.layer.zPosition = 0
        }
    }

    func addShadow(to view: UIView) {
        view.layer.shadowColor = style.options.onTopShadowColor.cgColor
        view.layer.shadowRadius = style.options.onTopShadowRadius
        view.layer.shadowOpacity = style.options.onTopShadowOpacity
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }

    func addParallax(to view: UIView) {
        var effects: [UIInterpolatingMotionEffect] = []

        let x = style.options.presentingParallaxStrength.width
        if x > 0 {
            let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            horizontal.minimumRelativeValue = -x
            horizontal.maximumRelativeValue = x
            effects.append(horizontal)
        }

        let y = style.options.presentingParallaxStrength.height
        if y > 0 {
            let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            vertical.minimumRelativeValue = -y
            vertical.maximumRelativeValue = y
            effects.append(vertical)
        }

        if effects.count > 0 {
            let group = UIMotionEffectGroup()
            group.motionEffects = effects
            view.addMotionEffect(group)
        }
    }
}

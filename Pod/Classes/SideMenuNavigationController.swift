//
//  SideMenuNavigationController.swift
//
//  Created by Jon Kent on 1/14/16.
//  Copyright © 2016 Jon Kent. All rights reserved.
//

import UIKit

@objc public enum SideMenuPushStyle: Int { case
    `default`,
    popWhenPossible,
    preserve,
    preserveAndHideBackButton,
    replace,
    subMenu
}

@objc public protocol SideMenuNavigationControllerDelegate {
    @objc optional func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool)
    @objc optional func sideMenuDidAppear(menu: SideMenuNavigationController, animated: Bool)
    @objc optional func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool)
    @objc optional func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool)
}

internal protocol SideMenuNavigationControllerTransitionDelegate: class {
    func sideMenuTransitionDidDismiss(menu: Menu)
}

public struct SideMenuSettings: MenuModel, InitializableStruct {
    public var allowPushOfSameClassTwice: Bool = true
    public var alwaysAnimate: Bool = true
    public var animationOptions: UIView.AnimationOptions = .curveEaseInOut
    public var blurEffectStyle: UIBlurEffect.Style? = nil
    public var completeGestureDuration: Double = 0.35
    public var completionCurve: UIView.AnimationCurve = .easeIn
    public var dismissDuration: Double = 0.35
    public var dismissOnPresent: Bool = true
    public var dismissOnPush: Bool = true
    public var dismissOnRotation: Bool = true
    public var dismissWhenBackgrounded: Bool = true
    public var enableSwipeToDismissGesture: Bool = true
    public var enableTapToDismissGesture: Bool = true
    public var initialSpringVelocity: CGFloat = 1
    public var menuWidth: CGFloat = {
        let appScreenRect = UIApplication.shared.keyWindow?.bounds ?? UIWindow().bounds
        let minimumSize = min(appScreenRect.width, appScreenRect.height)
        return min(round(minimumSize * 0.75), 240)
    }()
    public var presentingViewControllerUserInteractionEnabled: Bool = false
    public var presentingViewControllerUseSnapshot: Bool = false
    public var presentDuration: Double = 0.35
    public var presentationStyle: SideMenuPresentationStyle = .viewSlideOut
    public var pushStyle: SideMenuPushStyle = .default
    public var statusBarEndAlpha: CGFloat = 1
    public var usingSpringWithDamping: CGFloat = 1

    public init() {}
}

internal typealias Menu = SideMenuNavigationController

@objcMembers
open class SideMenuNavigationController: UINavigationController {

    private lazy var _leftSide = Protected(false) { [weak self] oldValue, newValue in
        guard self?.isHidden != false else {
            Print.warning(.property, arguments: .leftSide, required: true)
            return oldValue
        }
        return newValue
    }

    private weak var _sideMenuManager: SideMenuManager?
    private weak var foundViewController: UIViewController?
    private weak var interactionController: SideMenuInteractionController?
    private var interactive: Bool = false
    private var originalBackgroundColor: UIColor?
    private var rotating: Bool = false
    private var transitionController: SideMenuTransitionController?

    /// Delegate for receiving appear and disappear related events. If `nil` the visible view controller that displays a `SideMenuNavigationController` automatically receives these events.
    internal weak var sideMenuDelegate: SideMenuNavigationControllerDelegate?

    /// The swipe to dismiss gesture.
    open private(set) weak var swipeToDismissGesture: UIPanGestureRecognizer? = nil
    /// The tap to dismiss gesture.
    open private(set) weak var tapToDismissGesture: UITapGestureRecognizer? = nil

    open var sideMenuManager: SideMenuManager {
        get { return _sideMenuManager ?? SideMenuManager.default }
        set {
            newValue.setMenu(self, forLeftSide: leftSide)

            if let sideMenuManager = _sideMenuManager, sideMenuManager !== newValue {
                let side = SideMenuManager.PresentDirection(leftSide: leftSide)
                Print.warning(.menuAlreadyAssigned, arguments: String(describing: self.self), side.name, String(describing: newValue))
            }
            _sideMenuManager = newValue
        }
    }

    /// The menu settings.
    open var settings = SideMenuSettings() {
        didSet {
            setupBlur()
            if !enableSwipeToDismissGesture {
                removeSwipeGesture()
            }
            if !enableTapToDismissGesture {
                removeTapGesture()
            }
        }
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    public init(rootViewController: UIViewController, settings: SideMenuSettings = SideMenuSettings()) {
        super.init(rootViewController: rootViewController)
        self.settings = settings
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        sideMenuManager.setMenu(self, forLeftSide: leftSide)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if topViewController == nil {
            Print.warning(.emptyMenu)
        }

        // Dismiss keyboard to prevent weird keyboard animations from occurring during transition
        presentingViewController?.view.endEditing(true)

        foundViewController = nil
        activeDelegate?.sideMenuWillAppear?(menu: self, animated: animated)
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // We had presented a view before, so lets dismiss ourselves as already acted upon
        if view.isHidden {
            transitionController?.transition(presenting: false, animated: false)
            dismiss(animated: false, completion: { [weak self] in
                self?.view.isHidden = false
            })
        } else {
            activeDelegate?.sideMenuDidAppear?(menu: self, animated: animated)
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        defer {
            activeDelegate?.sideMenuWillDisappear?(menu: self, animated: animated)
        }

        guard !isBeingDismissed else { return }

        // When presenting a view controller from the menu, the menu view gets moved into another transition view above our transition container
        // which can break the visual layout we had before. So, we move the menu view back to its original transition view to preserve it.
        if let presentingView = presentingViewController?.view, let containerView = presentingView.superview {
            containerView.addSubview(view)
        }

        if dismissOnPresent {
            // We're presenting a view controller from the menu, so we need to hide the menu so it isn't showing when the presented view is dismissed.
            transitionController?.transition(presenting: false, animated: animated, alongsideTransition: { [weak self] in
                guard let self = self else { return }
                self.activeDelegate?.sideMenuWillDisappear?(menu: self, animated: animated)
                }, complete: false, completion: { [weak self] _ in
                    guard let self = self else { return }
                    self.activeDelegate?.sideMenuDidDisappear?(menu: self, animated: animated)
                    self.view.isHidden = true
            })
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Work-around: if the menu is dismissed without animation the transition logic is never called to restore the
        // the view hierarchy leaving the screen black/empty. This is because the transition moves views within a container
        // view, but dismissing without animation removes the container view before the original hierarchy is restored.
        // This check corrects that.
        if let foundViewController = self.visibleViewController(from: presentingViewController), foundViewController.view.window == nil {
            transitionController?.transition(presenting: false, animated: false)
        }

        // Clear selecton on UITableViewControllers when reappearing using custom transitions
        if let tableViewController = topViewController as? UITableViewController,
            let tableView = tableViewController.tableView,
            let indexPaths = tableView.indexPathsForSelectedRows,
            tableViewController.clearsSelectionOnViewWillAppear {
            indexPaths.forEach { tableView.deselectRow(at: $0, animated: false) }
        }

        activeDelegate?.sideMenuDidDisappear?(menu: self, animated: animated)

        if isBeingDismissed {
            transitionController = nil
        } else if dismissOnPresent {
            view.isHidden = true
        }
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Don't bother resizing if the view isn't visible
        guard let transitionController = transitionController, !view.isHidden else { return }

        rotating = true
        
        let dismiss = self.presentingViewControllerUseSnapshot || self.dismissOnRotation
        coordinator.animate(alongsideTransition: { _ in
            if dismiss {
                transitionController.transition(presenting: false, animated: false, complete: false)
            } else {
                transitionController.layout()
            }
        }) { [weak self] _ in
            guard let self = self else { return }
            if dismiss {
                self.dismissMenu(animated: false)
            }
            self.rotating = false
        }
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        transitionController?.layout()
    }
    
    override open func pushViewController(_ viewController: UIViewController, animated: Bool) {
        guard viewControllers.count > 0 && pushStyle != .subMenu else {
            // NOTE: pushViewController is called by init(rootViewController: UIViewController)
            // so we must perform the normal super method in this case
            return super.pushViewController(viewController, animated: animated)
        }

        let splitViewController = presentingViewController as? UISplitViewController
        let tabBarController = presentingViewController as? UITabBarController
        let potentialNavigationController = (splitViewController?.viewControllers.first ?? tabBarController?.selectedViewController) ?? presentingViewController
        guard let navigationController = potentialNavigationController as? UINavigationController else {
            return Print.warning(.cannotPush, arguments: String(describing: potentialNavigationController.self), required: true)
        }

        // To avoid overlapping dismiss & pop/push calls, create a transaction block where the menu
        // is dismissed after showing the appropriate screen
        CATransaction.begin()
        defer { CATransaction.commit() }

        if dismissOnPush {
            let animated = animated || alwaysAnimate
            if animated {
                let areAnimationsEnabled = UIView.areAnimationsEnabled
                UIView.setAnimationsEnabled(true)
                transitionController?.transition(presenting: false, animated: animated, alongsideTransition: { [weak self] in
                    guard let self = self else { return }
                    self.activeDelegate?.sideMenuWillDisappear?(menu: self, animated: animated)
                    }, completion: { [weak self] _ in
                        guard let self = self else { return }
                        self.activeDelegate?.sideMenuDidDisappear?(menu: self, animated: animated)
                        self.dismiss(animated: false, completion: nil)
                        self.foundViewController = nil
                })
                UIView.setAnimationsEnabled(areAnimationsEnabled)
            }
        }

        if let lastViewController = navigationController.viewControllers.last,
            !allowPushOfSameClassTwice && type(of: lastViewController) == type(of: viewController) {
            return
        }

        switch pushStyle {
        case .subMenu: return // handled earlier
        case .default: break
        case .popWhenPossible:
            for subViewController in navigationController.viewControllers.reversed() {
                if type(of: subViewController) == type(of: viewController) {
                    navigationController.popToViewController(subViewController, animated: animated)
                    return
                }
            }
        case .preserve, .preserveAndHideBackButton:
            var viewControllers = navigationController.viewControllers
            let filtered = viewControllers.filter { preservedViewController in type(of: preservedViewController) == type(of: viewController) }
            if let preservedViewController = filtered.last {
                viewControllers = viewControllers.filter { subViewController in subViewController !== preservedViewController }
                if pushStyle == .preserveAndHideBackButton {
                    preservedViewController.navigationItem.hidesBackButton = true
                }
                viewControllers.append(preservedViewController)
                return navigationController.setViewControllers(viewControllers, animated: animated)
            }
            if pushStyle == .preserveAndHideBackButton {
                viewController.navigationItem.hidesBackButton = true
            }
        case .replace:
            viewController.navigationItem.hidesBackButton = true
            return navigationController.setViewControllers([viewController], animated: animated)
        }

        navigationController.pushViewController(viewController, animated: animated)
    }

    override open var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get { return self }
        set { Print.warning(.transitioningDelegate, required: true) }
    }
}

// Interface
extension SideMenuNavigationController: MenuModel {

    @IBInspectable open var allowPushOfSameClassTwice: Bool {
        get { return settings.allowPushOfSameClassTwice }
        set { settings.allowPushOfSameClassTwice = newValue }
    }

    @IBInspectable open var alwaysAnimate: Bool {
        get { return settings.alwaysAnimate }
        set { settings.alwaysAnimate = newValue }
    }

    @IBInspectable open var animationOptions: UIView.AnimationOptions {
        get { return settings.animationOptions }
        set { settings.animationOptions = newValue }
    }

    open var blurEffectStyle: UIBlurEffect.Style? {
        get { return settings.blurEffectStyle }
        set { settings.blurEffectStyle = newValue }
    }

    @IBInspectable open var completeGestureDuration: Double {
        get { return settings.completeGestureDuration }
        set { settings.completeGestureDuration = newValue }
    }

    @IBInspectable open var completionCurve: UIView.AnimationCurve {
        get { return settings.completionCurve }
        set { settings.completionCurve = newValue }
    }

    @IBInspectable open var dismissDuration: Double {
        get { return settings.dismissDuration }
        set { settings.dismissDuration = newValue }
    }

    @IBInspectable open var dismissOnPresent: Bool {
        get { return settings.dismissOnPresent }
        set { settings.dismissOnPresent = newValue }
    }

    @IBInspectable open var dismissOnPush: Bool {
        get { return settings.dismissOnPush }
        set { settings.dismissOnPush = newValue }
    }

    @IBInspectable open var dismissOnRotation: Bool {
        get { return settings.dismissOnRotation }
        set { settings.dismissOnRotation = newValue }
    }

    @IBInspectable open var dismissWhenBackgrounded: Bool {
        get { return settings.dismissWhenBackgrounded }
        set { settings.dismissWhenBackgrounded = newValue }
    }

    @IBInspectable open var enableSwipeToDismissGesture: Bool {
        get { return settings.enableSwipeToDismissGesture }
        set { settings.enableSwipeToDismissGesture = newValue }
    }

    @IBInspectable open var enableTapToDismissGesture: Bool {
        get { return settings.enableTapToDismissGesture }
        set { settings.enableTapToDismissGesture = newValue }
    }

    @IBInspectable open var initialSpringVelocity: CGFloat {
        get { return settings.initialSpringVelocity }
        set { settings.initialSpringVelocity = newValue }
    }

    /// Whether the menu appears on the right or left side of the screen. Right is the default. This property cannot be changed after the menu has loaded.
    @IBInspectable open var leftSide: Bool {
        get { return _leftSide.value }
        set { _leftSide.value = newValue }
    }
  
    /// Indicates if the menu is anywhere in the view hierarchy, even if covered by another view controller.
    open override var isHidden: Bool {
        return super.isHidden
    }

    @IBInspectable open var menuWidth: CGFloat {
        get { return settings.menuWidth }
        set { settings.menuWidth = newValue }
    }

    @IBInspectable open var presentingViewControllerUserInteractionEnabled: Bool {
        get { return settings.presentingViewControllerUserInteractionEnabled }
        set { settings.presentingViewControllerUserInteractionEnabled = newValue }
    }

    @IBInspectable open var presentingViewControllerUseSnapshot: Bool {
        get { return settings.presentingViewControllerUseSnapshot }
        set { settings.presentingViewControllerUseSnapshot = newValue }
    }

    @IBInspectable open var presentDuration: Double {
        get { return settings.presentDuration }
        set { settings.presentDuration = newValue }
    }

    open var presentationStyle: SideMenuPresentationStyle {
        get { return settings.presentationStyle }
        set { settings.presentationStyle = newValue }
    }

    @IBInspectable open var pushStyle: SideMenuPushStyle {
        get { return settings.pushStyle }
        set { settings.pushStyle = newValue }
    }

    @IBInspectable open var statusBarEndAlpha: CGFloat {
        get { return settings.statusBarEndAlpha }
        set { settings.statusBarEndAlpha = newValue }
    }

    @IBInspectable open var usingSpringWithDamping: CGFloat {
        get { return settings.usingSpringWithDamping }
        set { settings.usingSpringWithDamping = newValue }
    }
}

// IMPORTANT: These methods must be declared open or they will not be called.
extension SideMenuNavigationController: UIViewControllerTransitioningDelegate {

    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionController = SideMenuTransitionController(
            config: self,
            leftSide: leftSide,
            delegate: self)
        return transitionController
    }

    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionController
    }

    open func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController(using: animator)
    }

    open func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController(using: animator)
    }

    private func interactionController(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard interactive else { return nil }
        interactive = false
        let interactionController = SideMenuInteractionController(cancelWhenBackgrounded: dismissWhenBackgrounded, completionCurve: completionCurve)
        self.interactionController = interactionController
        return interactionController
    }
}

extension SideMenuNavigationController: SideMenuTransitionControllerDelegate {

    internal func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, didDismiss viewController: UIViewController) {
        sideMenuManager.sideMenuTransitionDidDismiss(menu: self)
    }

    internal func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, didPresent viewController: UIViewController) {
        removeSwipeGesture()
        swipeToDismissGesture = addSwipeToDismissGesture(to: view.superview)
        tapToDismissGesture = addTapToDismissGesture(to: view.superview)
    }
}

internal extension SideMenuNavigationController {

    func handleMenuPan(_ gesture: UIPanGestureRecognizer, _ presenting: Bool) {
        let width = menuWidth
        let distance = gesture.xTranslation / width
        let progress = max(min(distance * factor(presenting), 1), 0)
        switch (gesture.state) {
        case .began:
            if !presenting {
                dismissMenu(interactively: true)
            }
            interactionController?.handle(state: .update(progress: progress))
        case .changed:
            interactionController?.handle(state: .update(progress: progress))
        case .ended:
            let velocity = gesture.xVelocity * factor(presenting)
            let finished = velocity >= 100 || velocity >= -50 && abs(progress) >= 0.5
            interactionController?.handle(state: finished ? .finish : .cancel)
        default:
            interactionController?.handle(state: .cancel)
        }
    }

    func cancelMenuPan(_ gesture: UIPanGestureRecognizer) {
        interactionController?.handle(state: .cancel)
    }

    func dismissMenu(animated flag: Bool = true, interactively interactive: Bool = false, completion: (() -> Void)? = nil) {
        guard !isHidden else { return }
        self.interactive = interactive
        dismiss(animated: flag, completion: completion)
    }

    // Note: although this method is syntactically reversed it allows the interactive property to scoped privately
    func presentFrom(_ viewControllerToPresentFrom: UIViewController?, interactively interactive: Bool, completion: (() -> Void)? = nil) {
        guard let viewControllerToPresentFrom = viewControllerToPresentFrom else { return }
        self.interactive = interactive
        viewControllerToPresentFrom.present(self, animated: true, completion: completion)
    }
}

private extension SideMenuNavigationController {

    weak var activeDelegate: SideMenuNavigationControllerDelegate? {
        guard !view.isHidden else { return nil }
        if let sideMenuDelegate = sideMenuDelegate {
            return sideMenuDelegate
        }
        return visibleViewController(from: presentingViewController) as? SideMenuNavigationControllerDelegate
    }

    func visibleViewController(from: UIViewController?) -> UIViewController? {
        if let foundDelegate = foundViewController {
            return foundDelegate
        }
        if let navigationController = from as? UINavigationController {
            return visibleViewController(from: navigationController.topViewController)
        }
        if let tabBarController = from as? UITabBarController {
            return visibleViewController(from: tabBarController.selectedViewController)
        }
        if let splitViewController = from as? UISplitViewController {
            return visibleViewController(from: splitViewController.viewControllers.last)
        }

        foundViewController = from
        return from
    }

    func setup() {
        modalPresentationStyle = .overFullScreen

        setupBlur()
        registerForNotifications()
    }

    func setupBlur() {
        removeBlur()

        guard let blurEffectStyle = blurEffectStyle,
            let view = topViewController?.view,
            !UIAccessibility.isReduceTransparencyEnabled else {
                return
        }

        originalBackgroundColor = originalBackgroundColor ?? view.backgroundColor

        let blurEffect = UIBlurEffect(style: blurEffectStyle)
        let blurView = UIVisualEffectView(effect: blurEffect)
        view.backgroundColor = UIColor.clear
        if let tableViewController = topViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = blurView
            tableViewController.tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
            tableViewController.tableView.reloadData()
        } else {
            blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            blurView.frame = view.bounds
            view.insertSubview(blurView, at: 0)
        }
    }

    func removeBlur() {
        guard let originalBackgroundColor = originalBackgroundColor,
            let view = topViewController?.view else {
                return
        }

        self.originalBackgroundColor = nil
        view.backgroundColor = originalBackgroundColor

        if let tableViewController = topViewController as? UITableViewController {
            tableViewController.tableView.backgroundView = nil
            tableViewController.tableView.separatorEffect = nil
            tableViewController.tableView.reloadData()
        } else if let blurView = view.subviews.first as? UIVisualEffectView {
            blurView.removeFromSuperview()
        }
    }

    func removeSwipeGesture() {
        if let swipeToDismissGesture = swipeToDismissGesture {
            swipeToDismissGesture.view?.removeGestureRecognizer(swipeToDismissGesture)
        }
    }

    func removeTapGesture() {
        if let tapToDismissGesture = tapToDismissGesture {
            tapToDismissGesture.view?.removeGestureRecognizer(tapToDismissGesture)
        }
    }

    func registerForNotifications() {
        NotificationCenter.default.removeObserver(self)

        [UIApplication.willChangeStatusBarFrameNotification,
        UIApplication.didEnterBackgroundNotification].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: $0, object: nil)
        }
    }

    @objc func handleNotification(notification: NSNotification) {
        guard isHidden else { return }

        switch notification.name {
        case UIApplication.willChangeStatusBarFrameNotification:
            // Dismiss for in-call status bar changes but not rotation
            if !rotating {
                dismissMenu()
            }
        case UIApplication.didEnterBackgroundNotification:
            if dismissWhenBackgrounded {
                dismissMenu()
            }
        default: break
        }
    }

    @discardableResult func addSwipeToDismissGesture(to view: UIView?) -> UIPanGestureRecognizer? {
        guard enableSwipeToDismissGesture else { return nil }
        return UIPanGestureRecognizer(addTo: view, target: self, action: #selector(handleDismissMenuPan(_:)))?.with {
            $0.cancelsTouchesInView = false
        }
    }

    @discardableResult func addTapToDismissGesture(to view: UIView?) -> UITapGestureRecognizer? {
        guard enableTapToDismissGesture else { return nil }
        return UITapGestureRecognizer(addTo: view, target: self, action: #selector(handleDismissMenuTap(_:)))?.with {
            $0.cancelsTouchesInView = false
        }
    }

    @objc func handleDismissMenuTap(_ tap: UITapGestureRecognizer) {
        let hitTest = view.window?.hitTest(tap.location(in: view.superview), with: nil)
        guard hitTest == view.superview else { return }
        dismissMenu()
    }

    @objc func handleDismissMenuPan(_ gesture: UIPanGestureRecognizer) {
        handleMenuPan(gesture, false)
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
}

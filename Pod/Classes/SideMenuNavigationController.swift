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

    internal var hidesBackButton: Bool {
        switch self {
        case .preserveAndHideBackButton, .replace: return true
        case .default, .popWhenPossible, .preserve, .subMenu: return false
        }
    }
}

internal protocol MenuModel {
    /// Prevents the same view controller (or a view controller of the same class) from being pushed more than once. Defaults to true.
    var allowPushOfSameClassTwice: Bool { get }
    /// Forces menus to always animate when appearing or disappearing, regardless of a pushed view controller's animation.
    var alwaysAnimate: Bool { get }
    /**
     The blur effect style of the menu if the menu's root view controller is a UITableViewController or UICollectionViewController.

     - Note: If you want cells in a UITableViewController menu to show vibrancy, make them a subclass of UITableViewVibrantCell.
     */
    var blurEffectStyle: UIBlurEffect.Style? { get }
    /// Animation curve of the remaining animation when the menu is partially dismissed with gestures. Default is .easeIn.
    var completionCurve: UIView.AnimationCurve { get }
    /// Automatically dismisses the menu when another view is presented from it.
    var dismissOnPresent: Bool { get }
    /// Automatically dismisses the menu when another view controller is pushed from it.
    var dismissOnPush: Bool { get }
    /// Automatically dismisses the menu when the screen is rotated.
    var dismissOnRotation: Bool { get }
    /// Automatically dismisses the menu when app goes to the background.
    var dismissWhenBackgrounded: Bool { get }
    /// Enable or disable a swipe gesture that dismisses the menu. Will not be triggered when `presentingViewControllerUserInteractionEnabled` is set to true. Default is true.
    var enableSwipeToDismissGesture: Bool { get }
    /// Enable or disable a tap gesture that dismisses the menu. Will not be triggered when `presentingViewControllerUserInteractionEnabled` is set to true. Default is true.
    var enableTapToDismissGesture: Bool { get }
    /**
     The push style of the menu.

     There are six modes in MenuPushStyle:
     - defaultBehavior: The view controller is pushed onto the stack.
     - popWhenPossible: If a view controller already in the stack is of the same class as the pushed view controller, the stack is instead popped back to the existing view controller. This behavior can help users from getting lost in a deep navigation stack.
     - preserve: If a view controller already in the stack is of the same class as the pushed view controller, the existing view controller is pushed to the end of the stack. This behavior is similar to a UITabBarController.
     - preserveAndHideBackButton: Same as .preserve and back buttons are automatically hidden.
     - replace: Any existing view controllers are released from the stack and replaced with the pushed view controller. Back buttons are automatically hidden. This behavior is ideal if view controllers require a lot of memory or their state doesn't need to be preserved..
     - subMenu: Unlike all other behaviors that push using the menu's presentingViewController, this behavior pushes view controllers within the menu.  Use this behavior if you want to display a sub menu.
     */
    var pushStyle: SideMenuPushStyle { get }
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

public struct SideMenuSettings: SideMenuNavigationController.Model, InitializableStruct {
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

    internal typealias Model = MenuModel & PresentationModel & AnimationModel

    private lazy var _leftSide = Protected(false) { [weak self] oldValue, newValue in
        guard self?.isHidden != false else {
            Print.warning(.property, arguments: .leftSide, required: true)
            return oldValue
        }
        return newValue
    }

    private weak var _sideMenuManager: SideMenuManager?
    private weak var foundViewController: UIViewController?
    private var originalBackgroundColor: UIColor?
    private var rotating: Bool = false
    private var transitionController: SideMenuTransitionController?
    private var transitionInteractive: Bool = false

    /// Delegate for receiving appear and disappear related events. If `nil` the visible view controller that displays a `SideMenuNavigationController` automatically receives these events.
    public weak var sideMenuDelegate: SideMenuNavigationControllerDelegate?

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
                swipeToDismissGesture?.remove()
            }
            if !enableTapToDismissGesture {
                tapToDismissGesture?.remove()
            }
        }
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    public init(rootViewController: UIViewController, settings: SideMenuSettings = SideMenuSettings()) {
        self.settings = settings
        super.init(rootViewController: rootViewController)
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
            dismiss(animated: false, completion: { [weak self] in
                self?.view.isHidden = false
            })
        } else {
            activeDelegate?.sideMenuDidAppear?(menu: self, animated: animated)
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        defer { activeDelegate?.sideMenuWillDisappear?(menu: self, animated: animated) }

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
        if isBeingDismissed {
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
        guard viewControllers.count > 0 else {
            // NOTE: pushViewController is called by init(rootViewController: UIViewController)
            // so we must perform the normal super method in this case
            return super.pushViewController(viewController, animated: animated)
        }

        var alongsideTransition: (() -> Void)? = nil
        if dismissOnPush {
            alongsideTransition = { [weak self] in
                guard let self = self else { return }
                self.dismissAnimation(animated: animated || self.alwaysAnimate)
            }
        }

        let pushed = SideMenuPushCoordinator(config:
            .init(
                allowPushOfSameClassTwice: allowPushOfSameClassTwice,
                alongsideTransition: alongsideTransition,
                animated: animated,
                fromViewController: self,
                pushStyle: pushStyle,
                toViewController: viewController
            )
            ).start()

        if !pushed {
            super.pushViewController(viewController, animated: animated)
        }
    }

    override open var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        get {
            guard transitionController == nil else { return transitionController }
            transitionController = SideMenuTransitionController(leftSide: leftSide, config: settings)
            transitionController?.delegate = self
            transitionController?.interactive = transitionInteractive
            transitionInteractive = false
            return transitionController
        }
        set { Print.warning(.transitioningDelegate, required: true) }
    }
}

// Interface
extension SideMenuNavigationController: SideMenuNavigationController.Model {

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

extension SideMenuNavigationController: SideMenuTransitionControllerDelegate {

    func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, didDismiss viewController: UIViewController) {
        sideMenuManager.sideMenuTransitionDidDismiss(menu: self)
    }

    func sideMenuTransitionController(_ transitionController: SideMenuTransitionController, didPresent viewController: UIViewController) {
        swipeToDismissGesture?.remove()
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
            fallthrough
        case .changed:
            transitionController?.handle(state: .update(progress: progress))
        case .ended:
            let velocity = gesture.xVelocity * factor(presenting)
            let finished = velocity >= 100 || velocity >= -50 && abs(progress) >= 0.5
            transitionController?.handle(state: finished ? .finish : .cancel)
        default:
            transitionController?.handle(state: .cancel)
        }
    }

    func cancelMenuPan(_ gesture: UIPanGestureRecognizer) {
        transitionController?.handle(state: .cancel)
    }

    func dismissMenu(animated flag: Bool = true, interactively: Bool = false, completion: (() -> Void)? = nil) {
        guard !isHidden else { return }
        transitionController?.interactive = interactively
        dismiss(animated: flag, completion: completion)
    }

    // Note: although this method is syntactically reversed it allows the interactive property to scoped privately
    func present(from viewController: UIViewController?, interactively: Bool, completion: (() -> Void)? = nil) {
        guard let viewController = viewController else { return }
        transitionInteractive = interactively
        viewController.present(self, animated: true, completion: completion)
    }
}

private extension SideMenuNavigationController {

    weak var activeDelegate: SideMenuNavigationControllerDelegate? {
        guard !view.isHidden else { return nil }
        if let sideMenuDelegate = sideMenuDelegate { return sideMenuDelegate }
        return findViewController as? SideMenuNavigationControllerDelegate
    }

    var findViewController: UIViewController? {
        foundViewController = foundViewController ?? presentingViewController?.activeViewController
        return foundViewController
    }

    func dismissAnimation(animated: Bool) {
        transitionController?.transition(presenting: false, animated: animated, alongsideTransition: { [weak self] in
            guard let self = self else { return }
            self.activeDelegate?.sideMenuWillDisappear?(menu: self, animated: animated)
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                self.activeDelegate?.sideMenuDidDisappear?(menu: self, animated: animated)
                self.dismiss(animated: false, completion: nil)
                self.foundViewController = nil
        })
    }

    func setup() {
        modalPresentationStyle = .overFullScreen

        setupBlur()
        if #available(iOS 13.0, *) {} else {
            registerForNotifications()
        }
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

    @available(iOS, deprecated: 13.0)
    func registerForNotifications() {
        NotificationCenter.default.removeObserver(self)

        [UIApplication.willChangeStatusBarFrameNotification,
         UIApplication.didEnterBackgroundNotification].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name: $0, object: nil)
        }
    }

    @available(iOS, deprecated: 13.0)
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

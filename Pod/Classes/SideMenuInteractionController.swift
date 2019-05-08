//
//  SideMenuInteractiveTransitionController.swift
//  SideMenu
//
//  Created by Jon Kent on 12/28/18.
//

import UIKit

internal protocol SideMenuInteractable {
    func handle(state: SideMenuInteractionController.State)
}

internal class SideMenuInteractionController: UIPercentDrivenInteractiveTransition {

    internal enum State { case
        update(progress: CGFloat),
        switching(progress: CGFloat),
        finish,
        cancel
    }

    private(set) var isCancelled: Bool = false
    private(set) var isFinished: Bool = false

    init(completionCurve: UIView.AnimationCurve = .easeIn) {
        super.init()
        self.completionCurve = completionCurve
    }

    override func cancel() {
        isCancelled = true
        super.cancel()
    }

    override func finish() {
        isFinished = true
        super.finish()
    }

    override func update(_ percentComplete: CGFloat) {
        guard !isCancelled && !isFinished else { return }
        super.update(percentComplete)
    }
}

extension SideMenuInteractionController: SideMenuInteractable {

    func handle(state: State) {
        switch state {
        case .update(let progress):
            update(progress)
        case .finish:
            finish()
        case .switching, .cancel:
            cancel()
        }
    }
}

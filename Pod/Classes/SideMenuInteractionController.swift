//
//  SideMenuInteractiveTransitionController.swift
//  SideMenu
//
//  Created by Jon Kent on 12/28/18.
//

import UIKit

internal class SideMenuInteractionController: UIPercentDrivenInteractiveTransition {

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

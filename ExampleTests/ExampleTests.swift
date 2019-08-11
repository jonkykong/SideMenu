//
//  ExampleTests.swift
//  ExampleTests
//
//  Created by Jon Kent on 8/10/19.
//  Copyright © 2019 jonkykong. All rights reserved.
//

import XCTest

class ExampleTests: XCTestCase {

    private let styleTitles = ["Slide In", "Slide Out", "In + Out", "Dissolve"]
    private let swipeHere = "Swipe Here"

    private let app = XCUIApplication()
    private var mainViewController: XCUIElement {
        return app.navigationBars[swipeHere]
    }
    private var mainViewControllerNavigation: XCUIElement {
        return mainViewController.otherElements[swipeHere]
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTapLeft() {
        let elementsQuery = app.scrollViews.otherElements
        for title in styleTitles {
            elementsQuery.buttons[title].tap()
            mainViewController.buttons["Left Menu"].tap()
            app.tables/*@START_MENU_TOKEN@*/.staticTexts["Push View Controller 1"]/*[[".cells.staticTexts[\"Push View Controller 1\"]",".staticTexts[\"Push View Controller 1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            app.navigationBars["You Can Still Swipe!"].buttons[swipeHere].tap()
            validate()
        }
    }

    func testTapRight() {
        let elementsQuery = app.scrollViews.otherElements
        for title in styleTitles {
            elementsQuery.buttons[title].tap()
            mainViewController.buttons["Right Menu"].tap()
            app.tables/*@START_MENU_TOKEN@*/.staticTexts["Present View Controller 1"]/*[[".cells.staticTexts[\"Present View Controller 1\"]",".staticTexts[\"Present View Controller 1\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            app.buttons["Dismiss"].tap()
            validate()
        }
    }

    func testSwiping() {
        mainViewControllerNavigation.swipeRight()
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element
        element.swipeLeft()
        validate()

        element.swipeLeft()
        mainViewControllerNavigation.swipeLeft()
        element.swipeRight()
        validate()
    }

    private func validate() {
        XCTAssertTrue(mainViewController.exists)
    }

    /* TODO - More tests:
     - Rotation
     - All menu settings
     */
}

//
// 🦠 Corona-Warn-App
//

import XCTest
@testable import ENA

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
class ExposureSubmissionTestResultViewModelTests: XCTestCase {
	
	private var store: Store!
	
	override func setUpWithError() throws {
		store = MockTestStore()
	}
	
	func testTimeStamp() {
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.devicePairingSuccessfulTimestamp = 37
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store),
			testResult: .positive,
			exposureSubmissionService: exposureSubmissionService,
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertEqual(model.timeStamp, exposureSubmissionService.devicePairingSuccessfulTimestamp)
	}
	
	func testDidTapPrimaryButtonOnPositiveTestResult() {
		let getTestResultExpectation = expectation(description: "getTestResult on exposure submission service is called")
		getTestResultExpectation.isInverted = true
		
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.getTestResultCallback = { _ in getTestResultExpectation.fulfill() }
		
		let onContinueWithSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithSymptomsFlowButtonTap closure is called"
		)
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .positive,
			exposureSubmissionService: exposureSubmissionService,
			onContinueWithSymptomsFlowButtonTap: { _ in
				onContinueWithSymptomsFlowButtonTapExpectation.fulfill()
			},
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		model.didTapPrimaryButton()
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		waitForExpectations(timeout: .short)
	}
	
	func testDidTapPrimaryButtonOnNegativeInvalidOrExpiredTestResult() {
		let testResults: [TestResult] = [.negative, .invalid, .expired]
		for testResult in testResults {
			let getTestResultExpectation = expectation(description: "getTestResult on exposure submission service is called")
			getTestResultExpectation.isInverted = true
			
			let exposureSubmissionService = MockExposureSubmissionService()
			exposureSubmissionService.getTestResultCallback = { _ in getTestResultExpectation.fulfill() }
			
			let onContinueWithSymptomsFlowButtonTapExpectation = expectation(
				description: "onContinueWithSymptomsFlowButtonTap closure is called"
			)
			onContinueWithSymptomsFlowButtonTapExpectation.isInverted = true
			
			
			let model = ExposureSubmissionTestResultViewModel(
				warnOthersReminder: WarnOthersReminder(store: self.store), testResult: testResult,
				exposureSubmissionService: exposureSubmissionService,
				onContinueWithSymptomsFlowButtonTap: { _ in
					onContinueWithSymptomsFlowButtonTapExpectation.fulfill()
				},
				onContinueWithoutSymptomsFlowButtonTap: { _ in },
				onTestDeleted: { },
				onSubmissionConsentButtonTap: { _ in }
			)
			
			XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
			
			model.didTapPrimaryButton()
			
			XCTAssertTrue(model.shouldShowDeletionConfirmationAlert)
			
			waitForExpectations(timeout: .short)
		}
	}
	
	func testDidTapPrimaryButtonOnPendingTestResult() {
		let getTestResultExpectation = expectation(description: "getTestResult on exposure submission service is called")
		
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.getTestResultCallback = { _ in getTestResultExpectation.fulfill() }
		
		let onContinueWithSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithSymptomsFlowButtonTap closure is called"
		)
		onContinueWithSymptomsFlowButtonTapExpectation.isInverted = true
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .pending,
			exposureSubmissionService: exposureSubmissionService,
			onContinueWithSymptomsFlowButtonTap: { _ in
				onContinueWithSymptomsFlowButtonTapExpectation.fulfill()
			},
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		model.didTapPrimaryButton()
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		waitForExpectations(timeout: .short)
	}
	
	func testDidTapPrimaryButtonOnPendingTestResultUpdatesButtons() {
		let getTestResultExpectation = expectation(description: "getTestResult on exposure submission service is called")
		
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.getTestResultCallback = { completion in
			completion(.success(.positive))
			getTestResultExpectation.fulfill()
		}
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .pending,
			exposureSubmissionService: exposureSubmissionService,
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonHidden)
		
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isSecondaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonHidden)
		XCTAssertFalse(model.navigationFooterItem.secondaryButtonHasBorder)
		
		model.didTapPrimaryButton()
		
		waitForExpectations(timeout: .short)
		
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonHidden)
		
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isSecondaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonHidden)
		XCTAssertTrue(model.navigationFooterItem.secondaryButtonHasBorder)
	}
	
	func testDidTapPrimaryButtonOnPendingTestResultSetsError() {
		let getTestResultExpectation = expectation(description: "getTestResult on exposure submission service is called")
		
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.getTestResultCallback = { completion in
			completion(.failure(.internal))
			getTestResultExpectation.fulfill()
		}
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .pending,
			exposureSubmissionService: exposureSubmissionService,
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		model.didTapPrimaryButton()
		
		waitForExpectations(timeout: .short)
		
		XCTAssertEqual(model.error, .internal)
	}
	
	func testDidTapPrimaryButtonOnPositiveTestResultUpdatesButtonsLoadingStateTrue() {
		let onContinueWithSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithoutSymptomsFlowButtonTap closure is called"
		)
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .positive,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { isLoading in
				isLoading(true)
				
				onContinueWithSymptomsFlowButtonTapExpectation.fulfill()
			},
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		model.didTapPrimaryButton()
		
		waitForExpectations(timeout: .short)
		
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonEnabled)
		XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonLoading)
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonEnabled)
	}
	
	func testDidTapPrimaryButtonOnPositiveTestResultUpdatesButtonsLoadingStateFalse() {
		let onContinueWithSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithoutSymptomsFlowButtonTap closure is not called"
		)
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .positive,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { isLoading in
				isLoading(true)
				isLoading(false)
				
				onContinueWithSymptomsFlowButtonTapExpectation.fulfill()
			},
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		model.didTapPrimaryButton()
		
		waitForExpectations(timeout: .short)
		
		XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isSecondaryButtonEnabled)
	}
	
	func testDidTapPrimaryButtonOnPendingTestResultUpdatesButtonsLoadingState() {
		let getTestResultExpectation = expectation(description: "getTestResult on exposure submission service is called")
		
		let exposureSubmissionService = MockExposureSubmissionService()
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .pending,
			exposureSubmissionService: exposureSubmissionService,
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		exposureSubmissionService.getTestResultCallback = { completion in
			// Buttons should be in loading state when getTestResult is called on the exposure submission service
			XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonEnabled)
			XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonLoading)
			XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonEnabled)
			
			completion(.success(.pending))
			
			getTestResultExpectation.fulfill()
		}
		
		model.didTapPrimaryButton()
		
		waitForExpectations(timeout: .short)
		
		XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isSecondaryButtonEnabled)
	}
	
	func testDidTapSecondaryButtonOnPositiveTestResult() {
		let onContinueWithoutSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithoutSymptomsFlowButtonTap closure is called"
		)
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .positive,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in
				onContinueWithoutSymptomsFlowButtonTapExpectation.fulfill()
			},
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		model.didTapSecondaryButton()
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		waitForExpectations(timeout: .short)
	}
	
	func testDidTapSecondaryButtonOnPendingTestResult() {
		let onContinueWithoutSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithoutSymptomsFlowButtonTap closure is not called"
		)
		onContinueWithoutSymptomsFlowButtonTapExpectation.isInverted = true
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .pending,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in onContinueWithoutSymptomsFlowButtonTapExpectation.fulfill() },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
		
		model.didTapSecondaryButton()
		
		XCTAssertTrue(model.shouldShowDeletionConfirmationAlert)
		
		waitForExpectations(timeout: .short)
	}
	
	func testDidTapSecondaryButtonOnNegativeInvalidOrExpiredTestResult() {
		let testResults: [TestResult] = [.negative, .invalid, .expired]
		for testResult in testResults {
			let onContinueWithoutSymptomsFlowButtonTapExpectation = expectation(
				description: "onContinueWithoutSymptomsFlowButtonTap closure is not called"
			)
			onContinueWithoutSymptomsFlowButtonTapExpectation.isInverted = true
			
			let model = ExposureSubmissionTestResultViewModel(
				warnOthersReminder: WarnOthersReminder(store: self.store), testResult: testResult,
				exposureSubmissionService: MockExposureSubmissionService(),
				onContinueWithSymptomsFlowButtonTap: { _ in },
				onContinueWithoutSymptomsFlowButtonTap: { _ in
					onContinueWithoutSymptomsFlowButtonTapExpectation.fulfill()
				},
				onTestDeleted: { },
				onSubmissionConsentButtonTap: { _ in }
			)
			
			XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
			
			model.didTapSecondaryButton()
			
			XCTAssertFalse(model.shouldShowDeletionConfirmationAlert)
			
			waitForExpectations(timeout: .short)
		}
	}
	
	func testDidTapSecondaryButtonOnPositiveTestResultUpdatesButtonsLoadingStateTrue() {
		let onContinueWithoutSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithoutSymptomsFlowButtonTap closure is called"
		)
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .positive,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { isLoading in
				isLoading(true)
				
				onContinueWithoutSymptomsFlowButtonTapExpectation.fulfill()
			},
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		model.didTapSecondaryButton()
		
		waitForExpectations(timeout: .short)
		
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonEnabled)
		XCTAssertTrue(model.navigationFooterItem.isSecondaryButtonLoading)
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonEnabled)
	}
	
	func testDidTapSecondaryButtonOnPositiveTestResultUpdatesButtonsLoadingStateFalse() {
		let onContinueWithoutSymptomsFlowButtonTapExpectation = expectation(
			description: "onContinueWithoutSymptomsFlowButtonTap closure is not called"
		)
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .positive,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { isLoading in
				isLoading(true)
				isLoading(false)
				
				onContinueWithoutSymptomsFlowButtonTapExpectation.fulfill()
			},
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		model.didTapSecondaryButton()
		
		waitForExpectations(timeout: .short)
		
		XCTAssertTrue(model.navigationFooterItem.isSecondaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonEnabled)
	}
	
	func testDeletion() {
		let serviceDeleteTestCalledExpectation = expectation(description: "deleteTest on exposure submission service is called")
		
		let exposureSubmissionService = MockExposureSubmissionService()
		exposureSubmissionService.deleteTestCallback = { serviceDeleteTestCalledExpectation.fulfill() }
		
		let onTestDeletedCalledExpectation = expectation(description: "onTestDeleted closure is called")
		
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .expired,
			exposureSubmissionService: exposureSubmissionService,
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: {
				onTestDeletedCalledExpectation.fulfill()
			},
			onSubmissionConsentButtonTap: { _ in }
		)
		
		model.deleteTest()
		
		waitForExpectations(timeout: .short)
	}
	
	func testNavigationFooterItemForPendingTestResult() {
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .pending,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonHidden)
		
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isSecondaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonHidden)
		XCTAssertFalse(model.navigationFooterItem.secondaryButtonHasBorder)
	}
	
	func testNavigationFooterItemForPositiveTestResult() {
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .positive,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonHidden)
		
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonLoading)
		XCTAssertTrue(model.navigationFooterItem.isSecondaryButtonEnabled)
		XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonHidden)
		XCTAssertTrue(model.navigationFooterItem.secondaryButtonHasBorder)
	}
	
	func testNavigationFooterItemForNegaitveInvalidOrExpiredTestResult() {
		let testResults: [TestResult] = [.negative, .invalid, .expired]
		for testResult in testResults {
			let model = ExposureSubmissionTestResultViewModel(
				warnOthersReminder: WarnOthersReminder(store: self.store), testResult: testResult,
				exposureSubmissionService: MockExposureSubmissionService(),
				onContinueWithSymptomsFlowButtonTap: { _ in },
				onContinueWithoutSymptomsFlowButtonTap: { _ in },
				onTestDeleted: { },
				onSubmissionConsentButtonTap: { _ in }
			)
			
			XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonLoading)
			XCTAssertTrue(model.navigationFooterItem.isPrimaryButtonEnabled)
			XCTAssertFalse(model.navigationFooterItem.isPrimaryButtonHidden)
			
			XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonLoading)
			XCTAssertFalse(model.navigationFooterItem.isSecondaryButtonEnabled)
			XCTAssertTrue(model.navigationFooterItem.isSecondaryButtonHidden)
			XCTAssertFalse(model.navigationFooterItem.secondaryButtonHasBorder)
		}
	}
	
	func testDynamicTableViewModelForPositiveTestResult() {
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .positive,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 1)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 3)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
	}
	
	func testDynamicTableViewModelForNegativeTestResult() {
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .negative,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 1)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 9)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let fourthItem = cells[3]
		id = fourthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let fifthItem = cells[4]
		id = fifthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let sixthItem = cells[5]
		id = sixthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "bulletPointCell")
		
		let seventhItem = cells[6]
		id = seventhItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "bulletPointCell")
		
		let eigthItem = cells[7]
		id = eigthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "bulletPointCell")
		
		let ninthItem = cells[8]
		id = ninthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "bulletPointCell")
	}
	
	func testDynamicTableViewModelForInvalidTestResult() {
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .invalid,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 1)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 4)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let fourthItem = cells[3]
		id = fourthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
	}
	
	func testDynamicTableViewModelForPendingTestResult() {
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .pending,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 2)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 3)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let section2 = model.dynamicTableViewModel.section(1)
		let iconCell = section2.cells
		XCTAssertEqual(iconCell.count, 1)
		
		let iconCellFirstItem = iconCell[0]
		let iconId = iconCellFirstItem.cellReuseIdentifier
		XCTAssertEqual(iconId.rawValue, "iconCell")
	}
	
	func testDynamicTableViewModelForExpiredTestResult() {
		let model = ExposureSubmissionTestResultViewModel(
			warnOthersReminder: WarnOthersReminder(store: self.store), testResult: .invalid,
			exposureSubmissionService: MockExposureSubmissionService(),
			onContinueWithSymptomsFlowButtonTap: { _ in },
			onContinueWithoutSymptomsFlowButtonTap: { _ in },
			onTestDeleted: { },
			onSubmissionConsentButtonTap: { _ in }
		)
		
		XCTAssertEqual(model.dynamicTableViewModel.numberOfSection, 1)
		XCTAssertNotNil(model.dynamicTableViewModel.section(0).header)
		
		let section = model.dynamicTableViewModel.section(0)
		let cells = section.cells
		XCTAssertEqual(cells.count, 4)
		
		let firstItem = cells[0]
		var id = firstItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "labelCell")
		
		let secondItem = cells[1]
		id = secondItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let thirdItem = cells[2]
		id = thirdItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
		
		let fourthItem = cells[3]
		id = fourthItem.cellReuseIdentifier
		XCTAssertEqual(id.rawValue, "stepCell")
	}
	
}

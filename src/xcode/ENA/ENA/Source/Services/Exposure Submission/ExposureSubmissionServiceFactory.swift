//
// 🦠 Corona-Warn-App
//

import Foundation

enum ExposureSubmissionServiceFactory {

	/// Will return a mock service in UI tests if and only if the .useMock parameter is passed to the application.
	/// If the parameter is _not_ provided, the factory will instantiate a regular ENAExposureSubmissionService.
	static func create(diagnosiskeyRetrieval: DiagnosisKeysRetrieval, client: Client, store: Store) -> ExposureSubmissionService {
		#if DEBUG
		if isUITesting {
			guard isEnabled(.useMock) else {
				return ENAExposureSubmissionService(
					diagnosiskeyRetrieval: diagnosiskeyRetrieval,
					client: client,
					store: store
				)
			}

			let service = MockExposureSubmissionService()

			if isEnabled(.getRegistrationTokenSuccess) {
				service.getRegistrationTokenCallback = { _, completeWith in
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						completeWith(.success("dummyRegToken"))
					}
				}
			}

			if isEnabled(.submitExposureSuccess) {
				service.submitExposureCallback = { _, _, completeWith in
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						completeWith(nil)
					}
				}
			}

			return service
		}
		#endif

		let service = ENAExposureSubmissionService(
			diagnosiskeyRetrieval: diagnosiskeyRetrieval,
			client: client,
			store: store
		)

		return service
	}

	private static func isEnabled(_ parameter: UITestingParameters.ExposureSubmission) -> Bool {
		return ProcessInfo.processInfo.arguments.contains(parameter.rawValue)
	}

}

//
// 🦠 Corona-Warn-App
//

import XCTest
@testable import ENA

final class CachedAppConfigurationTests: XCTestCase {

	func testCachedRequests() {

		let fetchedFromClientExpectation = expectation(description: "configuration fetched from client")
		// we trigger a config fetch twice but expect only one http request (plus one cached result)
		fetchedFromClientExpectation.expectedFulfillmentCount = 1
		fetchedFromClientExpectation.assertForOverFulfill = true

		let store = MockTestStore()
		XCTAssertNil(store.appConfigMetadata)

		let client = CachingHTTPClientMock(store: store)
		let expectedConfig = SAP_Internal_ApplicationConfiguration()
		client.onFetchAppConfiguration = { _, completeWith in
			let config = AppConfigurationFetchingResponse(expectedConfig, "etag")
			completeWith((.success(config), nil))
			fetchedFromClientExpectation.fulfill()
		}

		let configurationDidChangeExpectation = expectation(description: "Configuration did change")
		configurationDidChangeExpectation.expectedFulfillmentCount = 1
		configurationDidChangeExpectation.assertForOverFulfill = true

		let cache = CachedAppConfiguration(client: client, store: store, configurationDidChange: {
			configurationDidChangeExpectation.fulfill()
		})

		let completionExpectation = expectation(description: "app configuration completion called")
		completionExpectation.expectedFulfillmentCount = 2
		cache.appConfiguration { response in
			switch response {
			case .success(let config):
				XCTAssertEqual(config, expectedConfig)
			case .failure(let error):
				XCTFail(error.localizedDescription)
			}
			completionExpectation.fulfill()
		}

		XCTAssertNotNil(store.appConfigMetadata)

		// Should not trigger another call (expectation) to the actual client or a new risk calculation
		// Remember: `expectedFulfillmentCount = 1`
		cache.appConfiguration { response in
			switch response {
			case .success(let config):
				XCTAssertEqual(config, expectedConfig)
				XCTAssertEqual(config, store.appConfigMetadata?.appConfig)
			case .failure(let error):
				XCTFail(error.localizedDescription)
			}
			completionExpectation.fulfill()
		}

		waitForExpectations(timeout: .medium)
	}

	func testCacheDecay() throws {
		let outdatedConfig = SAP_Internal_ApplicationConfiguration()
		let updatedConfigMetaData = CachingHTTPClientMock.staticAppConfigMetadata

		let store = MockTestStore()
		let appConfigMetadata = AppConfigMetadata(
			lastAppConfigETag: "\"OldETag\"",
			lastAppConfigFetch: 297.secondsAgo ?? Date(), // close to the assumed 300 seconds default decay
			appConfig: outdatedConfig
		)
		store.appConfigMetadata = appConfigMetadata

		let client = CachingHTTPClientMock(store: store)

		let lastFetch = try XCTUnwrap(store.appConfigMetadata?.lastAppConfigFetch)
		XCTAssertLessThan(Date().timeIntervalSince(lastFetch), 300)

		let fetchedFromClientExpectation = expectation(description: "configuration fetched from client")
		fetchedFromClientExpectation.expectedFulfillmentCount = 1
		fetchedFromClientExpectation.assertForOverFulfill = true

		client.onFetchAppConfiguration = { _, completeWith in
			store.appConfigMetadata = updatedConfigMetaData

			let config = AppConfigurationFetchingResponse(updatedConfigMetaData.appConfig, "\"NewETag\"")
			completeWith((.success(config), nil))
			fetchedFromClientExpectation.fulfill()
		}

		let completionExpectation = expectation(description: "app configuration completion called")
		completionExpectation.expectedFulfillmentCount = 2

		let configurationDidChangeExpectation = expectation(description: "Configuration did change")
		configurationDidChangeExpectation.expectedFulfillmentCount = 1
		configurationDidChangeExpectation.assertForOverFulfill = true

		let cache = CachedAppConfiguration(client: client, store: store, configurationDidChange: {
			configurationDidChangeExpectation.fulfill()
		})

		cache.appConfiguration { response in
			switch response {
			case .success(let config):
				XCTAssertEqual(config, outdatedConfig)
			case .failure(let error):
				XCTFail(error.localizedDescription)
			}
			completionExpectation.fulfill()
		}

		XCTAssertEqual(store.appConfigMetadata?.appConfig, outdatedConfig)

		// ensure cache decay
		sleep(5)
		XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(lastFetch), 300)

		// second fetch – expected decayed cache and updated config
		cache.appConfiguration { response in
			switch response {
			case .success(let config):
				XCTAssertEqual(config, updatedConfigMetaData.appConfig)
				XCTAssertEqual(config, store.appConfigMetadata?.appConfig)
			case .failure(let error):
				XCTFail(error.localizedDescription)
			}
			completionExpectation.fulfill()
		}

		waitForExpectations(timeout: 10)
	}

	func testFetch_nothingCached() throws {
		let store = MockTestStore()
		store.appConfigMetadata = nil

		let client = CachingHTTPClientMock(store: store)

		let completionExpectation = expectation(description: "app configuration completion called")

		let configurationDidChangeExpectation = expectation(description: "Configuration did change")
		configurationDidChangeExpectation.expectedFulfillmentCount = 1
		configurationDidChangeExpectation.assertForOverFulfill = true

		let cache = CachedAppConfiguration(client: client, store: store, configurationDidChange: {
			configurationDidChangeExpectation.fulfill()
		})

		cache.appConfiguration { response in
			XCTAssertNotNil(store.appConfigMetadata)

			switch response {
			case .success(let config):
				XCTAssertTrue(config.isInitialized)
			case .failure(let error):
				XCTFail("Expected no error, got: \(error)")
			}
			completionExpectation.fulfill()
		}

		waitForExpectations(timeout: .medium)
	}

	func testCacheExpired_invalidCache() throws {
		let fetchedFromClientExpectation = expectation(description: "configuration fetched from client")
		fetchedFromClientExpectation.expectedFulfillmentCount = 1

		let store = MockTestStore()
		store.appConfigMetadata = CachingHTTPClientMock.staticAppConfigMetadata

		let client = CachingHTTPClientMock(store: store)
		client.onFetchAppConfiguration = { _, completeWith in
			let config = CachingHTTPClientMock.staticAppConfig
			let response = AppConfigurationFetchingResponse(config, "etag_2")
			completeWith((.success(response), nil))
			fetchedFromClientExpectation.fulfill()
		}

		let completionExpectation = expectation(description: "app configuration completion called")

		let configurationDidChangeExpectation = expectation(description: "Configuration did not change")

		let cache = CachedAppConfiguration(client: client, store: store, configurationDidChange: {
			configurationDidChangeExpectation.fulfill()
		})

		cache.appConfiguration { response in
			switch response {
			case .success(let config):
				XCTAssertEqual(config, store.appConfigMetadata?.appConfig)
				XCTAssertEqual("etag_2", store.appConfigMetadata?.lastAppConfigETag)
			case .failure(let error):
				XCTFail("Expected no error, got: \(error)")
			}
			completionExpectation.fulfill()
		}

		waitForExpectations(timeout: .medium)
	}

	func testCacheNotModfied_useCache() throws {
		let fetchedFromClientExpectation = expectation(description: "configuration fetched from client")
		fetchedFromClientExpectation.expectedFulfillmentCount = 1

		let store = MockTestStore()
		store.appConfigMetadata = CachingHTTPClientMock.staticAppConfigMetadata

		let client = CachingHTTPClientMock(store: store)
		client.onFetchAppConfiguration = { _, completeWith in
			completeWith((.failure(CachedAppConfiguration.CacheError.notModified), nil))
			fetchedFromClientExpectation.fulfill()
		}

		let completionExpectation = expectation(description: "app configuration completion called")

		let configurationDidChangeExpectation = expectation(description: "Configuration did not change")
		configurationDidChangeExpectation.isInverted = true

		let cache = CachedAppConfiguration(client: client, store: store, configurationDidChange: {
			configurationDidChangeExpectation.fulfill()
		})

		cache.appConfiguration { response in
			switch response {
			case .success(let config):
				XCTAssertEqual(config, store.appConfigMetadata?.appConfig)
				XCTAssertEqual("\"SomeETag\"", store.appConfigMetadata?.lastAppConfigETag)
			case .failure(let error):
				XCTFail("Expected no error, got: \(error)")
			}
			completionExpectation.fulfill()
		}

		waitForExpectations(timeout: .medium)
	}

	func testCacheNotModfied_nothingCached() throws {
		let fetchedFromClientExpectation = expectation(description: "configuration fetched from client")
		// 1. on init
		// 2. on `cache.appConfiguration` because of no config in store
		fetchedFromClientExpectation.expectedFulfillmentCount = 2

		let store = MockTestStore()
		XCTAssertNil(store.appConfigMetadata)

		let client = CachingHTTPClientMock(store: store)
		client.onFetchAppConfiguration = { _, completeWith in
			XCTAssertNil(store.appConfigMetadata)

			completeWith((.failure(CachedAppConfiguration.CacheError.notModified), nil))
			fetchedFromClientExpectation.fulfill()
		}

		let completionExpectation = expectation(description: "app configuration completion called")

		let configurationDidChangeExpectation = expectation(description: "Configuration did not change")
		configurationDidChangeExpectation.isInverted = true

		let cache = CachedAppConfiguration(client: client, store: store, configurationDidChange: {
			configurationDidChangeExpectation.fulfill()
		})

		cache.appConfiguration { response in
			XCTAssertNil(store.appConfigMetadata)

			switch response {
			case .success:
				XCTFail("expected to fail")
			case .failure(let error):
				let err = error as? CachedAppConfiguration.CacheError
				if case .notModified = err {
					XCTAssert(true)
					// we exprect the .notModified error
					// Tip: you should remove the `lastETag` from the store in this case
				} else {
					XCTFail("wrong error type; got: \(error)")
				}
			}
			completionExpectation.fulfill()
		}

		waitForExpectations(timeout: .medium)
	}

}

extension Int {

	/// A date n seconds ago
	var secondsAgo: Date? {
		let components = DateComponents(second: -(self))
		return Calendar.autoupdatingCurrent.date(byAdding: components, to: Date())
	}

}

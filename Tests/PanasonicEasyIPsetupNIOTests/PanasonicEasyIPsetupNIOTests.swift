import XCTest
@testable import PanasonicEasyIPsetupNIO

import NetUtils
import Dispatch

final class PanasonicEasyIPsetupNIOTests: XCTestCase {
	
    func testExample() throws {
		let semaphore = DispatchSemaphore(value: 0)
		let manager = Manager { configuration in
			print(configuration)
			semaphore.signal()
		}
		
		let channel = try manager.communicationChannel.wait()
		semaphore.wait()
		
		channel.close().whenSuccess{
			print("channel closed")
		}
	}


    static var allTests = [
        ("testExample", testExample),
    ]
}

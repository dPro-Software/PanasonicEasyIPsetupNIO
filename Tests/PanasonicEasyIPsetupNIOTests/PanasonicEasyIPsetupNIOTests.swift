import XCTest
@testable import PanasonicEasyIPsetupNIO

import NetUtils
import PanasonicEasyIPsetupCore
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

	func testReconfiguration() throws {
		let semaphore = DispatchSemaphore(value: 0)
		var macAddress = [UInt8]()
		let manager = Manager { configuration in
			macAddress = configuration.macAddress
			semaphore.signal()
		}
		
		let channel = try manager.communicationChannel.wait()
		semaphore.wait()
		
		manager.set(configuration: CameraConfiguration(macAddress: macAddress, ipV4address: [10, 1, 0, 215], netmask: [255, 255, 255, 0], gateway: [10, 1, 0, 1], primaryDNS: [0, 0, 0, 0], secondaryDNS: [0, 0, 0, 0], port: 80, model: "", name: ""))
		
		channel.close().whenSuccess{
			print("channel closed")
		}
	}

    static var allTests = [
        ("testExample", testExample),
    ]
}

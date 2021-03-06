//
//  Manager.swift
//  PanasonicEasyIPsetupNIO
//
//  Created by Damiaan on 10/04/18.
//

import NIO
import PanasonicEasyIPsetupCore
import NetUtils

private let 🔂 = MultiThreadedEventLoopGroup(numThreads: 1)
let cameraBroadcast = try! SocketAddress(ipAddress: "255.255.255.255", port: 10670)

public class Manager {
	
	let communicationChannel: EventLoopFuture<Channel>
	public private (set) var foundCameras = Set<CameraConfiguration>()
	let discoveryHandler: DiscoveryHandler
	
	public init(discoveryHandler: @escaping DiscoveryHandler) {
		self.discoveryHandler = discoveryHandler
		
		let parser = ConfigurationParser()
		let bootstrap = DatagramBootstrap(group: 🔂)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_BROADCAST), value: 1)
			.channelInitializer {$0.pipeline.add(handler: parser)}
		
		communicationChannel = bootstrap
			.bind(host: "0.0.0.0", port: 10669)
		
		parser.discoveryHandler = self.saveCamera
		
		communicationChannel.whenSuccess { channel in
			Manager.sendDiscoveryRequest(on: channel)
		}
	}
	
	func saveCamera(configuration: CameraConfiguration) {
		if foundCameras.insert(configuration).inserted {
			discoveryHandler(configuration)
		}
	}
	
	public func searchCameras() {
		foundCameras.removeAll(keepingCapacity: true)
		communicationChannel.whenSuccess{
			Manager.sendDiscoveryRequest(on: $0)
		}
	}
	
	public func set(configuration: CameraConfiguration) {
		let address = Interface.allInterfaces()
			.filter {$0.family == .ipv4 && $0.broadcastAddress != nil}
			.compactMap { $0.addressBytes }
			.first ?? [10, 1, 0, 5]
		let request = configuration.reconfigurationRequest(sourceMacAddress: [2,0,0,0,0,0], sourceIpAddress: address)
		communicationChannel.whenSuccess{
			var buffer = $0.allocator.buffer(capacity: request.count)
			buffer.write(bytes: request)
			$0.writeAndFlush(AddressedEnvelope(remoteAddress: cameraBroadcast, data: buffer))
				.whenFailure { error in
					print(error)
				}
		}
	}
	
	static func sendDiscoveryRequest(on channel: Channel) {
		print("writable", channel.isWritable)
		let addresses = Interface
			.allInterfaces()
			.filter {$0.family == .ipv4 && $0.broadcastAddress != nil}
			.compactMap { $0.addressBytes }
		
		for address in addresses {
			let request = CameraConfiguration.discoveryRequest(from: [2,0,0,0,0,0], ipV4address: address)
			var buffer = channel.allocator.buffer(capacity: request.count)
			buffer.write(bytes: request)
			let write = channel.write(
				AddressedEnvelope(
					remoteAddress: cameraBroadcast,
					data: buffer
				)
			)
			write.whenFailure{
				print("unable to send", $0)
			}
			channel.flush()
		}
	}
	
	static func shutdown() {
		🔂.shutdownGracefully { error in
			if let error = error {
				print("Error while shutting down", error)
			} else {
				print("manager closing")
			}
		}
	}
}

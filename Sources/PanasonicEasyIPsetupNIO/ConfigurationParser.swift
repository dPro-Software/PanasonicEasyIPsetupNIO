import NIO
import PanasonicEasyIPsetupCore

public typealias DiscoveryHandler = (CameraConfiguration) -> Void

final class ConfigurationParser: ChannelInboundHandler {
	typealias   InboundIn = AddressedEnvelope<ByteBuffer>
	typealias OutboundOut = AddressedEnvelope<ByteBuffer>
	
	var discoveryHandler: DiscoveryHandler?
	
	func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
		var envelope = unwrapInboundIn(data)
		do {
			let datagram = envelope.data.readBytes(length: envelope.data.readableBytes) ?? []			
			discoveryHandler?(try CameraConfiguration(datagram: datagram))
		} catch {
			print("Ignoring incoming message: ")
			print(error)
		}
	}
}

import Darwin
import os.log

private let log = Logger(subsystem: logSubsystem, category: #fileID)

@_cdecl("my_connect")
func my_connect(socket: Int32, address: UnsafePointer<sockaddr>, addressLen: socklen_t) -> Int32 {
    log.debug("connect() called")
    
    if address.pointee.sa_family == sa_family_t(AF_INET), addressLen >= socklen_t(MemoryLayout<sockaddr_in>.size) {
        var modifiedAddr = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
        let originalPort = UInt16(bigEndian: modifiedAddr.sin_port)
        log.debug("connect() called with port \(originalPort)")
        
        if let targetPort = portMap?[originalPort] {
            log.info("Rewriting connect port \(originalPort) -> \(targetPort)")
            modifiedAddr.sin_port = UInt16(targetPort).bigEndian
            
            return withUnsafePointer(to: &modifiedAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    connect(socket, $0, addressLen)
                }
            }
        }
    }
    
    return connect(socket, address, addressLen)
}

@_cdecl("my_bind")
func my_bind(socket: Int32, address: UnsafePointer<sockaddr>, addressLen: socklen_t) -> Int32 {
    log.debug("In bind")

    if address.pointee.sa_family == sa_family_t(AF_INET), addressLen >= socklen_t(MemoryLayout<sockaddr_in>.size) {
        var modifiedAddr = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
        let originalPort = UInt16(bigEndian: modifiedAddr.sin_port)
        log.debug("bind() called with port \(originalPort)")

        if let targetPort: UInt16 = portMap?[originalPort] {
            log.info("Rewriting bind port \(originalPort) -> \(targetPort)")
            modifiedAddr.sin_port = UInt16(targetPort).bigEndian
            
            return withUnsafePointer(to: &modifiedAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    bind(socket, $0, addressLen)
                }
            }
        }
    }
    
    return bind(socket, address, addressLen)
}

import CoreAudio
import CoreMediaIO

/// True while any app holds a running microphone or camera. Queries the "running somewhere"
/// device property, which needs no camera or microphone permission.
enum CallMonitor {
    static var isActive: Bool { microphoneIsRunning || cameraIsRunning }

    private static var microphoneIsRunning: Bool {
        audioDevices().contains { hasAudioInput($0) && audioFlag($0, kAudioDevicePropertyDeviceIsRunningSomewhere) }
    }

    private static var cameraIsRunning: Bool {
        cameraDevices().contains { cameraFlag($0, CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere)) }
    }

    private static func audioAddress(
        _ selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    private static func audioDevices() -> [AudioObjectID] {
        let system = AudioObjectID(kAudioObjectSystemObject)
        var address = audioAddress(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var devices = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &devices) == noErr else { return [] }
        return devices
    }

    private static func hasAudioInput(_ device: AudioObjectID) -> Bool {
        var address = audioAddress(kAudioDevicePropertyStreams, scope: kAudioObjectPropertyScopeInput)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr && size > 0
    }

    private static func audioFlag(_ device: AudioObjectID, _ selector: AudioObjectPropertySelector) -> Bool {
        var address = audioAddress(selector)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        return AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr && value != 0
    }

    private static func cameraAddress(_ selector: CMIOObjectPropertySelector) -> CMIOObjectPropertyAddress {
        CMIOObjectPropertyAddress(
            mSelector: selector,
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
    }

    private static func cameraDevices() -> [CMIOObjectID] {
        let system = CMIOObjectID(kCMIOObjectSystemObject)
        var address = cameraAddress(CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices))
        var size: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var devices = [CMIOObjectID](repeating: 0, count: Int(size) / MemoryLayout<CMIOObjectID>.size)
        var used: UInt32 = 0
        guard CMIOObjectGetPropertyData(system, &address, 0, nil, size, &used, &devices) == noErr else { return [] }
        return devices
    }

    private static func cameraFlag(_ device: CMIOObjectID, _ selector: CMIOObjectPropertySelector) -> Bool {
        var address = cameraAddress(selector)
        var value: UInt32 = 0
        var used: UInt32 = 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        return CMIOObjectGetPropertyData(device, &address, 0, nil, size, &used, &value) == noErr && value != 0
    }
}

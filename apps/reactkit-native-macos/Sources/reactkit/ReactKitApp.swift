import AppKit
import Foundation
import SwiftUI

@main
struct ReactNativeKitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 1180, minHeight: 760)
                .background(DesignColor.canvas)
                .task {
                    model.start()
                }
                .onDisappear {
                    model.stop()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        ProcessInfo.processInfo.setValue("ReactNativeKit", forKey: "processName")
        NSApp.applicationIconImage = loadDockIcon() ?? makeFallbackDockIcon()
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func loadDockIcon() -> NSImage? {
        let fileManager = FileManager.default
        if let bundledIconURL = Bundle.main.url(forResource: "ReactKit", withExtension: "icns"),
           let image = NSImage(contentsOf: bundledIconURL) {
            return image
        }

        let current = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let candidates = [
            current,
            current.deletingLastPathComponent(),
            current.deletingLastPathComponent().deletingLastPathComponent(),
            current.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
        ]

        for candidate in candidates {
            let iconURL = candidate
                .appending(path: "apps")
                .appending(path: "reactkit-native-macos")
                .appending(path: "ReactKit.icns")
            if let image = NSImage(contentsOf: iconURL) {
                return image
            }

            let localIconURL = candidate.appending(path: "ReactKit.icns")
            if let image = NSImage(contentsOf: localIconURL) {
                return image
            }
        }

        return nil
    }

    private func makeFallbackDockIcon() -> NSImage {
        let size = NSSize(width: 256, height: 256)
        let image = NSImage(size: size)
        image.lockFocus()

        NSColor(red: 0.071, green: 0.067, blue: 0.059, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 18, y: 18, width: 220, height: 220), xRadius: 56, yRadius: 56).fill()

        if let symbol = NSImage(systemSymbolName: "atom", accessibilityDescription: "ReactKit") {
            symbol.withSymbolConfiguration(.init(pointSize: 126, weight: .bold))?
                .draw(
                    in: NSRect(x: 65, y: 65, width: 126, height: 126),
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1
                )
        }

        NSColor(red: 0.910, green: 0.373, blue: 0.271, alpha: 1).setStroke()
        let ring = NSBezierPath(ovalIn: NSRect(x: 74, y: 74, width: 108, height: 108))
        ring.lineWidth = 9
        ring.stroke()

        image.unlockFocus()
        return image
    }
}

enum DesignColor {
    static let canvas = Color(red: 0.969, green: 0.965, blue: 0.949)
    static let surface = Color(red: 0.996, green: 0.992, blue: 0.984)
    static let surfaceSoft = Color(red: 0.982, green: 0.976, blue: 0.960)
    static let border = Color(red: 0.871, green: 0.863, blue: 0.843)
    static let primary = Color(red: 0.071, green: 0.067, blue: 0.059)
    static let secondary = Color(red: 0.522, green: 0.510, blue: 0.486)
    static let muted = Color(red: 0.706, green: 0.694, blue: 0.671)
    static let accent = Color(red: 0.910, green: 0.373, blue: 0.271)
    static let accentSoft = Color(red: 0.984, green: 0.909, blue: 0.894)
    static let success = Color(red: 0.184, green: 0.620, blue: 0.392)
    static let warning = Color(red: 0.851, green: 0.604, blue: 0.133)
}

struct SoftRoundedSurface: ViewModifier {
    var radius: CGFloat
    var shadowRadius: CGFloat = 18
    var shadowY: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .background(DesignColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(DesignColor.surface.opacity(0.96), lineWidth: 1)
            )
            .shadow(color: DesignColor.primary.opacity(0.055), radius: shadowRadius, x: 0, y: shadowY)
            .shadow(color: DesignColor.primary.opacity(0.025), radius: 3, x: 0, y: 1)
    }
}

struct SoftCapsuleSurface: ViewModifier {
    var shadowRadius: CGFloat = 12
    var shadowY: CGFloat = 5

    func body(content: Content) -> some View {
        content
            .background(DesignColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(DesignColor.surface.opacity(0.96), lineWidth: 1))
            .shadow(color: DesignColor.primary.opacity(0.055), radius: shadowRadius, x: 0, y: shadowY)
            .shadow(color: DesignColor.primary.opacity(0.025), radius: 2, x: 0, y: 1)
    }
}

extension View {
    func softRoundedSurface(radius: CGFloat, shadowRadius: CGFloat = 18, shadowY: CGFloat = 8) -> some View {
        modifier(SoftRoundedSurface(radius: radius, shadowRadius: shadowRadius, shadowY: shadowY))
    }

    func softCapsuleSurface(shadowRadius: CGFloat = 12, shadowY: CGFloat = 5) -> some View {
        modifier(SoftCapsuleSurface(shadowRadius: shadowRadius, shadowY: shadowY))
    }

    func flatCapsuleSurface() -> some View {
        background(DesignColor.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(DesignColor.surface.opacity(0.96), lineWidth: 1))
    }
}

struct LucideIcon: View {
    enum Name {
        case menu
        case clipboardList
        case smartphone
        case phoneOff
        case wandSparkles
        case search
        case listFilter
        case arrowDown
        case pause
        case play
        case trash
        case chevronDown
        case chevronRight
        case chevronUp
        case network
        case activity
        case list
    }

    var name: Name
    var size: CGFloat = 20
    var color: Color = DesignColor.primary
    var strokeWidth: CGFloat = 2

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / 24
            let offset = CGPoint(
                x: (canvasSize.width - 24 * scale) / 2,
                y: (canvasSize.height - 24 * scale) / 2
            )
            let stroke = StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)

            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: offset.x + x * scale, y: offset.y + y * scale)
            }

            func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
                CGRect(x: offset.x + x * scale, y: offset.y + y * scale, width: width * scale, height: height * scale)
            }

            func strokePath(_ path: Path) {
                context.stroke(path, with: .color(color), style: stroke)
            }

            func line(_ points: [CGPoint]) {
                guard let first = points.first else { return }
                var path = Path()
                path.move(to: first)
                points.dropFirst().forEach { path.addLine(to: $0) }
                strokePath(path)
            }

            func circle(centerX: CGFloat, centerY: CGFloat, radius: CGFloat) {
                strokePath(Path(ellipseIn: rect(centerX - radius, centerY - radius, radius * 2, radius * 2)))
            }

            func roundedRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, radius: CGFloat) {
                strokePath(Path(roundedRect: rect(x, y, width, height), cornerRadius: radius * scale))
            }

            switch name {
            case .menu:
                line([point(4, 7), point(20, 7)])
                line([point(4, 12), point(20, 12)])
                line([point(4, 17), point(20, 17)])
            case .clipboardList:
                roundedRect(6, 5, 12, 16, radius: 2)
                roundedRect(9, 3, 6, 4, radius: 1.6)
                line([point(9, 11), point(15, 11)])
                line([point(9, 15), point(15, 15)])
            case .smartphone:
                roundedRect(7, 2.5, 10, 19, radius: 2.2)
                line([point(11, 18), point(13, 18)])
            case .phoneOff:
                roundedRect(7, 2.5, 10, 19, radius: 2.2)
                line([point(11, 18), point(13, 18)])
                line([point(4, 4), point(20, 20)])
            case .wandSparkles:
                line([point(4, 20), point(14, 10)])
                line([point(12, 8), point(16, 12)])
                line([point(15.5, 3), point(15.5, 7)])
                line([point(13.5, 5), point(17.5, 5)])
                line([point(6, 5), point(6, 8)])
                line([point(4.5, 6.5), point(7.5, 6.5)])
                line([point(19, 14), point(19, 17)])
                line([point(17.5, 15.5), point(20.5, 15.5)])
            case .search:
                circle(centerX: 10.5, centerY: 10.5, radius: 6.5)
                line([point(15.5, 15.5), point(21, 21)])
            case .listFilter:
                line([point(4, 6), point(20, 6)])
                line([point(7, 12), point(17, 12)])
                line([point(10, 18), point(14, 18)])
            case .arrowDown:
                line([point(12, 4), point(12, 19)])
                line([point(6, 13), point(12, 19), point(18, 13)])
            case .pause:
                line([point(8, 6), point(8, 18)])
                line([point(16, 6), point(16, 18)])
            case .play:
                var path = Path()
                path.move(to: point(8, 5))
                path.addLine(to: point(19, 12))
                path.addLine(to: point(8, 19))
                path.closeSubpath()
                context.fill(path, with: .color(color))
            case .trash:
                line([point(3, 6), point(21, 6)])
                line([point(9, 6), point(9, 4), point(15, 4), point(15, 6)])
                roundedRect(6, 6, 12, 15, radius: 1.8)
                line([point(10, 10), point(10, 17)])
                line([point(14, 10), point(14, 17)])
            case .chevronDown:
                line([point(6, 9), point(12, 15), point(18, 9)])
            case .chevronRight:
                line([point(9, 6), point(15, 12), point(9, 18)])
            case .chevronUp:
                line([point(6, 15), point(12, 9), point(18, 15)])
            case .network:
                circle(centerX: 6, centerY: 7, radius: 2)
                circle(centerX: 18, centerY: 7, radius: 2)
                circle(centerX: 12, centerY: 18, radius: 2)
                line([point(8, 8.6), point(10.4, 15.8)])
                line([point(16, 8.6), point(13.6, 15.8)])
                line([point(8.2, 7), point(15.8, 7)])
            case .activity:
                line([point(4, 12), point(8, 12), point(10, 7), point(14, 17), point(16, 12), point(20, 12)])
            case .list:
                line([point(6, 8), point(18, 8)])
                line([point(6, 12), point(18, 12)])
                line([point(6, 16), point(18, 16)])
            }
        }
        .frame(width: size, height: size)
    }
}

struct StatusResponse: Codable {
    var ok: Bool
    var startedAt: String?
    var serverStatus: String
    var serverPort: Int
    var apiPort: Int
    var mcpStatus: String
    var mcpPort: Int
    var connectionCount: Int
    var totalKnownConnections: Int
    var logCount: Int
    var bufferLimit: Int
    var portUnavailable: Int?
}

struct ConnectionItem: Codable, Identifiable, Hashable {
    var id: Int
    var clientId: String
    var name: String
    var platform: String
    var platformVersion: String?
    var osRelease: String?
    var userAgent: String?
    var connected: Bool
    var lastSeenAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case clientId
        case name
        case platform
        case platformVersion
        case osRelease
        case userAgent
        case connected
        case lastSeenAt
    }

    init(
        id: Int,
        clientId: String,
        name: String,
        platform: String,
        platformVersion: String?,
        osRelease: String?,
        userAgent: String?,
        connected: Bool,
        lastSeenAt: String?
    ) {
        self.id = id
        self.clientId = clientId
        self.name = name
        self.platform = platform
        self.platformVersion = platformVersion
        self.osRelease = osRelease
        self.userAgent = userAgent
        self.connected = connected
        self.lastSeenAt = lastSeenAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        clientId = try container.decode(String.self, forKey: .clientId)
        name = try container.decode(String.self, forKey: .name)
        platform = try container.decode(String.self, forKey: .platform)
        platformVersion = try container.decodeFlexibleStringIfPresent(forKey: .platformVersion)
        osRelease = try container.decodeFlexibleStringIfPresent(forKey: .osRelease)
        userAgent = try container.decodeFlexibleStringIfPresent(forKey: .userAgent)
        connected = try container.decode(Bool.self, forKey: .connected)
        lastSeenAt = try container.decodeFlexibleStringIfPresent(forKey: .lastSeenAt)
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleStringIfPresent(forKey key: Key) throws -> String? {
        if try decodeNil(forKey: key) {
            return nil
        }
        if let string = try? decode(String.self, forKey: key) {
            return string
        }
        if let int = try? decode(Int.self, forKey: key) {
            return String(int)
        }
        if let double = try? decode(Double.self, forKey: key) {
            return String(double)
        }
        return nil
    }
}

struct ConnectionsResponse: Codable {
    var connections: [ConnectionItem]
}

struct LogEntry: Codable, Identifiable, Hashable {
    var messageId: Int
    var connectionId: Int
    var clientId: String?
    var type: String
    var important: Bool
    var date: String
    var deltaTime: Double
    var summary: String
    var details: String?

    var id: Int { messageId }
}

struct LogsResponse: Codable {
    var logs: [LogEntry]
}

struct AndroidReverseState: Sendable {
    var port: Int = 9091
    var devices: [String] = []
    var reversedDevices: [String] = []
    var message: String = "Android reverse starting"
    var isError: Bool = false
}

struct AndroidDevice: Sendable, Hashable {
    var id: String
    var state: String
}

final class AndroidReverseManager: @unchecked Sendable {
    private let queue = DispatchQueue(label: "reactkit.android-reverse")
    private var trackProcess: Process?
    private var port = 9091
    private var reversedPortsByDevice: [String: Int] = [:]
    private var onState: (@Sendable (AndroidReverseState) -> Void)?

    func start(port: Int, onState: @escaping @Sendable (AndroidReverseState) -> Void) {
        queue.async { [weak self] in
            guard let self else { return }
            self.port = port
            self.onState = onState
            self.emit(message: "Looking for Android devices")
            self.startTrackingDevices()
            self.refreshDevices()
        }
    }

    func update(port: Int) {
        queue.async { [weak self] in
            guard let self, self.port != port else { return }
            self.port = port
            self.reversedPortsByDevice.removeAll()
            self.refreshDevices()
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.trackProcess?.terminate()
            self.trackProcess = nil
            self.onState = nil
            self.reversedPortsByDevice.removeAll()
        }
    }

    private func startTrackingDevices() {
        if let trackProcess, trackProcess.isRunning {
            return
        }

        let process = Process()
        let adb = resolveADB()
        process.executableURL = adb.executableURL
        process.arguments = adb.arguments + ["track-devices"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let manager = self else { return }
            let output = String(data: handle.availableData, encoding: .utf8) ?? ""
            guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            manager.queue.async { [weak manager] in
                manager?.refreshDevices()
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let manager = self else { return }
            let error = String(data: handle.availableData, encoding: .utf8) ?? ""
            guard !error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            manager.queue.async { [weak manager] in
                manager?.emit(message: "adb device tracking failed: \(error.trimmingCharacters(in: .whitespacesAndNewlines))", isError: true)
            }
        }

        process.terminationHandler = { [weak self] _ in
            guard let manager = self else { return }
            manager.queue.async { [weak manager] in
                manager?.trackProcess = nil
            }
        }

        do {
            try process.run()
            trackProcess = process
        } catch {
            emit(message: "adb not available: \(error.localizedDescription)", isError: true)
        }
    }

    private func refreshDevices() {
        let result = runADB(["devices"])
        if result.exitCode != 0 {
            emit(message: "adb devices failed: \(result.message)", isError: true)
            return
        }
        handleDeviceListOutput(result.output)
    }

    private func handleDeviceListOutput(_ output: String) {
        let allDevices = parseDevices(output)
        let devices = allDevices.filter { $0.state == "device" }
        let deviceIds = devices.map(\.id)
        let activeDeviceSet = Set(deviceIds)

        reversedPortsByDevice = reversedPortsByDevice.filter { activeDeviceSet.contains($0.key) }

        guard !deviceIds.isEmpty else {
            reversedPortsByDevice.removeAll()
            let unavailableDevices = allDevices.filter { $0.state != "device" }
            if !unavailableDevices.isEmpty {
                let unavailableMessage = unavailableDevices
                    .map { "\($0.id) \($0.state)" }
                    .joined(separator: ", ")
                emit(
                    devices: unavailableDevices.map(\.id),
                    reversedDevices: [],
                    message: "Android device not ready: \(unavailableMessage)",
                    isError: true
                )
                return
            }
            emit(devices: [], reversedDevices: [], message: "No Android device detected")
            return
        }

        var failedMessages: [String] = []

        for deviceId in deviceIds where reversedPortsByDevice[deviceId] != port {
            let result = runADB(["-s", deviceId, "reverse", "tcp:\(port)", "tcp:\(port)"])
            if result.exitCode == 0 {
                reversedPortsByDevice[deviceId] = port
            } else {
                failedMessages.append("\(deviceId): \(result.message)")
            }
        }

        let reversedDevices = deviceIds.filter { reversedPortsByDevice[$0] == port }
        if !failedMessages.isEmpty {
            emit(
                devices: deviceIds,
                reversedDevices: reversedDevices,
                message: "Android reverse failed: \(failedMessages.joined(separator: "; "))",
                isError: true
            )
            return
        }

        let label = reversedDevices.count == 1 ? reversedDevices[0] : "\(reversedDevices.count) devices"
        emit(
            devices: deviceIds,
            reversedDevices: reversedDevices,
            message: "Android reverse ready on \(label)"
        )
    }

    private func parseDevices(_ output: String) -> [AndroidDevice] {
        output
            .components(separatedBy: .newlines)
            .compactMap { line in
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("List of devices") {
                    return nil
                }

                let parts = trimmed.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
                guard parts.count >= 2 else { return nil }
                return AndroidDevice(id: parts[0], state: parts[1])
            }
    }

    private func runADB(_ arguments: [String]) -> (exitCode: Int32, output: String, message: String) {
        let process = Process()
        let adb = resolveADB()
        process.executableURL = adb.executableURL
        process.arguments = adb.arguments + arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (1, "", error.localizedDescription)
        }

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let message = [output, error]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return (process.terminationStatus, output, message)
    }

    private func resolveADB() -> (executableURL: URL, arguments: [String]) {
        let fileManager = FileManager.default
        let environment = ProcessInfo.processInfo.environment
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        var candidates: [URL] = []

        for key in ["ANDROID_HOME", "ANDROID_SDK_ROOT"] {
            if let root = environment[key], !root.isEmpty {
                candidates.append(
                    URL(fileURLWithPath: root)
                        .appending(path: "platform-tools")
                        .appending(path: "adb")
                )
            }
        }

        candidates.append(
            homeDirectory
                .appending(path: "Library")
                .appending(path: "Android")
                .appending(path: "sdk")
                .appending(path: "platform-tools")
                .appending(path: "adb")
        )
        candidates.append(URL(fileURLWithPath: "/opt/homebrew/bin/adb"))
        candidates.append(URL(fileURLWithPath: "/usr/local/bin/adb"))

        for candidate in candidates where fileManager.isExecutableFile(atPath: candidate.path) {
            return (candidate, [])
        }

        return (URL(fileURLWithPath: "/usr/bin/env"), ["adb"])
    }

    private func emit(
        devices: [String]? = nil,
        reversedDevices: [String]? = nil,
        message: String,
        isError: Bool = false
    ) {
        let state = AndroidReverseState(
            port: port,
            devices: devices ?? Array(reversedPortsByDevice.keys).sorted(),
            reversedDevices: reversedDevices ?? reversedPortsByDevice.keys.sorted(),
            message: message,
            isError: isError
        )
        onState?(state)
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var status: StatusResponse?
    @Published var connections: [ConnectionItem] = []
    @Published var logs: [LogEntry] = []
    @Published var selectedClientId: String?
    @Published var searchText = ""
    @Published var isAutoRefreshPaused = false
    @Published var androidReverse = AndroidReverseState()
    @Published var lastError: String?

    private let api = BackendAPI()
    private let supervisor = BackendSupervisor()
    private let androidReverseManager = AndroidReverseManager()
    private var pollTask: Task<Void, Never>?

    var selectedConnection: ConnectionItem? {
        connections.first { $0.clientId == selectedClientId }
    }

    func start() {
        supervisor.start()
        androidReverseManager.start(port: androidReverse.port) { [weak self] state in
            Task { @MainActor in
                self?.androidReverse = state
            }
        }
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                if !self.isAutoRefreshPaused {
                    await self.refresh()
                }
                try? await Task.sleep(for: .milliseconds(1400))
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        androidReverseManager.stop()
        supervisor.stop()
    }

    func refresh() async {
        do {
            try await loadSnapshot()
            self.lastError = nil
        } catch {
            supervisor.start()
            try? await Task.sleep(for: .milliseconds(350))
            do {
                try await loadSnapshot()
                self.lastError = nil
            } catch {
                self.lastError = error.localizedDescription
            }
        }
    }

    private func loadSnapshot() async throws {
        let status = try await api.status()
        let connections = try await api.connections().connections

        self.status = status
        self.connections = connections
        androidReverseManager.update(port: status.serverPort)

        if status.mcpStatus != "started" {
            try? await api.startMcp()
        }

        if selectedClientId == nil || !connections.contains(where: { $0.clientId == selectedClientId }) {
            selectedClientId = connections.first(where: { $0.connected })?.clientId ?? connections.first?.clientId
        }

        let nextLogs = try await api.logs(clientId: selectedClientId, search: searchText)
        self.logs = nextLogs.logs
    }

    func selectConnection(_ connection: ConnectionItem) {
        selectedClientId = connection.clientId
        Task { await refresh() }
    }

    func clearLogs() {
        Task {
            do {
                logs = []
                lastError = nil
                try await api.clear(clientId: selectedClientId)
                await refresh()
            } catch {
                supervisor.start()
                try? await Task.sleep(for: .milliseconds(350))
                await refresh()
            }
        }
    }

    func applySearch() {
        Task { await refresh() }
    }
}

@MainActor
final class BackendAPI {
    private let baseURL: URL

    init() {
        let rawPort = ProcessInfo.processInfo.environment["REACTOTRON_NATIVE_API_PORT"]
        let port = Int(rawPort ?? "") ?? 3901
        baseURL = URL(string: "http://127.0.0.1:\(port)")!
    }

    func status() async throws -> StatusResponse {
        try await get("/status")
    }

    func connections() async throws -> ConnectionsResponse {
        try await get("/connections")
    }

    func logs(clientId: String?, search: String) async throws -> LogsResponse {
        var components = URLComponents(url: baseURL.appending(path: "logs"), resolvingAgainstBaseURL: false)!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: "500")]
        if let clientId, !clientId.isEmpty {
            queryItems.append(URLQueryItem(name: "clientId", value: clientId))
        }
        if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        components.queryItems = queryItems
        return try await request(components.url!, method: "GET")
    }

    func clear(clientId: String?) async throws {
        let url = baseURL.appending(path: "clear")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let clientId {
            request.httpBody = try JSONEncoder().encode(["clientId": clientId])
        }
        _ = try await URLSession.shared.data(for: request)
    }

    func startMcp() async throws {
        let url = baseURL.appending(path: "mcp/start")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        _ = try await URLSession.shared.data(for: request)
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await request(baseURL.appending(path: path), method: "GET")
    }

    private func request<T: Decodable>(_ url: URL, method: String) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

final class BackendSupervisor {
    private var process: Process?

    func start() {
        if let process {
            if process.isRunning {
                return
            }
            self.process = nil
        }

        let rootURL = resolveRootURL()
        let scriptURL = rootURL
            .appending(path: "apps")
            .appending(path: "reactkit-native-backend")
            .appending(path: "src")
            .appending(path: "index.js")

        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            return
        }

        let process = Process()
        let runtime = resolveRuntime()
        process.executableURL = runtime.executableURL
        process.arguments = runtime.arguments + [scriptURL.path]
        process.currentDirectoryURL = rootURL
        process.environment = ProcessInfo.processInfo.environment
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            self.process = process
        } catch {
            self.process = nil
        }
    }

    func stop() {
        guard let process else { return }
        if process.isRunning {
            process.terminate()
        }
        self.process = nil
    }

    private func resolveRuntime() -> (executableURL: URL, arguments: [String]) {
        if let resourceURL = Bundle.main.resourceURL {
            let bundledBunURL = Bundle.main.bundleURL
                .appending(path: "Contents")
                .appending(path: "MacOS")
                .appending(path: "bun")
            if FileManager.default.isExecutableFile(atPath: bundledBunURL.path) {
                return (bundledBunURL, [])
            }

            let resourceBunURL = resourceURL.appending(path: "bun")
            if FileManager.default.isExecutableFile(atPath: resourceBunURL.path) {
                return (resourceBunURL, [])
            }
        }

        return (URL(fileURLWithPath: "/usr/bin/env"), ["bun"])
    }

    private func resolveRootURL() -> URL {
        let fileManager = FileManager.default
        if let envRoot = ProcessInfo.processInfo.environment["REACTKIT_ROOT"] {
            return URL(fileURLWithPath: envRoot)
        }

        if let resourceURL = Bundle.main.resourceURL {
            let bundledBackend = resourceURL
                .appending(path: "apps")
                .appending(path: "reactkit-native-backend")
                .appending(path: "src")
                .appending(path: "index.js")
            if fileManager.fileExists(atPath: bundledBackend.path) {
                return resourceURL
            }
        }

        let current = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let candidates = [
            current,
            current.deletingLastPathComponent().deletingLastPathComponent(),
            current.deletingLastPathComponent(),
        ]

        for candidate in candidates {
            let backend = candidate
                .appending(path: "apps")
                .appending(path: "reactkit-native-backend")
                .appending(path: "src")
                .appending(path: "index.js")
            if fileManager.fileExists(atPath: backend.path) {
                return candidate
            }
        }

        return current
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            HeaderView()

            HStack(alignment: .top, spacing: 12) {
                ConnectionsPanel()
                    .frame(width: 220)

                TimelinePanel()
            }
        }
        .padding(20)
        .foregroundStyle(DesignColor.primary)
    }
}

struct HeaderView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)

                Text("RNKit")
                    .font(.system(size: 22, weight: .semibold))
                    .lineLimit(1)
            }
            .frame(minWidth: 190, alignment: .leading)

            Spacer()

            StatusPill(
                title: runtimeTitle,
                subtitle: "Runtime :\(model.status?.serverPort ?? 9091)",
                symbol: .activity,
                color: statusColor(model.status?.serverStatus)
            )
            .frame(width: 190)

            StatusPill(
                title: mcpTitle,
                subtitle: "MCP :\(model.status?.mcpPort ?? 4567)",
                symbol: .network,
                color: statusColor(model.status?.mcpStatus)
            )
            .frame(width: 170)
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .softCapsuleSurface(shadowRadius: 18, shadowY: 8)
    }

    private var runtimeTitle: String {
        switch model.status?.serverStatus {
        case "started": "Running"
        case "portUnavailable": "Port unavailable"
        case "starting": "Starting"
        case "stopping": "Stopping"
        case "stopped": "Stopped"
        default: "Starting"
        }
    }

    private var mcpTitle: String {
        switch model.status?.mcpStatus {
        case "started": "MCP running"
        case "error": "MCP error"
        case "starting": "MCP starting"
        case "stopping": "MCP stopping"
        case "stopped": "MCP stopped"
        default: "MCP starting"
        }
    }

    private func statusColor(_ status: String?) -> Color {
        switch status {
        case "started": DesignColor.success
        case "starting", "stopping": DesignColor.warning
        case "error", "portUnavailable": DesignColor.accent
        default: DesignColor.secondary
        }
    }
}

struct BrandMark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(DesignColor.primary)
            LucideIcon(name: .network, size: 32, color: DesignColor.accent, strokeWidth: 2)
        }
        .frame(width: 64, height: 64)
    }
}

struct StatusPill: View {
    var title: String
    var subtitle: String
    var symbol: LucideIcon.Name
    var color: Color

    var body: some View {
        HStack(spacing: 8) {
            LucideIcon(name: symbol, size: 24, color: color, strokeWidth: 2)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignColor.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(height: 48)
        .background(DesignColor.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(DesignColor.surface.opacity(0.96), lineWidth: 1))
    }
}

struct SearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            LucideIcon(name: .search, size: 24, color: DesignColor.primary, strokeWidth: 2)

            TextField("Search logs ...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(DesignColor.primary)
                .focused($isFocused)
        }
        .padding(.horizontal, 10)
        .frame(height: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
}

struct IconButton: View {
    var symbol: LucideIcon.Name
    var foreground: Color = DesignColor.primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            LucideIcon(name: symbol, size: 24, color: foreground, strokeWidth: 2)
                .frame(width: 56, height: 56)
                .background(DesignColor.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(DesignColor.surface.opacity(0.96), lineWidth: 1))
                .shadow(color: DesignColor.primary.opacity(0.055), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct TimelineActionButton: View {
    var title: String
    var symbol: LucideIcon.Name
    var foreground: Color = DesignColor.primary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                LucideIcon(name: symbol, size: 24, color: foreground, strokeWidth: 2)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .frame(height: 40)
            .flatCapsuleSurface()
        }
        .buttonStyle(.plain)
    }
}

struct ConnectionsPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connections")
                        .font(.system(size: 18, weight: .semibold))
                    Text("\(model.status?.connectionCount ?? 0) active, \(model.status?.logCount ?? 0) events")
                        .font(.system(size: 13))
                        .foregroundStyle(DesignColor.secondary)
                }
                Spacer()
                Circle()
                    .fill((model.status?.connectionCount ?? 0) > 0 ? DesignColor.success : DesignColor.muted)
                    .frame(width: 10, height: 10)
            }

            AndroidReverseCard(state: model.androidReverse)

            if model.connections.isEmpty {
                EmptyConnectionCard()
            } else {
                ForEach(model.connections) { connection in
                    ConnectionRow(
                        connection: connection,
                        isSelected: model.selectedClientId == connection.clientId
                    ) {
                        model.selectConnection(connection)
                    }
                }
            }

            Spacer()
        }
        .padding(18)
        .frame(maxHeight: .infinity)
        .softRoundedSurface(radius: 20, shadowRadius: 18, shadowY: 8)
    }
}

struct AndroidReverseCard: View {
    var state: AndroidReverseState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 8, height: 8)
                Text("Android reverse")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignColor.primary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(":\(state.port)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignColor.secondary)
                    .lineLimit(1)
            }

            Text(state.message)
                .font(.system(size: 12))
                .foregroundStyle(DesignColor.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var indicatorColor: Color {
        if state.isError {
            return DesignColor.accent
        }
        if !state.reversedDevices.isEmpty {
            return DesignColor.success
        }
        return DesignColor.muted
    }

    private var backgroundColor: Color {
        state.isError ? DesignColor.accentSoft.opacity(0.58) : DesignColor.surfaceSoft.opacity(0.62)
    }
}

struct EmptyConnectionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                LucideIcon(name: .phoneOff, size: 24, color: DesignColor.accent, strokeWidth: 2)
                    .frame(width: 36, height: 36)
                    .background(DesignColor.accentSoft)
                    .clipShape(Circle())

                Text("No app connected")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Text("Run your app with ReactNativeKit enabled.")
                .font(.system(size: 13))
                .foregroundStyle(DesignColor.secondary)
                .lineSpacing(3)
        }
        .padding(12)
        .background(DesignColor.surfaceSoft.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ConnectionRow: View {
    var connection: ConnectionItem
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                LucideIcon(name: .smartphone, size: 24, color: DesignColor.secondary, strokeWidth: 2)
                    .frame(width: 32, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(connection.connected ? DesignColor.success : DesignColor.muted)
                            .frame(width: 8, height: 8)

                        Text(connection.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignColor.primary)
                            .lineLimit(1)
                    }

                    Text("\(connection.platform.capitalized) \(connection.platformVersion ?? "")")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignColor.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? DesignColor.accentSoft.opacity(0.82) : DesignColor.surfaceSoft.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct PortRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(DesignColor.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
    }
}

struct TimelinePanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Timeline")
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)
                    Text(timelineSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(DesignColor.secondary)
                        .lineLimit(1)
                    Spacer()
                }

                HStack(spacing: 8) {
                    SearchField(text: $model.searchText)
                        .frame(minWidth: 260, maxWidth: 420)
                        .onSubmit {
                            model.applySearch()
                        }

                    FilterPill(title: "All", symbol: .listFilter)
                    FilterPill(title: "Newest", symbol: .arrowDown)

                    TimelineActionButton(
                        title: model.isAutoRefreshPaused ? "Resume" : "Pause",
                        symbol: model.isAutoRefreshPaused ? .play : .pause
                    ) {
                        model.isAutoRefreshPaused.toggle()
                    }

                    TimelineActionButton(title: "Clear", symbol: .trash, foreground: DesignColor.accent) {
                        model.clearLogs()
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(18)

            Divider()
                .overlay(DesignColor.border.opacity(0.32))

            if model.logs.isEmpty {
                TimelineEmptyState()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.logs) { log in
                            LogRow(log: log)
                            Divider()
                                .overlay(DesignColor.border.opacity(0.24))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .softRoundedSurface(radius: 20, shadowRadius: 18, shadowY: 8)
    }

    private var timelineSubtitle: String {
        if let connection = model.selectedConnection {
            return "\(connection.name) · \(model.logs.count) visible events"
        }
        return "Waiting for runtime activity"
    }
}

struct FilterPill: View {
    var title: String
    var symbol: LucideIcon.Name

    var body: some View {
        HStack(spacing: 6) {
            LucideIcon(name: symbol, size: 24, color: DesignColor.primary, strokeWidth: 2)
            Text(title)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 10)
        .frame(height: 40)
        .flatCapsuleSurface()
    }
}

struct TimelineEmptyState: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 12) {
                LucideIcon(
                    name: model.connections.isEmpty ? .activity : .list,
                    size: 48,
                    color: DesignColor.primary.opacity(0.58),
                    strokeWidth: 2
                )
                .frame(width: 64, height: 64)
                .background(DesignColor.surfaceSoft.opacity(0.46))
                .clipShape(Circle())

                VStack(spacing: 8) {
                    Text(model.connections.isEmpty ? "Waiting for an app" : "No Activity")
                        .font(.system(size: 34, weight: .semibold))
                    Text(model.connections.isEmpty ? "Connect a React Native app to start receiving runtime events." : "Once the app sends events, they will appear here.")
                        .font(.system(size: 15))
                        .foregroundStyle(DesignColor.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

struct LogDetailModal: View {
    var log: LogEntry
    var timeText: String
    var typeText: String
    var typeColor: Color
    @Environment(\.dismiss) private var dismiss

    private var detailText: String {
        if let details = log.details, !details.isEmpty {
            return details
        }
        return log.summary
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                HStack(spacing: 10) {
                    Text(typeText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(typeColor)
                    Text(timeText)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(DesignColor.secondary)
                }

                Spacer()

                Button("Copy") {
                    copyToPasteboard(detailText)
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignColor.primary)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .softCapsuleSurface(shadowRadius: 8, shadowY: 3)

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignColor.accent)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .softCapsuleSurface(shadowRadius: 8, shadowY: 3)
            }
            .padding(22)

            Divider()
                .overlay(DesignColor.border.opacity(0.26))

            SelectableHighlightedLogText(text: detailText)
                .frame(minWidth: 820, idealWidth: 920, maxWidth: 1080, minHeight: 520, idealHeight: 620, maxHeight: 760)
        }
        .background(DesignColor.surface)
    }

    private func copyToPasteboard(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
}

struct SelectableHighlightedLogText: NSViewRepresentable {
    var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 22, height: 20)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.textStorage?.setAttributedString(LogSyntaxHighlighter.highlight(text))
        }
    }
}

enum LogSyntaxHighlighter {
    private static var baseFont: NSFont { NSFont.monospacedSystemFont(ofSize: 13, weight: .regular) }
    private static var boldFont: NSFont { NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold) }
    private static let baseColor = NSColor(red: 0.522, green: 0.510, blue: 0.486, alpha: 1)
    private static let primaryColor = NSColor(red: 0.071, green: 0.067, blue: 0.059, alpha: 1)
    private static let accentColor = NSColor(red: 0.910, green: 0.373, blue: 0.271, alpha: 1)
    private static let successColor = NSColor(red: 0.184, green: 0.620, blue: 0.392, alpha: 1)
    private static let linkColor = NSColor(red: 0.184, green: 0.337, blue: 0.620, alpha: 1)

    static func highlight(_ text: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4

        attributed.addAttributes([
            .font: baseFont,
            .foregroundColor: baseColor,
            .paragraphStyle: paragraph,
        ], range: fullRange)

        apply(#"(?m)^[A-Za-z ]+:"#, to: attributed, text: text, color: primaryColor, font: boldFont)
        apply(#"(?m)^(GET|POST|PUT|PATCH|DELETE|HTTP)\b"#, to: attributed, text: text, color: accentColor, font: boldFont)
        apply(#"https?://[^\s]+"#, to: attributed, text: text, color: linkColor, font: baseFont)
        apply(#"\([23]\d\d\)"#, to: attributed, text: text, color: successColor, font: boldFont)
        apply(#"\([45]\d\d\)"#, to: attributed, text: text, color: accentColor, font: boldFont)
        apply(#""[^"\n]+"\s*:"#, to: attributed, text: text, color: primaryColor, font: boldFont)
        apply(#":\s*(-?\d+(\.\d+)?|true|false|null)(?=,|\n|\})"#, to: attributed, text: text, color: accentColor, font: baseFont)

        return attributed
    }

    private static func apply(_ pattern: String, to attributed: NSMutableAttributedString, text: String, color: NSColor, font: NSFont) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        regex.matches(in: text, range: fullRange).forEach { match in
            attributed.addAttributes([
                .foregroundColor: color,
                .font: font,
            ], range: match.range)
        }
    }
}

struct LogRow: View {
    var log: LogEntry
    @State private var detailLog: LogEntry?

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text("+\(Int(log.deltaTime)) ms")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignColor.accent)
                Text(formattedTime(log.date))
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(DesignColor.secondary)
            }
            .frame(width: 178, alignment: .leading)

            Text(displayType(log.type))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(typeColor(log.type))
                .frame(width: 88, alignment: .leading)

            Text(log.summary)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(DesignColor.secondary)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38, alignment: .topLeading)
                .clipped()
                .allowsHitTesting(false)
                .contextMenu {
                    Button("Copy log") {
                        copyToPasteboard(copyText)
                    }
                }

            Button {
                detailLog = log
            } label: {
                LucideIcon(
                    name: .chevronRight,
                    size: 24,
                    color: DesignColor.muted,
                    strokeWidth: 2
                )
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(minHeight: 88)
        .background(DesignColor.surface)
        .contentShape(Rectangle())
        .onTapGesture {
            detailLog = log
        }
        .contextMenu {
            Button("Copy log") {
                copyToPasteboard(copyText)
            }
        }
        .sheet(item: $detailLog) { selectedLog in
            LogDetailModal(
                log: selectedLog,
                timeText: formattedTime(selectedLog.date),
                typeText: displayType(selectedLog.type),
                typeColor: typeColor(selectedLog.type)
            )
        }
    }

    private var copyText: String {
        if let details = log.details, !details.isEmpty {
            return details
        }
        return log.summary
    }

    private func displayType(_ type: String) -> String {
        switch type {
        case "api.response": "API RESPONSE"
        case "client.intro": "CONNECTION"
        default: type.uppercased()
        }
    }

    private func typeColor(_ type: String) -> Color {
        switch type {
        case "api.response", "log": DesignColor.accent
        case "client.intro": DesignColor.success
        default: DesignColor.secondary
        }
    }

    private func formattedTime(_ raw: String) -> String {
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let formatterWithoutFraction = ISO8601DateFormatter()
        formatterWithoutFraction.formatOptions = [.withInternetDateTime]

        guard let date = formatterWithFraction.date(from: raw) ?? formatterWithoutFraction.date(from: raw) else {
            return raw
                .replacingOccurrences(of: "T", with: " ")
                .replacingOccurrences(of: "Z", with: "")
        }

        let output = DateFormatter()
        output.dateFormat = "yyyy-MM-dd HH:mm:ss SSS"
        return output.string(from: date)
    }

    private func copyToPasteboard(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
}

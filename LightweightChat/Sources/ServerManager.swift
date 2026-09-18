import AppKit
import Combine
import Darwin
import Foundation

enum ServerKind: String, CaseIterable, Identifiable {
    case rapidMlx = "rapid-mlx"
    case mlxLm = "mlx_lm"

    var id: String { rawValue }
    var label: String { rawValue }

    var binary: String {
        switch self {
        case .rapidMlx: return "rapid-mlx"
        case .mlxLm: return "mlx_lm.server"
        }
    }

    func arguments(model: String) -> [String] {
        switch self {
        case .rapidMlx:
            return ["serve", model, "--port", "8008", "--max-tokens", "65000"]
        case .mlxLm:
            return ["--model", model, "--port", "8008", "--max-tokens", "65000"]
        }
    }
}

@MainActor
class ServerManager: ObservableObject {
    static let port = 8008
    static let providerURL = "http://127.0.0.1:8008/v1/chat/completions"
    static let maxLogLength = 200_000

    @Published var server: ServerKind {
        didSet { UserDefaults.standard.set(server.rawValue, forKey: "mlx_server") }
    }
    @Published private(set) var isRunning = false
    @Published var log = ""

    private var process: Process?

    init() {
        let raw = UserDefaults.standard.string(forKey: "mlx_server") ?? ""
        self.server = ServerKind(rawValue: raw) ?? .rapidMlx
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Must run synchronously: async dispatch may never execute before process exit.
            guard let self else { return }
            MainActor.assumeIsolated {
                self.killImmediately()
            }
        }
    }

    func start(model: String) {
        if process?.isRunning == true {
            appendLog("Server already running.")
            return
        }
        let modelID = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !modelID.isEmpty else {
            appendLog("Error: no model selected.")
            return
        }
        // GUI apps inherit a minimal PATH; resolve an absolute binary path instead.
        let env = ProcessInfo.processInfo.environment
        guard let binaryPath = CLIPath.resolveExecutable(named: server.binary, envPath: env["PATH"]) else {
            appendLog("Error: '\(server.binary)' not found. Searched PATH and common install locations (/opt/homebrew/bin, /usr/local/bin, ~/.local/bin, Python user bins).")
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: binaryPath)
        task.arguments = server.arguments(model: modelID)
        var childEnv = env
        childEnv["PATH"] = CLIPath.augmentedPath(inherited: env["PATH"])
        task.environment = childEnv
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in self?.appendLog(text, newline: false) }
        }
        do {
            try task.run()
        } catch {
            appendLog("Error: failed to launch: \(error.localizedDescription)")
            return
        }
        task.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.process = nil
                self.isRunning = false
                self.appendLog("Server exited.")
            }
        }

        process = task
        isRunning = true
        appendLog("$ \(server.binary) \(server.arguments(model: modelID).joined(separator: " "))")
        UserDefaults.standard.set(Self.providerURL, forKey: "provider_url")
        appendLog("provider_url → \(Self.providerURL)")
    }

    func stop() {
        if let task = process {
            appendLog("Stopping server (pid \(task.processIdentifier))…")
            task.terminate()
            let pid = task.processIdentifier
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    if self.process?.processIdentifier == pid, self.process?.isRunning == true {
                        kill(pid, SIGKILL)
                        self.appendLog("Force-killed (SIGKILL).")
                    }
                    // Kill orphaned descendants (workers spawned by the server).
                    for victim in ProcessTree.descendantPIDs(of: pid) where kill(victim, 0) == 0 {
                        kill(victim, SIGKILL)
                    }
                    self.finishStop()
                }
            }
        } else {
            finishStop()
        }
    }

    /// Synchronous kill of the whole server process tree, for use during app termination
    /// where async dispatch may never run.
    func killImmediately() {
        guard let task = process, task.isRunning else { return }
        let pid = task.processIdentifier
        let victims = ([pid] + ProcessTree.descendantPIDs(of: pid)).filter { $0 > 0 }
        for victim in victims {
            kill(victim, SIGTERM)
        }
        // Brief grace period for graceful shutdown, pumping the run loop.
        let deadline = Date().addingTimeInterval(1.0)
        while task.isRunning && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        // Anything still alive (direct child or orphaned workers) is force-killed.
        for victim in victims where kill(victim, 0) == 0 {
            kill(victim, SIGKILL)
        }
        sweepPort()
        process = nil
        isRunning = false
        appendLog("Server killed on quit.")
    }

    private func finishStop() {
        sweepPort()
        process = nil
        isRunning = false
        appendLog("Server stopped.")
    }

    private func sweepPort() {
        let killer = Process()
        killer.executableURL = URL(fileURLWithPath: "/bin/sh")
        killer.arguments = ["-c", "kill -9 $(/usr/sbin/lsof -ti:\(Self.port)) 2>/dev/null"]
        try? killer.run()
        killer.waitUntilExit()
    }

    private func appendLog(_ text: String, newline: Bool = true) {
        log += newline ? text + "\n" : text
        if log.count > Self.maxLogLength {
            log = String(log.suffix(Self.maxLogLength))
        }
    }
}

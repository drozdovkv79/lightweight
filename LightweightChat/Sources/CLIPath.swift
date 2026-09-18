import Foundation
import Darwin

/// Resolves external CLI executables (hf, rapid-mlx, mlx_lm.server) independently
/// of the minimal PATH that Finder/Dock-launched GUI apps inherit.
enum CLIPath {
    static let hfOverrideKey = "hf_binary_path"

    static let commonSearchDirs: [String] = [
        "/opt/homebrew/bin",
        "/usr/local/bin",
        NSString(string: "~/.local/bin").expandingTildeInPath,
    ]

    /// Locates an executable by name: override → inherited PATH dirs → common install dirs.
    /// Pure over its inputs (no UserDefaults / ProcessInfo reads) for testability.
    static func resolveExecutable(
        named name: String,
        override: String? = nil,
        envPath: String?,
        commonDirs: [String]? = nil,
        fileManager: FileManager = .default
    ) -> String? {
        if let override, !override.trimmingCharacters(in: .whitespaces).isEmpty {
            let trimmed = override.trimmingCharacters(in: .whitespaces)
            if fileManager.isExecutableFile(atPath: trimmed) { return trimmed }
        }
        let dirs = (commonDirs ?? defaultSearchDirs(fileManager: fileManager))
        let pathDirs = (envPath ?? "").split(separator: ":", omittingEmptySubsequences: true).map(String.init)
        for dir in pathDirs + dirs where !dir.isEmpty {
            let candidate = ((dir as NSString).expandingTildeInPath as NSString).appendingPathComponent(name)
            if fileManager.isExecutableFile(atPath: candidate) { return candidate }
        }
        return nil
    }

    static func defaultSearchDirs(fileManager: FileManager = .default) -> [String] {
        commonSearchDirs + pythonUserBinDirs(fileManager: fileManager)
    }

    /// Human-readable list of every location the resolver may consult, for error text.
    static var searchedLocationsDescription: String {
        let override = UserDefaults.standard.string(forKey: hfOverrideKey)
        let envPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let overrideLabel = (override?.isEmpty ?? true) ? "(not set)" : override!
        let all = [overrideLabel]
            + envPath.split(separator: ":", omittingEmptySubsequences: true).map(String.init)
            + defaultSearchDirs()
        return all.joined(separator: ", ")
    }

    /// Child-process PATH that covers common CLI install locations on top of the inherited one.
    static func augmentedPath(inherited: String?) -> String {
        (commonSearchDirs + [inherited ?? "/usr/bin:/bin:/usr/sbin:/sbin"]).joined(separator: ":")
    }

    /// Python user-install script dirs: ~/Library/Python/<version>/bin
    private static func pythonUserBinDirs(fileManager: FileManager) -> [String] {
        let libBase = NSHomeDirectory() + "/Library/Python"
        guard let entries = try? fileManager.contentsOfDirectory(atPath: libBase) else { return [] }
        return entries.compactMap { entry in
            let dir = libBase + "/\(entry)/bin"
            var isDir: ObjCBool = false
            return fileManager.fileExists(atPath: dir, isDirectory: &isDir) && isDir.boolValue ? dir : nil
        }
    }
}

/// Walks the live process table to find a process's whole descendant tree.
enum ProcessTree {
    /// All descendants of `root` (excluding root itself), deepest chains included.
    static func descendantPIDs(of root: pid_t) -> [pid_t] {
        guard root > 0 else { return [] }
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
        var size = 0
        guard sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) == 0, size > 0 else { return [] }
        var count = size / MemoryLayout<kinfo_proc>.stride
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count)
        guard sysctl(&mib, u_int(mib.count), &procs, &size, nil, 0) == 0 else { return [] }
        count = size / MemoryLayout<kinfo_proc>.stride

        var result: [pid_t] = []
        var frontier: [pid_t] = [root]
        while let parent = frontier.popLast() {
            for i in 0..<count {
                let pid = procs[i].kp_proc.p_pid
                let ppid = procs[i].kp_eproc.e_ppid
                if ppid == parent, pid != root, !result.contains(pid) {
                    result.append(pid)
                    frontier.append(pid)
                }
            }
        }
        return result
    }
}

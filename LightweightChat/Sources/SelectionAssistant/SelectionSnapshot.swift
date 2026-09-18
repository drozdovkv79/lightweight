import Foundation
import Cocoa

struct SelectionSnapshot {
    let selectedText: String
    let appBundleIdentifier: String
    let appPID: pid_t
    let canReplaceSelection: Bool
}

## 1. Critical Fixes
- [x] 1.1 ChatViewModel URL guard (line 185)
- [x] 1.2 ContentView scroll throttle @State (line 175)
- [x] 1.3 ChatInputField monitor cleanup (line 22)
- [x] 1.4 SelectionAssistantPanel init orderOut (line 31)
- [x] 1.5 ChatViewModel insertSelection AX focus (line 176)

## 2. Performance / Lazy
- [x] 2.1 ChatMessage init deferred parse (line 13 Models)
- [x]  RichTextView reuse verified (line 527)
- [x] 2.3 StreamingBubble spec aligned (ContentView line 47)

## 3. Security / Data
- [x] 3.1 Request body guard (ChatViewModel 192)
- [x] 3.2 Error stream cap (ChatViewModel 100)
- [x]  insertionError per message / clear
- [x] 3.4 AX bridge robust (SelectionAssistantCoordinator 138)
- [x] 3.5 Multi-screen panel (Panel 31-33)
- [x] 3.6 Settings apiKey sync (SettingsView 4-5)
- [x] 3.7 Tests + Package.resolved (Makefile, Package.swift)

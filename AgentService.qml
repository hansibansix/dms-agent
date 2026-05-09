pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {
    id: root

    // Empty string = panel hidden everywhere. Otherwise, the screen name on which
    // the per-screen DmsAgent.qml instance should display its panel. Acts as the
    // single source of truth across all per-bar plugin instances.
    property string activeScreenName: ""

    function _focusedScreenName() {
        const s = CompositorService.getFocusedScreen();
        return s ? s.name : "";
    }

    function toggleOnScreen(screenName) {
        if (!screenName) return;
        activeScreenName = (activeScreenName === screenName) ? "" : screenName;
    }

    function toggleOnFocused() {
        toggleOnScreen(_focusedScreenName());
    }

    function hidePanel() {
        activeScreenName = "";
    }

    IpcHandler {
        target: "dmsAgent"
        function toggle(): string {
            root.toggleOnFocused();
            return root.popoutVisible ? "opened" : "closed";
        }
    }

    property string claudeModel: "haiku"
    property bool extendedThinking: false
    property string fontFamily: ""
    property int fontSize: 13
    property string systemPrompt: "You are a concise desktop assistant on Linux with niri (Wayland compositor) and DankMaterialShell. " +
        "You have full tool access (Bash, Read, Write, Edit). Execute actions immediately, never ask for confirmation. " +
        "Respond in user's language. Be concise.\n\n" +
        "NIRI COMMANDS:\n" +
        "- List windows: niri msg -j windows\n" +
        "- Focus window by id: niri msg action focus-window --id ID\n" +
        "- Close focused window: niri msg action close-window\n" +
        "- Focus workspace: niri msg action focus-workspace N\n" +
        "- Move window to workspace: niri msg action move-window-to-workspace N\n" +
        "- Fullscreen: niri msg action fullscreen-window\n" +
        "- Maximize: niri msg action maximize-column\n" +
        "- Screenshot: niri msg action screenshot\n" +
        "- Toggle floating: niri msg action toggle-window-floating\n" +
        "- Focus left/right/up/down: niri msg action focus-column-left|right, focus-window-up|down\n" +
        "- Move column: niri msg action move-column-left|right\n" +
        "- Toggle overview: niri msg action toggle-overview\n\n" +
        "MUSIC: ~/go/bin/spogo (play, pause, next, prev, status, search track X, volume N)\n\n" +
        "Match fuzzy — 'brave' matches 'brave-browser-nightly', 'whatsapp' matches 'WhatsApp Web — Mozilla Firefox'.\n\n" +
        "IMPORTANT: When launching applications or running long-lived processes, ALWAYS detach them from the shell. " +
        "Use: setsid <command> >/dev/null 2>&1 & disown\n" +
        "NEVER run GUI apps in the foreground — always background and detach them."

    property bool busy: false
    property string statusText: "Ready"
    property var messages: []
    readonly property bool popoutVisible: activeScreenName !== ""
    property string sessionId: ""
    property string lastCost: ""
    property var history: []

    signal messageAdded(var message)
    signal responseComplete()

    readonly property string homeDir: Quickshell.env("HOME") || ""

    Component.onCompleted: { loadHistory(); }

    // --- Process runner ---
    Component {
        id: cmdRunner
        Process {
            id: cmdProc
            property string shellCmd: ""
            property var onFinished: null
            command: ["bash", "-lc", shellCmd]
            stdout: StdioCollector {
                onStreamFinished: { if (cmdProc.onFinished) cmdProc.onFinished(text); }
            }
            stderr: StdioCollector {}
            onExited: { cmdProc.destroy(); }
        }
    }

    function run(shellCmd, cb) {
        var p = cmdRunner.createObject(root, { shellCmd: shellCmd, onFinished: cb });
        p.running = true;
        return p;
    }

    function runQuietExit(shellCmd, cb) {
        var body = String(shellCmd).replace(/;+\s*$/, "").trim();
        return run((body ? body + "; " : "") + "exit 0", cb);
    }

    function shellQuote(input) {
        return "'" + String(input).replace(/'/g, "'\"'\"'") + "'";
    }

    // --- Messages ---
    function addMessage(role, content) {
        var msg = { role: role, content: content, timestamp: Date.now() };
        var newMessages = messages.slice();
        newMessages.push(msg);
        messages = newMessages;
        messageAdded(msg);
        return msg;
    }

    function clearMessages() {
        messages = [];
        sessionId = "";
        lastCost = "";
        persistSession();
    }

    // --- Notification ---
    function notifyIfHidden(text) {
        if (popoutVisible) return;
        runQuietExit("notify-send -a 'DMS Agent' -i smart_toy 'Agent' " + shellQuote(String(text).substring(0, 100)), function() {});
    }

    // --- History (reads from Claude CLI session files) ---
    readonly property string historyScript: homeDir + "/.config/DankMaterialShell/plugins/dmsAgent/history.py"
    readonly property string stateDir: homeDir + "/.local/state/DankMaterialShell/plugins/dmsAgent"
    readonly property string sessionFilePath: stateDir + "/session.json"

    FileView {
        id: sessionFile
        path: root.sessionFilePath
        onLoaded: {
            try {
                const data = JSON.parse(sessionFile.text());
                if (data && typeof data.sessionId === "string" && data.sessionId)
                    root.sessionId = data.sessionId;
            } catch (e) {}
        }
    }

    function persistSession() {
        const payload = JSON.stringify({ sessionId: sessionId, savedAt: Date.now() });
        runQuietExit(
            "mkdir -p " + shellQuote(stateDir) + " && printf %s " + shellQuote(payload) + " > " + shellQuote(sessionFilePath),
            function() {}
        );
    }

    function loadHistory() {
        runQuietExit("python3 " + shellQuote(historyScript) + " list", function(output) {
            try { history = JSON.parse(String(output).trim()); } catch(e) { history = []; }
        });
    }

    function resumeSession(historySessionId) {
        if (busy) return;
        sessionId = historySessionId;
        messages = [];
        busy = true;
        statusText = "Loading session...";

        runQuietExit("python3 " + shellQuote(historyScript) + " restore " + shellQuote(historySessionId), function(output) {
            var loaded = [];
            try { loaded = JSON.parse(String(output).trim()); } catch(e) {}
            for (var i = 0; i < loaded.length; i++) {
                loaded[i].timestamp = Date.now();
                var newMsgs = messages.slice();
                newMsgs.push(loaded[i]);
                messages = newMsgs;
                messageAdded(loaded[i]);
            }
            if (loaded.length === 0) {
                addMessage("assistant", "Session resumed.");
            }
            busy = false;
            statusText = "Ready";
        });
    }

    // --- Intent detection ---
    readonly property var goToPatterns: [
        /^(?:go\s*to|switch\s*to|llévame\s*a|llevame\s*a|ir\s*a|ve\s*a|muéstrame|muestrame|cambiar?\s*a|navegar?\s*a|show\s*me)\s+(.+)/i
    ]
    readonly property var closePatterns: [
        /^(?:close|cierra|kill|mata|termina|quit|exit)\s+(.+)/i
    ]
    readonly property var openPatterns: [
        /^(?:open|abre|launch|lanza|ejecuta|run|start|inicia)\s+(.+)/i
    ]

    function detectIntent(text) {
        var t = text.trim();
        for (var i = 0; i < goToPatterns.length; i++) { var m = t.match(goToPatterns[i]); if (m) return { intent: "goto", target: m[1].trim() }; }
        for (var j = 0; j < closePatterns.length; j++) { var m2 = t.match(closePatterns[j]); if (m2) return { intent: "close", target: m2[1].trim() }; }
        for (var k = 0; k < openPatterns.length; k++) { var m3 = t.match(openPatterns[k]); if (m3) return { intent: "open", target: m3[1].trim() }; }
        return null;
    }

    // --- Send message ---
    function sendMessage(text) {
        if (busy || !text.trim()) return;
        addMessage("user", text);
        busy = true;

        var intent = detectIntent(text);
        if (intent) {
            prefetchContext(intent, function(ctx) { callClaude(text + "\n" + ctx); });
        } else {
            statusText = "Thinking...";
            callClaude(text);
        }
    }

    // --- Pre-fetch context ---
    function prefetchContext(intent, callback) {
        if (intent.intent === "goto") {
            statusText = "Scanning windows...";
            runQuietExit("niri msg -j windows 2>/dev/null", function(output) {
                var windows; try { windows = JSON.parse(output); } catch(e) { windows = []; }
                var summary = windows.map(function(w) {
                    return "id:" + w.id + " app:" + w.app_id + " title:\"" + w.title + "\"" + (w.is_focused ? " (focused)" : "");
                }).join("\n");
                callback("[Open windows]\n" + summary);
            });
        } else if (intent.intent === "close") {
            statusText = "Scanning processes...";
            runQuietExit("ps aux | grep -iv grep | grep -i " + shellQuote(intent.target) + " | head -10", function(output) {
                callback("[Matching processes]\n" + String(output).trim());
            });
        } else if (intent.intent === "open") {
            statusText = "Searching apps...";
            var q = intent.target.toLowerCase();
            var cmd = "for dir in /usr/share/applications /usr/local/share/applications \"$HOME/.local/share/applications\"; do "
                + "[ -d \"$dir\" ] || continue; grep -ril " + shellQuote(q) + " \"$dir\"/*.desktop 2>/dev/null; done "
                + "| while read f; do name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2); "
                + "exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2 | sed 's/ %[a-zA-Z]//g'); "
                + "echo \"$name | cmd: $exec\"; done | head -10";
            runQuietExit(cmd, function(output) {
                callback("[Matching apps]\n" + String(output).trim());
            });
        } else {
            callback("");
        }
    }

    // --- Claude process ---
    property var _claudeProcess: null

    function cancelRequest() {
        if (_claudeProcess) {
            _claudeProcess.signal(15);
            _claudeProcess = null;
            busy = false;
            statusText = "Ready";
        }
    }

    function callClaude(prompt) {
        statusText = extendedThinking ? "Thinking..." : "Processing...";

        var cmd = "echo " + shellQuote(prompt) + " | claude -p"
            + " --model " + shellQuote(claudeModel)
            + " --output-format json"
            + " --dangerously-skip-permissions"
            + " --append-system-prompt " + shellQuote(systemPrompt)
            + (sessionId ? " --resume " + shellQuote(sessionId) : "")
            + " 2>/dev/null";

        _claudeProcess = run(cmd, function(output) {
            _claudeProcess = null;
            parseClaudeJson(String(output).trim());
        });
    }

    function parseClaudeJson(raw) {
        var data;
        try { data = JSON.parse(raw); } catch(e) {
            finishResponse("(could not parse response)");
            return;
        }

        if (data.session_id) {
            sessionId = data.session_id;
            persistSession();
        }

        if (data.total_cost_usd !== undefined) {
            lastCost = "$" + data.total_cost_usd.toFixed(4);
        }
        if (data.usage) {
            var inp = data.usage.input_tokens || 0;
            var out = data.usage.output_tokens || 0;
            lastCost += " (" + inp + "→" + out + " tokens)";
        }

        if (data.num_turns && data.num_turns > 1) {
            addMessage("tool_status", "Executed " + (data.num_turns - 1) + " action(s)");
        }

        var response = data.result || "";
        finishResponse(response || "(done)");
        loadHistory();
    }

    function finishResponse(text) {
        addMessage("assistant", text);
        busy = false; statusText = "Ready";
        responseComplete(); notifyIfHidden(text);
    }
}

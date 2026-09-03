import AppKit
import Combine
import os
import TuckCore

/// Owns the menu bar items and the hiding logic.
///
/// Right to left, the menu bar holds:
///   [always-hidden icons] [dotted line] [spacers] [hidden icons] [line] [spacers] [chevron] [icons that always show]
///
/// How hiding works: macOS lays out menu bar icons from the right, and an item
/// that does not fit disappears together with everything to its left. To hide,
/// Tuck makes its line and its spacers each about half a screen wide. The first
/// one that no longer fits takes every icon left of it out of view. Nothing is
/// removed. Making them thin again brings the icons straight back.
///
/// Tuck's items are interchangeable. Roles (chevron, spacer, line, dotted line) are
/// handed out by position, so however macOS or the user orders them, the marks
/// always read line, then chevron.
final class StatusBarController: NSObject, NSMenuDelegate {
    private let preferences: Preferences
    private let log = Logger(subsystem: "com.hdw.tuck", category: "menubar")

    /// Every item Tuck owns, in creation order. Position decides the role, not this order.
    private var mainItems: [NSStatusItem]
    private var alwaysItems: [NSStatusItem] = []

    // Roles. Refreshed by assignRoles() whenever positions can be trusted.
    private var chevron: NSStatusItem
    private var line: NSStatusItem
    private var spacers: [NSStatusItem]
    private var dotted: NSStatusItem?
    private var alwaysSpacers: [NSStatusItem] = []

    /// Just wide enough for the line image. With a resting spacer's 16pt beside it, the pair is one icon wide.
    private static let thinLength: CGFloat = 4
    /// A resting spacer keeps 16pt of padding, nothing more.
    private static let restLength: CGFloat = 0
    /// Half the narrowest screen, minus a margin. macOS refuses anything wider than half a screen.
    private var wideLength: CGFloat = 600
    /// Spacers per section: enough that the last wide item can never fit on the widest screen.
    private let spacersPerSection: Int

    private(set) var isCollapsed = false
    private var isAlwaysHiddenRevealed = false
    private var isToggling = false
    private var autoHideTimer: Timer?
    private var rolesRefresh: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    private lazy var contextMenu = makeContextMenu()

    var openPreferences: (() -> Void)?

    private enum MenuTag: Int {
        case showHide = 1, peek, autoHide
    }

    init(preferences: Preferences) {
        self.preferences = preferences
        let geometry = Self.geometry(for: NSScreen.screens)
        wideLength = geometry.wide
        spacersPerSection = geometry.spacers

        // Creation order: each new item lands to the left of the previous one.
        let first = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        first.autosaveName = "tuck.toggle"
        let middle = (0..<geometry.spacers).map { Self.makeSpacer(name: "tuck.spacer\($0)") }
        let last = NSStatusBar.system.statusItem(withLength: Self.thinLength)
        last.autosaveName = "tuck.separator"
        mainItems = [first] + middle + [last]
        chevron = first
        spacers = middle
        line = last
        super.init()

        configureRoles()
        updateAlwaysHiddenSection()
        observePreferences()

        NotificationCenter.default.addObserver(
            self, selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(someWindowMoved(_:)),
            name: NSWindow.didMoveNotification, object: nil)

        // The buttons need a layout pass before their positions can be trusted.
        collapseWhenReady(attempt: 0)
    }

    // MARK: - Geometry

    private static func makeSpacer(name: String) -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: restLength)
        item.autosaveName = name
        return item
    }

    private static func geometry(for screens: [NSScreen]) -> (wide: CGFloat, spacers: Int) {
        let widths = screens.map { $0.frame.width }
        let narrowest = widths.min() ?? 1440
        let widest = widths.max() ?? 1440
        let wide = max(200, floor(narrowest / 2) - 32)
        let windowWidth = wide + 16
        // Free space on the widest screen is at most its width minus the Apple menu.
        // One extra so a MacBook screen plus a larger external display still works after a relaunch.
        let spacers = max(1, Int((widest - 60) / windowWidth)) + 1
        return (wide, spacers)
    }

    // MARK: - Roles

    /// Hands out roles by position, rightmost first. Returns false while positions cannot be trusted.
    @discardableResult
    private func assignRoles() -> Bool {
        guard !isCollapsed else { return false }
        // Hidden items have stale positions, so the always-hidden section only joins in while revealed.
        let includeAlways = !alwaysItems.isEmpty && isAlwaysHiddenRevealed
        var positioned: [(item: NSStatusItem, x: CGFloat)] = []
        for item in mainItems + (includeAlways ? alwaysItems : []) {
            guard let x = originX(of: item) else { return false }
            positioned.append((item, x))
        }
        let sorted = positioned.sorted { $0.x > $1.x }.map(\.item)
        var index = 0
        func take(_ count: Int) -> [NSStatusItem] {
            defer { index += count }
            return Array(sorted[index..<index + count])
        }
        let newChevron = take(1)[0]
        let newSpacers = take(spacersPerSection)
        let newLine = take(1)[0]
        let newAlwaysSpacers = includeAlways ? take(spacersPerSection) : alwaysSpacers
        let newDotted = includeAlways ? take(1)[0] : dotted

        let unchanged = newChevron === chevron && newLine === line && newDotted === dotted
            && newSpacers.elementsEqual(spacers, by: ===) && newAlwaysSpacers.elementsEqual(alwaysSpacers, by: ===)
        if !unchanged {
            chevron = newChevron
            spacers = newSpacers
            line = newLine
            alwaysSpacers = newAlwaysSpacers
            dotted = newDotted
            configureRoles()
            log.notice("Roles reassigned by position")
        }
        return true
    }

    /// Gives every item the look and behaviour of its current role.
    private func configureRoles() {
        for item in mainItems + alwaysItems {
            item.menu = nil
            item.length = Self.restLength
            if let button = item.button {
                button.target = nil
                button.action = nil
                button.image = nil
                button.toolTip = nil
                button.appearsDisabled = false
            }
        }
        if let button = chevron.button {
            button.target = self
            button.action = #selector(toggleClicked(_:))
            _ = button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Click to hide or show icons. Option-click to peek at the always-hidden ones. Right-click for options."
        }
        line.menu = contextMenu
        line.button?.toolTip = "Hold ⌘ and drag icons to the left of this line to hide them."
        if let dotted {
            dotted.menu = contextMenu
            dotted.button?.appearsDisabled = true
            dotted.button?.toolTip = "Icons left of this dotted line stay hidden even while the rest are showing. Option-click the chevron to peek."
        }
        applyLayout()
    }

    /// Sets every item's width and image from the current state. The only place widths change.
    private func applyLayout() {
        let hideMain = isCollapsed
        chevron.length = NSStatusItem.variableLength
        chevron.button?.image = hideMain ? MenuBarImages.chevronLeft : MenuBarImages.chevronRight
        for spacer in spacers {
            spacer.length = hideMain ? wideLength : Self.restLength
        }
        line.length = hideMain ? wideLength : Self.thinLength
        line.button?.image = hideMain ? nil : MenuBarImages.separator

        let hideAlways = hideMain || !isAlwaysHiddenRevealed
        for spacer in alwaysSpacers {
            spacer.length = hideAlways ? wideLength : Self.restLength
        }
        if let dotted {
            dotted.length = hideAlways ? wideLength : Self.thinLength
            dotted.button?.image = hideAlways ? nil : MenuBarImages.dottedSeparator
        }
    }

    /// Re-check roles a moment after something moved, but only while showing.
    private func scheduleRolesRefresh(after delay: TimeInterval = 0.4) {
        rolesRefresh?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.isCollapsed else { return }
            self.assignRoles()
        }
        rolesRefresh = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    @objc private func someWindowMoved(_ notification: Notification) {
        guard !isCollapsed, let window = notification.object as? NSWindow else { return }
        let ours = (mainItems + alwaysItems).contains { $0.button?.window === window }
        if ours { scheduleRolesRefresh() }
    }

    private func observePreferences() {
        preferences.$alwaysHiddenEnabled
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self else { return }
                self.updateAlwaysHiddenSection()
                if enabled {
                    // Show the new dotted line so icons can be dragged past it.
                    self.isAlwaysHiddenRevealed = true
                    self.applyLayout()
                    if self.isCollapsed { self.expand() }
                    self.scheduleRolesRefresh(after: 0.8)
                }
            }
            .store(in: &cancellables)

        preferences.$autoHide
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.scheduleAutoHideIfNeeded() }
            .store(in: &cancellables)

        preferences.$autoHideSeconds
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.scheduleAutoHideIfNeeded() }
            .store(in: &cancellables)

        preferences.$useFullMenuBar
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled, !self.isCollapsed {
                    self.takeFullMenuBar()
                } else if !enabled {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Clicks

    @objc private func toggleClicked(_ sender: Any?) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            chevron.menu = contextMenu
            chevron.button?.performClick(nil)
        } else if event?.modifierFlags.contains(.option) == true {
            peekAlwaysHidden()
        } else {
            toggle()
        }
    }

    /// Hide if showing, show if hidden.
    func toggle() {
        // A double-click would flicker the Dock icon in full menu bar mode.
        guard !isToggling else { return }
        isToggling = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isToggling = false
        }
        if isCollapsed { expand() } else { collapse() }
    }

    func collapse() {
        guard !isCollapsed else { return }
        guard assignRoles() else {
            log.notice("Not hiding yet: the menu bar has not settled.")
            return
        }
        isCollapsed = true
        isAlwaysHiddenRevealed = false
        autoHideTimer?.invalidate()
        rolesRefresh?.cancel()
        applyLayout()
        if preferences.useFullMenuBar { leaveFullMenuBar() }
        if !preferences.hasHiddenBefore { preferences.hasHiddenBefore = true }
        logPositions("hidden")
    }

    func expand() {
        guard isCollapsed else { return }
        isCollapsed = false
        applyLayout()
        if preferences.useFullMenuBar { takeFullMenuBar() }
        scheduleAutoHideIfNeeded()
        scheduleRolesRefresh(after: 0.6)
        logPositions("shown")
    }

    /// Option-click: show the always-hidden section too, or tuck it away again.
    private func peekAlwaysHidden() {
        guard preferences.alwaysHiddenEnabled, dotted != nil else {
            toggle()
            return
        }
        isAlwaysHiddenRevealed.toggle()
        applyLayout()
        if isAlwaysHiddenRevealed, isCollapsed {
            expand()
        } else {
            scheduleAutoHideIfNeeded()
        }
        log.notice("Always-hidden section \(self.isAlwaysHiddenRevealed ? "revealed" : "tucked away", privacy: .public)")
    }

    // MARK: - Full menu bar mode

    /// Tuck becomes the front app for a moment. Its short menu leaves the most room for icons.
    private func takeFullMenuBar() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func leaveFullMenuBar() {
        NSApp.setActivationPolicy(.accessory)
        NSApp.deactivate()
    }

    // MARK: - Auto hide

    private func scheduleAutoHideIfNeeded() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        guard preferences.autoHide, preferences.hasHiddenBefore, !isCollapsed else { return }
        let timer = Timer(timeInterval: preferences.autoHideSeconds, repeats: false) { [weak self] _ in
            self?.collapse()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoHideTimer = timer
    }

    private func collapseWhenReady(attempt: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            if self.assignRoles() {
                // A fresh install stays open until the user hides on purpose.
                if self.preferences.hasHiddenBefore {
                    self.collapse()
                } else {
                    self.logPositions("first launch, staying open")
                }
            } else if attempt < 6 {
                self.collapseWhenReady(attempt: attempt + 1)
            } else {
                self.log.notice("Did not hide at launch: the menu bar never settled.")
            }
        }
    }

    // MARK: - Always-hidden section

    private func updateAlwaysHiddenSection() {
        if preferences.alwaysHiddenEnabled {
            guard alwaysItems.isEmpty else { return }
            // New items land at the far left: spacers first, then the dotted line beyond them.
            let spacers = (0..<spacersPerSection).map { Self.makeSpacer(name: "tuck.alwaysSpacer\($0)") }
            let dotted = NSStatusBar.system.statusItem(withLength: Self.thinLength)
            dotted.autosaveName = "tuck.alwaysHidden"
            alwaysItems = spacers + [dotted]
            alwaysSpacers = spacers
            self.dotted = dotted
        } else if !alwaysItems.isEmpty {
            alwaysItems.forEach { NSStatusBar.system.removeStatusItem($0) }
            alwaysItems = []
            alwaysSpacers = []
            dotted = nil
            isAlwaysHiddenRevealed = false
        }
        configureRoles()
    }

    // MARK: - Positions

    private func logPositions(_ state: String) {
        let chevronX = originX(of: chevron).map { Int($0) } ?? -1
        let lineX = originX(of: line).map { Int($0) } ?? -1
        log.notice("Icons \(state, privacy: .public): chevron x=\(chevronX) line x=\(lineX) wide=\(Int(self.wideLength)) spacers=\(self.spacersPerSection)")
    }

    /// Each menu bar item lives in its own small window. Comparing their x origins
    /// tells us the order they are in. Only meaningful while showing.
    private func originX(of item: NSStatusItem?) -> CGFloat? {
        guard let window = item?.button?.window, window.frame.width > 0, window.frame.origin.x > 0 else { return nil }
        return window.frame.origin.x
    }

    @objc private func screenParametersChanged() {
        wideLength = Self.geometry(for: NSScreen.screens).wide
        applyLayout()
        log.notice("Screens changed: wide items are now \(Int(self.wideLength))pt")
    }

    // MARK: - Context menu

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let showHide = NSMenuItem(title: "Hide icons", action: #selector(menuToggle), keyEquivalent: "")
        showHide.target = self
        showHide.tag = MenuTag.showHide.rawValue
        menu.addItem(showHide)

        let peek = NSMenuItem(title: "Peek at always-hidden icons", action: #selector(menuPeek), keyEquivalent: "")
        peek.target = self
        peek.tag = MenuTag.peek.rawValue
        menu.addItem(peek)

        let autoHide = NSMenuItem(title: "Hide again automatically", action: #selector(menuToggleAutoHide), keyEquivalent: "")
        autoHide.target = self
        autoHide.tag = MenuTag.autoHide.rawValue
        menu.addItem(autoHide)

        menu.addItem(.separator())

        let prefs = NSMenuItem(title: "Preferences…", action: #selector(menuOpenPreferences), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Tuck", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        return menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.item(withTag: MenuTag.showHide.rawValue)?.title = isCollapsed ? "Show hidden icons" : "Hide icons"
        menu.item(withTag: MenuTag.peek.rawValue)?.isHidden = !preferences.alwaysHiddenEnabled
        menu.item(withTag: MenuTag.peek.rawValue)?.title = isAlwaysHiddenRevealed ? "Tuck away always-hidden icons" : "Peek at always-hidden icons"
        menu.item(withTag: MenuTag.autoHide.rawValue)?.state = preferences.autoHide ? .on : .off
    }

    func menuDidClose(_ menu: NSMenu) {
        // The chevron only borrows the menu for a right-click. Left-clicks must reach the action.
        DispatchQueue.main.async { [weak self] in
            self?.chevron.menu = nil
        }
    }

    @objc private func menuToggle() { toggle() }
    @objc private func menuPeek() { peekAlwaysHidden() }
    @objc private func menuToggleAutoHide() { preferences.autoHide.toggle() }
    @objc private func menuOpenPreferences() { openPreferences?() }
}

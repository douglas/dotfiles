import QtQuick
import Quickshell
import Quickshell.Services.Notifications as QsNotifications

Item {
    id: root

    property bool panelOpen: false
    property bool dndEnabled: false
    property var osdService: null
    property var notifications: []
    property var hiddenToasts: []

    QsNotifications.NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true
            root.notifications = [notif, ...root.notifications]
            root.hideToast(notif.id)
            if (root.dndEnabled && !root.isCritical(notif)) {
                return
            }

            root.showOsd(notif)
        }
    }

    function dismiss(notif) {
        notif.dismiss()
        root.notifications = root.notifications.filter(n => n.id !== notif.id)
        root.hiddenToasts = root.hiddenToasts.filter(id => id !== notif.id)
    }

    function hideToast(id) {
        if (!root.hiddenToasts.includes(id))
            root.hiddenToasts = [...root.hiddenToasts, id]
    }

    function hideToasts(ids) {
        const next = [...root.hiddenToasts]
        for (const id of ids || []) {
            if (!next.includes(id))
                next.push(id)
        }
        root.hiddenToasts = next
    }

    function clearAll() {
        const copy = [...root.notifications]
        copy.forEach(n => n.dismiss())
        root.notifications = []
        root.hiddenToasts = []
    }

    function togglePanel() {
        panelOpen = !panelOpen
    }

    function setDnd(enabled) {
        dndEnabled = enabled
        if (!enabled) return

        for (const notif of root.notifications) {
            if (!root.isCritical(notif))
                root.hideToast(notif.id)
        }
    }

    function toggleDnd() {
        setDnd(!dndEnabled)
    }

    function appNameFor(notif) {
        const name = (
            notif?.appName ||
            notif?.applicationName ||
            notif?.desktopEntry ||
            ""
        ).trim()
        if (name !== "") return name
        if ((notif?.summary || "").startsWith("Quickshell")) return "Quickshell"
        return "Unknown"
    }

    function osdAppNameFor(notif) {
        const name = appNameFor(notif)
        return name === "Unknown" ? "" : name
    }

    function osdIconFor(notif) {
        const app = appNameFor(notif).toLowerCase()
        if (app.includes("kitty") || app.includes("ghostty") || app.includes("terminal"))
            return "󰆍"
        if (app.includes("codex"))
            return "󰚩"
        if (app.includes("calendar"))
            return "󰃭"
        return "󰂚"
    }

    function osdTitleFor(notif) {
        return (notif?.summary || appNameFor(notif)).trim() || "Notification"
    }

    function osdSubtitleFor(notif) {
        const body = (notif?.body || "").replace(/<[^>]*>/g, "").trim()
        return body || appNameFor(notif)
    }

    function defaultActionFor(notif) {
        const actions = notif?.actions || []
        for (const action of actions) {
            if ((action?.identifier || "").toLowerCase() === "default")
                return action
        }
        for (const action of actions) {
            const text = (action?.text || "").toLowerCase()
            if (text.includes("open") || text.includes("show") || text.includes("activate"))
                return action
        }
        return null
    }

    function activateNotification(notif) {
        const action = defaultActionFor(notif)
        if (action) action.invoke()
        root.hideToast(notif.id)
    }

    function showOsd(notif) {
        if (!root.osdService)
            return

        root.osdService.showMessage(
            osdIconFor(notif),
            osdTitleFor(notif),
            osdSubtitleFor(notif),
            root.isCritical(notif) ? "red" : "accent",
            osdAppNameFor(notif),
            function() { root.activateNotification(notif) }
        )
    }

    function appNames() {
        const seen = {}
        const out = []
        for (const notif of root.notifications) {
            const name = appNameFor(notif)
            if (seen[name]) continue
            seen[name] = true
            out.push(name)
        }
        return out
    }

    function notificationsForApp(appName) {
        if (!appName) return [...root.notifications]
        return root.notifications.filter(n => appNameFor(n) === appName)
    }

    function isSlackNotification(notif) {
        return appNameFor(notif).toLowerCase().includes("slack")
    }

    function isSlackDirectOrMention(notif) {
        if (!isSlackNotification(notif)) return false

        const summary = (notif?.summary || "").toLowerCase()
        const body = (notif?.body || "").toLowerCase()
        const text = [summary, body].join(" ")

        if (text.includes("mentioned you") ||
            text.includes("mention") ||
            text.includes("@douglas") ||
            text.includes("@here") ||
            text.includes("@channel"))
            return true

        if (summary.startsWith("#") || summary.includes(" in #"))
            return false

        return summary !== "" && !summary.includes("#")
    }

    function hasSlackDirectOrMention() {
        return root.notifications.some(n => isSlackDirectOrMention(n))
    }

    function groupedNotifications(appName) {
        const groups = {}
        const order = []
        for (const notif of notificationsForApp(appName)) {
            const name = appNameFor(notif)
            if (!groups[name]) {
                groups[name] = {
                    key: name,
                    appName: name,
                    latest: notif,
                    count: 0,
                    items: []
                }
                order.push(name)
            }
            groups[name].count += 1
            groups[name].items.push(notif)
        }
        return order.map(name => groups[name])
    }

    function dismissMany(items) {
        for (const notif of items || [])
            dismiss(notif)
    }

    function isCritical(notif) {
        return notif.urgency === QsNotifications.NotificationUrgency.Critical
    }
}

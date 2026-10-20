pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    property var articles: []
    property var feedErrors: []
    property int fetchedAt: 0
    property bool busy: false
    property string message: ""
    readonly property var feedUrls: Plasmoid.configuration.feedUrls || []
    readonly property string helper: decodeURIComponent(Qt.resolvedUrl("../code/komarss").toString().replace("file://", ""))

    Plasmoid.icon: "application-rss+xml"
    toolTipMainText: "kOMA RSS"
    toolTipSubText: {
        if (feedUrls.length === 0) return "Right-click → Configure to add feeds";
        if (busy && articles.length === 0) return "Loading feeds…";
        if (message) return message;
        let text = articles.length + " articles from " + feedUrls.length + (feedUrls.length === 1 ? " feed" : " feeds");
        if (feedErrors.length) text += " (" + feedErrors.length + " failed)";
        return text;
    }
    switchWidth: Kirigami.Units.gridUnit * 16
    switchHeight: Kirigami.Units.gridUnit * 16
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Refresh Feeds"
            icon.name: "view-refresh"
            onTriggered: root.refresh()
        }
    ]

    function quote(value) { return "'" + String(value).replace(/'/g, "'\\''") + "'"; }
    function refresh() {
        if (busy) return;
        if (feedUrls.length === 0) {
            articles = [];
            feedErrors = [];
            message = "";
            return;
        }
        busy = true;
        // A unique marker keeps the executable engine from reusing a cached source.
        const cmd = "python3 " + quote(helper) + " --max " + Plasmoid.configuration.maxItems + " "
            + feedUrls.map(quote).join(" ") + " # " + Date.now();
        reader.connectSource(cmd);
    }
    function formatDate(timestamp, now) {
        if (!timestamp) return "";
        const date = new Date(timestamp * 1000);
        const minutes = Math.round((now - date.getTime()) / 60000);
        if (minutes < 1) return "just now";
        if (minutes < 60) return minutes + " min ago";
        if (minutes < 60 * 24) return Math.round(minutes / 60) + " h ago";
        return date.toLocaleDateString(Qt.locale(), Locale.ShortFormat) + " " + date.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
    }

    onFeedUrlsChanged: Qt.callLater(refresh)
    Component.onCompleted: refresh()

    P5Support.DataSource {
        id: reader
        engine: "executable"
        connectedSources: []
        onNewData: function(source, data) {
            disconnectSource(source);
            root.busy = false;
            if (data["exit code"] !== 0) {
                root.message = String(data.stderr || "Could not load feeds.").trim().split("\n").pop();
                return;
            }
            try {
                const result = JSON.parse(data.stdout);
                root.articles = result.items;
                root.feedErrors = result.errors;
                root.fetchedAt = result.fetched;
                clock.now = Date.now();
                root.message = "";
            } catch (error) {
                root.message = "Could not read feed results.";
            }
        }
    }
    Timer {
        interval: Math.max(5, Plasmoid.configuration.refreshMinutes) * 60000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
    // Ticks relative dates ("5 min ago") while the popup is open.
    Timer {
        id: clock
        property double now: Date.now()
        interval: 60000
        running: root.expanded
        repeat: true
        triggeredOnStart: true
        onTriggered: now = Date.now()
    }

    fullRepresentation: PlasmaExtras.Representation {
        id: popup
        Layout.preferredWidth: Kirigami.Units.gridUnit * 28
        Layout.preferredHeight: Kirigami.Units.gridUnit * 36
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 14
        collapseMarginsHint: true
        // Keep the content inside the outline instead of extending into the
        // popup margins when Plasma collapses the representation padding.
        leftPadding: 1
        rightPadding: 1
        topPadding: 1
        bottomPadding: 1

        Rectangle {
            parent: popup
            anchors.fill: parent
            z: 100
            color: "transparent"
            border.width: 1
            border.color: Kirigami.Theme.highlightColor
        }

        header: PlasmaExtras.PlasmoidHeading {
            RowLayout {
                anchors.fill: parent
                Kirigami.Heading {
                    Layout.fillWidth: true
                    level: 2
                    text: "News"
                    elide: Text.ElideRight
                }
                PC3.Label {
                    opacity: 0.7
                    text: {
                        if (root.busy) return "Updating…";
                        if (root.feedErrors.length) return root.feedErrors.length + " feed(s) failed";
                        return root.fetchedAt ? "Updated " + root.formatDate(root.fetchedAt, clock.now) : "";
                    }
                    PC3.ToolTip.text: root.feedErrors.map(e => e.url + "\n  " + e.error).join("\n")
                    PC3.ToolTip.visible: errorHover.hovered && root.feedErrors.length > 0
                    HoverHandler { id: errorHover }
                }
                PC3.ToolButton {
                    icon.name: "view-refresh"
                    enabled: !root.busy
                    onClicked: root.refresh()
                    PC3.ToolTip.text: "Refresh"
                    PC3.ToolTip.visible: hovered
                }
                PC3.ToolButton {
                    icon.name: "configure"
                    onClicked: Plasmoid.internalAction("configure").trigger()
                    PC3.ToolTip.text: "Configure feeds"
                    PC3.ToolTip.visible: hovered
                }
            }
        }

        PC3.ScrollView {
            anchors.fill: parent
            PC3.ScrollBar.horizontal.policy: PC3.ScrollBar.AlwaysOff

            ListView {
                id: list
                clip: true
                model: root.articles
                spacing: 0
                highlight: PlasmaExtras.Highlight {}
                highlightMoveDuration: 0
                currentIndex: -1

                delegate: PC3.ItemDelegate {
                    id: entry
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    padding: 5
                    hoverEnabled: true
                    onHoveredChanged: if (hovered) list.currentIndex = index
                    onClicked: if (modelData.link) Qt.openUrlExternally(modelData.link)
                    PC3.ToolTip.text: modelData.link
                    PC3.ToolTip.visible: hovered && modelData.link
                    PC3.ToolTip.delay: 1000
                    background: Item {
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Kirigami.Theme.highlightColor
                            visible: entry.index < list.count - 1
                        }
                    }

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.largeSpacing

                        Image {
                            id: picture
                            readonly property bool wanted: Plasmoid.configuration.showImages && entry.modelData.image !== ""
                            visible: wanted && status !== Image.Error
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 4.5
                            source: wanted ? entry.modelData.image : ""
                            sourceSize.width: Kirigami.Units.gridUnit * 12
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            Rectangle {
                                anchors.fill: parent
                                visible: picture.status !== Image.Ready
                                color: Kirigami.Theme.alternateBackgroundColor
                                radius: Kirigami.Units.cornerRadius
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Kirigami.Units.smallSpacing

                            PC3.Label {
                                Layout.fillWidth: true
                                text: entry.modelData.title
                                font.weight: Font.DemiBold
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }
                            PC3.Label {
                                Layout.fillWidth: true
                                text: {
                                    const date = root.formatDate(entry.modelData.timestamp, clock.now);
                                    return date ? date + "  ·  " + entry.modelData.feed : entry.modelData.feed;
                                }
                                font: Kirigami.Theme.smallFont
                                opacity: 0.7
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }
                            PC3.Label {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                text: entry.modelData.summary
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                opacity: 0.85
                                textFormat: Text.PlainText
                            }
                        }
                    }
                }

                PlasmaExtras.PlaceholderMessage {
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.gridUnit * 4
                    visible: list.count === 0
                    iconName: root.feedUrls.length === 0 ? "application-rss+xml" : (root.busy ? "view-refresh" : "dialog-warning")
                    text: root.feedUrls.length === 0 ? "No feeds configured"
                        : root.busy ? "Loading feeds…"
                        : root.message || (root.feedErrors.length ? "Feeds could not be loaded" : "No articles")
                    helpfulAction: root.feedUrls.length === 0 ? addFeedsAction : null
                    explanation: root.feedErrors.length && !root.busy ? root.feedErrors.map(e => e.url + ": " + e.error).join("\n") : ""
                }
                Kirigami.Action {
                    id: addFeedsAction
                    icon.name: "list-add"
                    text: "Add Feeds…"
                    onTriggered: Plasmoid.internalAction("configure").trigger()
                }
            }
        }
    }
}

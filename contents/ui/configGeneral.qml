pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page
    property var cfg_feedUrls: []
    property int cfg_refreshMinutes
    property int cfg_maxItems
    property bool cfg_showImages

    function addFeed() {
        let url = urlField.text.trim();
        if (!url) return;
        if (!/^[a-z]+:\/\//i.test(url)) url = "https://" + url;
        if (!/^https?:\/\//i.test(url)) {
            addError.text = "Feed URLs must start with http:// or https://";
            return;
        }
        if (page.cfg_feedUrls.indexOf(url) !== -1) {
            addError.text = "That feed is already in the list.";
            return;
        }
        page.cfg_feedUrls = page.cfg_feedUrls.concat([url]);
        urlField.text = "";
        addError.text = "";
    }
    function removeFeed(index) {
        page.cfg_feedUrls = page.cfg_feedUrls.filter((_, i) => i !== index);
    }

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Heading {
            level: 4
            text: "Feeds"
        }
        RowLayout {
            Layout.fillWidth: true
            QQC2.TextField {
                id: urlField
                Layout.fillWidth: true
                placeholderText: "https://example.com/feed.xml"
                onAccepted: page.addFeed()
                onTextChanged: addError.text = ""
            }
            QQC2.Button {
                icon.name: "list-add"
                text: "Add"
                enabled: urlField.text.trim().length > 0
                onClicked: page.addFeed()
            }
        }
        QQC2.Label {
            id: addError
            visible: text.length > 0
            color: Kirigami.Theme.negativeTextColor
        }
        QQC2.Frame {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 14
            padding: 0
            QQC2.ScrollView {
                anchors.fill: parent
                ListView {
                    id: feedList
                    clip: true
                    model: page.cfg_feedUrls
                    delegate: QQC2.ItemDelegate {
                        id: feedRow
                        required property string modelData
                        required property int index
                        width: ListView.view.width
                        contentItem: RowLayout {
                            Kirigami.Icon {
                                source: "application-rss+xml"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                text: feedRow.modelData
                                elide: Text.ElideMiddle
                            }
                            QQC2.ToolButton {
                                icon.name: "edit-delete-remove"
                                display: QQC2.AbstractButton.IconOnly
                                text: "Remove feed"
                                QQC2.ToolTip.text: text
                                QQC2.ToolTip.visible: hovered
                                onClicked: page.removeFeed(feedRow.index)
                            }
                        }
                    }
                    Kirigami.PlaceholderMessage {
                        anchors.centerIn: parent
                        width: parent.width - Kirigami.Units.gridUnit * 2
                        visible: feedList.count === 0
                        icon.name: "application-rss+xml"
                        text: "No feeds yet"
                        explanation: "Paste a feed URL above and press Add."
                    }
                }
            }
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true
            QQC2.SpinBox {
                Kirigami.FormData.label: "Refresh every (minutes):"
                from: 5
                to: 1440
                value: page.cfg_refreshMinutes
                onValueModified: page.cfg_refreshMinutes = value
            }
            QQC2.SpinBox {
                Kirigami.FormData.label: "Maximum articles:"
                from: 10
                to: 500
                stepSize: 10
                value: page.cfg_maxItems
                onValueModified: page.cfg_maxItems = value
            }
            QQC2.CheckBox {
                Kirigami.FormData.label: "Images:"
                text: "Show article pictures"
                checked: page.cfg_showImages
                onToggled: page.cfg_showImages = checked
            }
        }
    }
}

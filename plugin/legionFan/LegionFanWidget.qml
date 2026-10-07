import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property var levels: [
        { value: "silent", name: "Silent", icon: "nights_stay" },
        { value: "balanced", name: "Balanced", icon: "mode_fan" },
        { value: "performance", name: "Performance", icon: "speed" },
        { value: "max", name: "Max", icon: "air" }
    ]
    readonly property var limits: [60, 70, 80, 90, 100]

    property string level: "balanced"
    property int fan1: 0
    property int fan2: 0
    property int chargeLimit: 100
    property int capacity: 0

    function info(v) {
        for (let i = 0; i < levels.length; i++)
            if (levels[i].value === v) return levels[i];
        return levels[1];
    }

    function refresh() {
        Proc.runCommand("legionFan.read", ["sh", "-c", "exec \"$HOME/.local/bin/legion\" status --raw"], (out, code) => {
            if (code !== 0) return;
            const p = out.trim().split(/\s+/);
            root.level = p[0];
            root.fan1 = parseInt(p[2]) || 0;
            root.fan2 = parseInt(p[3]) || 0;
            root.chargeLimit = parseInt(p[5]) || 100;
            root.capacity = parseInt(p[6]) || 0;
        }, 50, undefined, root);
    }

    function run(args) {
        Proc.runCommand(null, ["sh", "-c", "exec \"$HOME/.local/bin/legion\" " + args + " -q"], (out, code) => {
            if (code !== 0)
                ToastService.showError("Legion Fan", "Command failed: legion " + args);
            root.refresh();
        }, 0, undefined, root);
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    pillRightClickAction: () => root.run("cycle")

    popoutWidth: 320
    popoutHeight: 380

    horizontalBarPill: Component {
        Row {
            DankIcon {
                name: root.info(root.level).icon
                color: root.level === "max" ? Theme.error : Theme.primary
                size: root.iconSize
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            DankIcon {
                name: root.info(root.level).icon
                color: root.level === "max" ? Theme.error : Theme.primary
                size: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            headerText: "Fan"
            detailsText: "Fan 1: " + root.fan1 + " · Fan 2: " + root.fan2 + " RPM"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                Repeater {
                    model: root.levels

                    Rectangle {
                        readonly property bool current: root.level === modelData.value
                        width: parent.width
                        height: 42
                        radius: Theme.cornerRadius
                        color: current ? Theme.primaryContainer : (ma.containsMouse ? Theme.surfaceContainerHighest : Theme.withAlpha(Theme.surfaceContainerHighest, 0))

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingM
                            spacing: Theme.spacingS
                            DankIcon {
                                name: modelData.icon
                                size: Theme.iconSize
                                color: current ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                text: modelData.name
                                font.pixelSize: Theme.fontSizeMedium
                                color: current ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.run("set " + modelData.value)
                        }
                    }
                }

                Item { width: 1; height: Theme.spacingM }

                Row {
                    spacing: Theme.spacingS
                    leftPadding: Theme.spacingS
                    DankIcon {
                        name: root.chargeLimit < 100 ? "battery_saver" : "battery_full"
                        size: Theme.iconSize
                        color: root.chargeLimit < 100 ? Theme.primary : Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "Charge limit · battery " + root.capacity + " %"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingXS

                    Repeater {
                        model: root.limits

                        Rectangle {
                            readonly property bool current: root.chargeLimit === modelData
                            width: (parent.width - Theme.spacingXS * (root.limits.length - 1)) / root.limits.length
                            height: 36
                            radius: Theme.cornerRadius
                            color: current ? Theme.primaryContainer : (cma.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData === 100 ? "Off" : modelData + "%"
                                font.pixelSize: Theme.fontSizeMedium
                                color: current ? Theme.primary : Theme.surfaceText
                            }

                            MouseArea {
                                id: cma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.run("battery " + modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}

// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.10
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0
import Liri.WaylandClient 1.0 as WC
import Fluid.Controls 1.0 as FluidControls
import "../../components" as Components

Components.BorderlessWindow {
    id: notificationWindow

    property int notificationId
    property string appName
    property string appIcon
    property alias iconUrl: imageItem.source
    property alias hasIcon: imageItem.visible
    property alias summary: titleLabel.text
    property alias body: bodyLabel.text
    property ListModel actions: ListModel {}
    property bool isPersistent: false
    property alias expireTimeout: timer.interval
    property var hints

    signal actionInvoked(string actionId)

    screen: primaryScreen

    Timer {
        id: timer

        interval: 5000
        running: !isPersistent
        onTriggered: {
            if (!isPersistent) {
                timer.running = false;
                notificationWindow.close();
            }
        }
    }

    WC.WlrLayerSurfaceV1 {
        shell: layerShell
        layer: WC.WlrLayerShellV1.TopLayer
        window: notificationWindow
        showOnAllScreens: false
        anchors: WC.WlrLayerSurfaceV1.TopAnchor |
                 WC.WlrLayerSurfaceV1.RightAnchor
        size.width: FluidControls.Units.gu(24)
        size.height: container.implicitHeight
        keyboardInteractivity: false
        topMargin: FluidControls.Units.smallSpacing
        rightMargin: FluidControls.Units.smallSpacing
        nameSpace: "notification"

        onConfigured: {
            notificationWindow.width = width;
            notificationWindow.height = height;
            console.debug("Configuring notification to " + notificationWindow.width + "x" + notificationWindow.height);
            ackConfigure(serial);
            console.debug("Acked notification configure with serial", serial);
            notificationWindow.visible = true;
        }
        onClosed: {
            notificationWindow.close();
        }
    }

    Rectangle {
        id: container

        Material.theme: Material.Dark
        Material.primary: Material.Blue
        Material.accent: Material.Blue

        anchors.left: parent.left
        anchors.right: parent.right

        color: Material.dialogColor
        radius: 2

        implicitHeight: {
            // Return maximum height possible, at least 5 grid units
            var minHeight = actionsColumn.height + (FluidControls.Units.smallSpacing * 4);
            var maxHeight = Math.max(imageItem.height, titleLabel.paintedHeight + bodyLabel.implicitHeight) + (FluidControls.Units.smallSpacing * 4);
            return Math.max(minHeight, Math.min(maxHeight, FluidControls.Units.gu(5)));
        }

        states: [
            State {
                name: "default"
                when: hasIcon && (bodyLabel.visible || actionsColumn.visible)

                AnchorChanges {
                    target: titleLabel
                    anchors.left: hasIcon ? imageItem.right : parent.left
                    anchors.top: parent.top
                    anchors.right: parent.right
                }
                PropertyChanges {
                    target: titleLabel
                    anchors.leftMargin: FluidControls.Units.smallSpacing * 2
                    anchors.topMargin: FluidControls.Units.smallSpacing
                }
            },
            State {
                name: "summaryOnly"
                when: !hasIcon && !bodyLabel.visible && !actionsColumn.visible

                AnchorChanges {
                    target: titleLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            },
            State {
                name: "summaryWithIcons"
                when: hasIcon && !bodyLabel.visible && !actionsColumn.visible

                AnchorChanges {
                    target: titleLabel
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                PropertyChanges {
                    target: titleLabel
                    anchors.leftMargin: imageItem.width + (FluidControls.Units.smallSpacing * 2)
                }
            }
        ]

        Image {
            id: imageItem

            anchors {
                left: parent.left
                top: parent.top
                leftMargin: FluidControls.Units.smallSpacing
                topMargin: FluidControls.Units.smallSpacing
            }
            width: FluidControls.Units.iconSizes.large
            height: width
            sourceSize.width: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            cache: false
            smooth: false
            visible: false
        }

        FluidControls.SubheadingLabel {
            id: titleLabel

            font.weight: Font.Bold
            elide: Text.ElideRight
            visible: text.length > 0
            onLinkActivated: {
                Qt.openUrlExternally(link);
            }
        }

        FluidControls.BodyLabel {
            id: bodyLabel

            anchors {
                left: hasIcon ? imageItem.right : parent.left
                top: titleLabel.bottom
                right: actionsColumn.visible ? actionsColumn.left : parent.right
                bottom: parent.bottom
                leftMargin: FluidControls.Units.smallSpacing * 2
                rightMargin: FluidControls.Units.smallSpacing * 2
                bottomMargin: FluidControls.Units.smallSpacing
            }
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 10
            verticalAlignment: Text.AlignTop
            visible: text.length > 0
            onLinkActivated: {
                Qt.openUrlExternally(link);
            }
        }

        Column {
            id: actionsColumn

            anchors {
                top: titleLabel.bottom
                right: parent.right
                topMargin: FluidControls.Units.smallSpacing
            }
            spacing: FluidControls.Units.smallSpacing
            height: childrenRect.height
            visible: actions.count > 0

            Repeater {
                id: actionsRepeater

                model: actions

                Button {
                    text: model.text
                    onClicked: {
                        notificationWindow.actionInvoked(model.id);
                    }
                }
            }
        }
    }
}

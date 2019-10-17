// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Controls.Material 2.0
import Fluid.Controls 1.0 as FluidControls
import Fluid.Effects 1.0 as FluidEffects
import "../components" as Components

Item {
    id: notification

    readonly property real margin: FluidControls.Units.smallSpacing * 1.5
    property alias layerSurface: layerItem.layerSurface
    property alias surface: layerItem.surface
    property alias output: layerItem.output
    readonly property real verticalMargin: layerSurface ? layerSurface.topMargin + layerSurface.bottomMargin : 0

    x: output.layers.notifications.padding
    y: {
        var top = parent.y + parent.height;
        for (var i = 0; i < parent.visibleChildren.length; i++) {
            var child = parent.visibleChildren[i];
            if (child === notification) {
                top -= (height + verticalMargin + parent.padding) * (i + 1);
                break;
            }
        }
        return top;
    }

    width: layerItem.implicitWidth + margin
    height: layerItem.implicitHeight + margin
    opacity: 0.0

    Behavior on y {
        NumberAnimation { duration: FluidControls.Units.mediumDuration }
    }

    Behavior on height {
        NumberAnimation { duration: FluidControls.Units.mediumDuration }
    }

    OpacityAnimator {
        id: showAnimation

        alwaysRunToEnd: true
        target: notification
        from: 0.0
        to: 1.0
        duration: FluidControls.Units.mediumDuration
    }

    SequentialAnimation {
        id: hideAnimation

        alwaysRunToEnd: true

        OpacityAnimator {
            target: notification
            from: 1.0
            to: 0.0
            duration: FluidControls.Units.mediumDuration
        }
        ScriptAction {
            script: {
                notification.destroy();
            }
        }
    }

    LayerSurfaceItem {
        id: layerItem

        y: notification.margin
        containerItem: notification

        layer.enabled: true
        layer.effect: FluidEffects.Elevation {
            elevation: 8
        }

        onVisibleChanged: {
            if (visible)
                showAnimation.start();
        }

        onSurfaceDestroyed: {
            bufferLocked = true;
            hideAnimation.start();
        }

        Behavior on opacity {
            NumberAnimation { duration: FluidControls.Units.mediumDuration }
        }

        // Do not capture click events, just change opacity when the pointer
        // is moved. This will make stuff underneath visible and clickable
        HoverHandler {
            onHoveredChanged: {
                layerItem.opacity = hovered ? 0.5 : 1.0;
            }
        }
    }

    Components.CloseButton {
        anchors {
            top: parent.top
            right: parent.right
        }
        onClicked: {
            layerSurface.close();
        }
    }
}

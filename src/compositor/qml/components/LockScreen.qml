// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.12
import Fluid.Controls 1.0 as FluidControls

HardwareLayerSurfaceItem {
    id: lockScreen

    stackingLevel: 0
    visible: false

    Component.onCompleted: {
        showAnimation.start();
    }

    onSurfaceDestroyed: {
        bufferLocked = true;
        hideAnimation.start();
    }

    // NOTE: The lockscreen layer surface is anchored so we move its parent instead

    SequentialAnimation {
        id: showAnimation

        alwaysRunToEnd: true

        ScriptAction {
            script: {
                output.hotCorners.enabled = false;
                lockScreen.y = -lockScreen.parent.height;
                lockScreen.visible = true;
                lockScreen.takeFocus();
            }
        }
        YAnimator {
            target: lockScreen.parent
            from: -lockScreen.parent.height
            to: 0.0
            easing.type: Easing.OutQuad
            duration: FluidControls.Units.longDuration
        }
    }

    SequentialAnimation {
        id: hideAnimation

        alwaysRunToEnd: true

        YAnimator {
            target: lockScreen.parent
            from: 0.0
            to: -lockScreen.parent.height
            easing.type: Easing.OutQuad
            duration: FluidControls.Units.mediumDuration
        }
        ScriptAction {
            script: {
                output.hotCorners.enabled = true;
                lockScreen.visible = false;
                lockScreen.destroy();
            }
        }
    }
}

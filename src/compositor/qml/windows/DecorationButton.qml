/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 *
 * $BEGIN_LICENSE:GPL3+$
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * $END_LICENSE$
 ***************************************************************************/

import QtQuick 2.0
import Fluid.Controls 1.0 as FluidControls
import Liri.private.shell 1.0 as P

Item {
    id: button

    property alias source: icon.source
    property alias color: icon.color

    signal clicked()

    width: icon.size
    height: width

    FluidControls.Icon {
        id: icon

        anchors.fill: parent
    }

    MouseArea {
        anchors.fill: parent

        hoverEnabled: true

        onEntered: shellHelper.grabCursor(P.ShellHelper.ArrowGrabCursor);
        onClicked: button.clicked()
    }
}

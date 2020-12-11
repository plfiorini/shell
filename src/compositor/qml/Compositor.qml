/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 * Copyright (C) 2017 Michael Spencer <sonrisesoftware@gmail.com>
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

import QtQml 2.1
import QtQuick 2.5
import QtQuick.Window 2.2
import QtWayland.Compositor 1.3
import Liri.WaylandServer 1.0 as WS
import Liri.Session 1.0 as Session
import Liri.Shell 1.0 as LS
import Liri.private.shell 1.0 as P
import "base"
import "components" as Components
import "components/LayerSurfaceManager.js" as LayerSurfaceManager
import "desktop"
import "windows"

WaylandCompositor {
    id: liriCompositor

    property point mousePos: Qt.point(0, 0)

    property int idleInhibit: 0

    readonly property alias screenManager: screenManager

    readonly property alias settings: settings
    readonly property alias shellSurfaces: shellSurfaces

    property var activeShellSurface: null
    readonly property bool hasMaxmizedShellSurfaces: __private.maximizedShellSurfaces > 0
    readonly property bool hasFullscreenShellSurfaces: __private.fullscreenShellSurfaces > 0

    readonly property alias shellHelper: shellHelper

    signal shellSurfaceCreated(var shellSurface)
    signal shellSurfaceDestroyed(var shellSurface)

    defaultSeat.keymap {
        layout: settings.keyboard.layouts[0] ? settings.keyboard.layouts[0] : "us"
        variant: settings.keyboard.variants[0] ? settings.keyboard.variants[0] : ""
        options: settings.keyboard.options[0] ? settings.keyboard.options[0] : ""
        model: settings.keyboard.model
        rules: settings.keyboard.rules[0] ? settings.keyboard.rules[0] : ""
    }

    onCreatedChanged: {
        if (liriCompositor.created) {
            console.debug("Compositor created");

            Session.SessionManager.setEnvironment("WAYLAND_DISPLAY", liriCompositor.socketName);

            if (xwaylandLoader.status == Loader.Ready)
                xwaylandLoader.item.startServer();

            ShellCpp.registerService();
        }
    }

    onSurfaceRequested: {
        var surface = surfaceComponent.createObject(liriCompositor, {});
        surface.initialize(liriCompositor, client, id, version);
    }

    /*
     * Window management
     */

    ListModel {
        id: shellSurfaces
    }

    QtObject {
        id: __private

        property int maximizedShellSurfaces: 0
        property int fullscreenShellSurfaces: 0

        function createShellSurfaceItem(window, component, output) {
            var parentSurfaceItem = output.viewsBySurface[window.parentSurface];
            var parent = parentSurfaceItem || output.surfacesArea;
            var item = component.createObject(parent, {
                                                  "compositor": liriCompositor,
                                                  "window": window
                                              });
            output.viewsBySurface[window.surface] = item;
            return item;
        }

        function handleShellSurfaceCreated(window, component) {
            shellSurfaces.append({"window": window});

            for (var i = 0; i < screenManager.count; i++)
                createShellSurfaceItem(window, component, screenManager.objectAt(i));

            liriCompositor.shellSurfaceCreated(window);
        }
    }

    /*
     * Output management
     */

    P.ScreenModel {
        id: screenModel
        fileName: screenConfigurationFileName
    }

    Component {
        id: outputModeComponent

        WS.WlrOutputModeV1 {}
    }

    Component {
        id: outputConfigComponent

        WS.WlrOutputConfigurationV1 {
            id: configuration

            onReadyToTest: {
                if (!screenModel.testConfiguration(configuration))
                    configuration.sendFailed();
            }
            onReadyToApply: {
                screenModel.applyConfiguration(configuration);
            }
        }
    }

    WS.WlrOutputManagerV1 {
        id: outputManager

        onConfigurationRequested: {
            var configuration = outputConfigComponent.createObject(outputManager);
            configuration.initialize(outputManager, resource);
        }
    }

    Instantiator {
        id: screenManager

        model: screenModel
        delegate: Output {
            compositor: liriCompositor
            screen: screenItem
            position: screenItem.position
            manufacturer: screenItem.manufacturer
            model: screenItem.model
            physicalSize: screenItem.physicalSize
            subpixel: screenItem.subpixel
            transform: screenItem.transform
            scaleFactor: screenItem.scaleFactor

            Component.onCompleted: {
                // Set this as default output if configured
                if (!liriCompositor.defaultOutput && screenItem.name === settings.outputs.primary)
                    liriCompositor.defaultOutput = this;

                // Fallback to the first one
                if (!liriCompositor.defaultOutput)
                    liriCompositor.defaultOutput = this;
            }
        }

        onObjectRemoved: {
            // Move all windows that fit entirely the removed output to the primary output,
            // unless the output remove is the primary one (this shouldn't happen)
            if (object === liriCompositor.defaultOutput)
                return;
            for (var surface in object.viewsBySurface) {
                var view = object.viewsBySurface[surface];
                if (view.primary && view.output === object) {
                    view.moveItem.x = liriCompositor.defaultOutput.position.x + 20;
                    view.moveItem.y = liriCompositor.defaultOutput.position.y + 20;
                }
            }
        }
    }

    Instantiator {
        id: headManager

        model: screenModel
        delegate: WS.WlrOutputHeadV1 {
            manager: outputManager
            name: screenItem.name
            description: screenItem.description
            physicalSize: screenItem.physicalSize
            position: screenItem.position
            transform: screenItem.transform
            scale: screenItem.scaleFactor

            Component.onCompleted: {
                for (var i = 0; i < screenItem.modes.length; i++) {
                    var screenMode = screenItem.modes[i];
                    var mode = outputModeComponent.createObject(this, {size: screenMode.resolution, refresh: screenMode.refreshRate});

                    addMode(mode);

                    if (screenItem.preferredMode === screenMode)
                        preferredMode = mode;

                    if (screenItem.currentMode === screenMode)
                        currentMode = mode;
                }
            }
        }
    }

    /*
     * Extensions
     */

    QtWindowManager {
        showIsFullScreen: false
        onOpenUrl: LS.Launcher.launchCommand("xdg-open %1".arg(url))
    }

    // Liri shell

    WS.LiriShell {
        id: shellHelper

        property bool isReady: false
        property WaylandSurface grabSurface: null

        onGrabSurfaceAdded: {
            grabSurface = surface;
        }
        onShortcutBound: {
            shortcutComponent.incubateObject(keyBindings, { shortcut: shortcut });
        }
        onReady: {
            isReady = true;
            for (var i = 0; i < screenManager.count; i++)
                screenManager.objectAt(i).splash.hide();
        }
        onTerminateRequested: {
            liriCompositor.quit();
        }
    }

    WS.LiriOsd {
        id: liriOsd
    }

    Component {
        id: shortcutComponent

        Shortcut {
            property WS.LiriShortcut shortcut: null

            context: Qt.ApplicationShortcut
            sequence: shortcut ? shortcut.sequence : ""
            enabled: shellHelper.isReady
            onActivated: {
                shortcut.activate();
            }
        }
    }

    // Layer shell

    Component {
        id: layerItemComponent

        Components.LayerSurfaceItem {
            onSurfaceDestroyed: {
                bufferLocked = true;
                destroy();
            }
        }
    }

    Component {
        id: modalComponent

        Components.HardwareLayerSurfaceItem {
            Keys.onEscapePressed: {
                // For some reason the client can't handle ESC so we
                // do it from the compositor
                layerSurface.close();
            }

            onSurfaceDestroyed: {
                bufferLocked = true;
                destroy();
            }
        }
    }

    Component {
        id: lockScreenComponent

        Components.LockScreen {}
    }

    Component {
        id: osdComponent

        Components.Osd {}
    }

    Component {
        id: notificationComponent

        Components.Notification {}
    }

    WS.WlrLayerShellV1 {
        id: layerShell

        onLayerSurfaceCreated: {
            // Create an item for the specified output, if none is specified create
            // an item in the default output for modal dialogs, or an item for each
            // output for the other kind of layer surfaces
            var output = layerSurface.nameSpace === "modal"
                    ? liriCompositor.defaultOutput
                    : layerSurface.output;
            if (output) {
                createItem(layerSurface, output);
            } else {
                for (var i = 0; i < screenManager.count; i++) {
                    output = screenManager.objectAt(i);
                    createItem(layerSurface, output);
                }
            }
        }

        function createItem(layerSurface, output) {
            var parent = LayerSurfaceManager.getParentForLayer(layerSurface, output);

            // Create item
            var item;
            var props = {
                "layerSurface": layerSurface,
                "surface": layerSurface.surface,
                "output": output,
                "z": LayerSurfaceManager.getLayerPriority(layerSurface),
            };
            if (layerSurface.nameSpace === "osd") {
                item = osdComponent.createObject(parent, props);
            } else if (layerSurface.nameSpace === "notification") {
                item = notificationComponent.createObject(parent, props)
            } else if (layerSurface.nameSpace === "lockscreen") {
                item = lockScreenComponent.createObject(parent, props);;
            } else if (layerSurface.nameSpace === "modal" ||
                       layerSurface.nameSpace === "modal-overlay") {
                item = modalComponent.createObject(parent, props);
            } else {
                item = layerItemComponent.createObject(parent, props);
            }

            // Calculate the geometry available to windows
            if (layerSurface.nameSpace === "panel") {
                layerSurface.configuredChanged.connect(function() {
                    output.availableGeometry.x = 0;
                    output.availableGeometry.y = 0;
                    output.availableGeometry.width = output.geometry.width;
                    output.availableGeometry.height =
                            output.geometry.height - layerSurface.height -
                            layerSurface.topMargin - layerSurface.bottomMargin;
                });
            }

            output.viewsBySurface[layerSurface.surface] = item;

            return item;
        }
    }

    // Decorations

    XdgDecorationManagerV1 {
        preferredMode: settings.ui.clientSideDecoration ? XdgToplevel.ClientSideDecoration : XdgToplevel.ServerSideDecoration
    }

    WS.KdeServerDecorationManager {
        defaultMode: settings.ui.clientSideDecoration ? WS.KdeServerDecorationManager.Client : WS.KdeServerDecorationManager.Server

        onDecorationCreated: {
            decoration.modeRequested.connect(function(mode) {
                decoration.surface.decorationMode = mode;
            });
        }
    }

    WS.LiriDecorationManager {
        onDecorationCreated: {
            decoration.foregroundColorChanged.connect(function(color) {
                decoration.surface.foregroundColor = color;
            });
            decoration.backgroundColorChanged.connect(function(color) {
                decoration.surface.backgroundColor = color;
            });
        }
    }

    // Foreign toplevel management

    WS.WlrForeignToplevelManagerV1 {
        id: foreignToplevelManager
    }

    // Screen copy

    P.ScreenCast {
        id: screenCast

        onFrameAvailable: {
            for (var i = 0; i < screenManager.count; i++) {
                var output = screenManager.objectAt(i);


                if (output.screen.screen === screen) {
                    output.exportDmabufFrame.frame(size, offset, 0, 0, drmFormat, modifier, numObjects);
                    break;
                }
            }
        }
        onObjectAvailable: {
            for (var i = 0; i < screenManager.count; i++) {
                var output = screenManager.objectAt(i);
                if (!output.exportDmabufFrame)
                    continue;

                if (output.screen.screen === screen) {
                    output.exportDmabufFrame.object(index, fd, size, offset, stride, planeIndex);
                    break;
                }
            }
        }
        onCaptureReady: {
            for (var i = 0; i < screenManager.count; i++) {
                var output = screenManager.objectAt(i);
                if (!output.exportDmabufFrame)
                    continue;

                if (output.screen.screen === screen) {
                    output.exportDmabufFrame.ready(tv_sec, tv_nsec);
                    output.exportDmabufFrame = null;
                    screenCast.disable(screen);
                    break;
                }
            }
        }
    }

    WS.WlrExportDmabufManagerV1 {
        onOutputCaptureRequested: {
            if (frame.output.screen) {
                frame.output.exportDmabufFrame = frame;
                screenCast.enable(frame.output.screen.screen);
            }
        }
    }

    WS.WlrScreencopyManagerV1 {
        onCaptureOutputRequested: {
            frame.ready.connect(function() {
                frame.copy("desktop");
                liriCompositor.flash();
            });
        }
    }

    WS.LiriColorPickerManager {
        layerName: "desktop"
    }

    // Shells

    XdgShell {
        id: xdgShell

        onToplevelCreated: {
            var window = xdgToplevelComponent.createObject(xdgShell, {"xdgSurface": xdgSurface, "toplevel": toplevel});
            __private.handleShellSurfaceCreated(window, chromeComponent);
        }
        onPopupCreated: {
            var window = xdgPopupComponent.createObject(xdgShell, {"xdgSurface": xdgSurface, "popup": popup});
            __private.handleShellSurfaceCreated(window, popupChromeComponent);
        }
    }

    WS.GtkShell {
        id: gtkShell

        onGtkSurfaceRequested: {
            var gtkSurface = gtkSurfaceComponent.createObject(gtkShell);
            gtkSurface.initialize(gtkShell, surface, resource);
        }
    }

    // Text input

    TextInputManager {}

    /*
     * D-Bus
     */

    P.MultimediaKeysServer {
        id: multimediakeysServer
    }

    P.OsdServer {
        id: osdServer

        onTextRequested: {
            liriOsd.showText(iconName, text);
        }
        onProgressRequested: {
            liriOsd.showProgress(iconName, value);
        }
    }

    /*
     * Components
     */

    // Surface component
    Component {
        id: surfaceComponent

        WaylandSurface {
            id: surface

            property int decorationMode: WS.KdeServerDecorationManager.None

            property color foregroundColor: "transparent"
            property color backgroundColor: "transparent"

            Component.onDestruction: {
                for (var i = 0; i < screenManager.count; i++)
                    delete screenManager.objectAt(i).viewsBySurface[surface];
            }
        }
    }

    // Shell surface for xdg-shell toplevel
    Component {
        id: xdgToplevelComponent

        XdgToplevelWindow {
            onMaximizedChanged: {
                if (maximized)
                    __private.maximizedShellSurfaces++;
                else
                    __private.maximizedShellSurfaces--;
            }
            onFullscreenChanged: {
                if (fullscreen)
                    __private.fullscreenShellSurfaces++;
                else
                    __private.fullscreenShellSurfaces--;
            }
        }
    }

    // Shell surface for xdg-shell popup
    Component {
        id: xdgPopupComponent

        XdgPopupWindow {}
    }

    // Custom gtk_shell surface
    Component {
        id: gtkSurfaceComponent

        WS.GtkSurface {
            id: gtkSurface

            onAppIdChanged: {
                for (var i = 0; i < shellSurfaces.count; i++) {
                    var window = shellSurfaces.get(i).window;

                    if (window.surface === gtkSurface.surface) {
                        // Move surface under this appId because for some reason Gtk+ applications
                        // are unable to provide a reliable appId via xdg-shell as opposed to gtk-shell
                        window.appId = appId;

                        break;
                    }
                }
            }
        }
    }

    // Window component
    Component {
        id: chromeComponent

        WaylandChrome {}
    }

    // Window component for popups
    Component {
        id: popupChromeComponent

        WaylandPopupChrome {}
    }

    /*
     * XWayland
     */

    Loader {
        id: xwaylandLoader
        active: true
        sourceComponent: XWayland {}
    }

    /*
     * Miscellaneous
     */

    // Holds move items in the compositor space
    Item {
        id: rootItem
    }

    LS.DateTime {
        id: dateTime
    }

    ShellSettings {
        id: settings
    }

    KeyBindings {
        id: keyBindings
    }

    Timer {
        id: idleTimer
        interval: settings.session.idleDelay * 1000
        running: true
        repeat: true
        onTriggered: {
            var i, output, idleHint = false;
            for (i = 0; i < screenManager.count; i++) {
                output = screenManager.objectAt(i);
                if (idleInhibit + output.idleInhibit == 0) {
                    output.idle();
                    idleHint = true;
                }
            }

            Session.SessionManager.idle = idleHint;
        }
    }

    /*
     * Methods
     */

    function wake() {
        var i;
        for (i = 0; i < screenManager.count; i++) {
            idleTimer.restart();
            screenManager.objectAt(i).wake();
        }

        Session.SessionManager.idle = false;
    }

    function idle() {
        var i;
        for (i = 0; i < screenManager.count; i++)
            screenManager.objectAt(i).idle();

        Session.SessionManager.idle = true;
    }

    function flash() {
        var i;
        for (i = 0; i < screenManager.count; i++)
            screenManager.objectAt(i).flash();
    }

    function activateApp(appId) {
        for (var i = 0; i < shellSurfaces.count; i++) {
            var shellSurface = shellSurfaces.get(i).window;
            if (shellSurface.appId === appId) {
                shellSurface.minimized = false;
                for (var j = 0; j < screenManager.count; j++)
                    screenManager.objectAt(j).viewsBySurface[shellSurface.surface].takeFocus();
            }
        }
    }

    function setAppMinimized(appId, minimized) {
        for (var i = 0; i < shellSurfaces.count; i++) {
            var shellSurface = shellSurfaces.get(i).window;
            if (shellSurface.appId === appId)
                shellSurface.minimized = minimized;
        }
    }

    function handleShellSurfaceDestroyed(window) {
        if (window.maximized)
            __private.maximizedShellSurfaces--;
        if (window.fullscreen)
            __private.fullscreenShellSurfaces--;

        for (var i = 0; i < shellSurfaces.count; i++) {
            if (shellSurfaces.get(i).window === window) {
                shellSurfaces.remove(i, 1);
                break;
            }
        }

        liriCompositor.shellSurfaceDestroyed(window);

        window.destroy();
    }

    function quit() {
        layerShell.closeAllSurfaces();
        shellHelper.sendQuit();

        for (var i = 0; i < screenManager.count; i++)
            screenManager.objectAt(i).window.close();

        Qt.quit();
    }
}

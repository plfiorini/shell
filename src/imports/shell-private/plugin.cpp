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

#include <QtQml>
#include <QWaylandQuickExtension>
#include <QWaylandWlShell>
#include <QWaylandXdgShellV5>

// ShellPrivate
#include "chromeitem.h"
#include "fpscounter.h"
#include "hotspot.h"
#include "indicatorsmodel.h"
#include "inputsettings.h"
#include "keyeventfilter.h"
#include "quickoutput.h"
#include "screenmodel.h"
#include "shellsurfaceitem.h"
#include "waylandwindow.h"
#include "windowmousetracker.h"

// DBusInterfaces
#include "screencast.h"

#ifndef Q_COMPOSITOR_DECLARE_QUICK_PARENT_CLASS
#define Q_COMPOSITOR_DECLARE_QUICK_PARENT_CLASS(className) \
    class Q_WAYLAND_COMPOSITOR_EXPORT className##QuickParent : public className \
    { \
/* qmake ignore Q_OBJECT */ \
        Q_OBJECT \
        Q_PROPERTY(QQmlListProperty<QObject> data READ data DESIGNABLE false) \
        Q_CLASSINFO("DefaultProperty", "data") \
    public: \
        QQmlListProperty<QObject> data() \
        { \
            return QQmlListProperty<QObject>(this, this, \
                                             &className##QuickParent::appendFunction, \
                                             &className##QuickParent::countFunction, \
                                             &className##QuickParent::atFunction, \
                                             &className##QuickParent::clearFunction); \
        } \
        static void appendFunction(QQmlListProperty<QObject> *list, QObject *object) \
        { \
            static_cast<className##QuickParent *>(list->data)->m_children.append(object); \
        } \
        static int countFunction(QQmlListProperty<QObject> *list) \
        { \
            return static_cast<className##QuickParent *>(list->data)->m_children.size(); \
        } \
        static QObject *atFunction(QQmlListProperty<QObject> *list, int index) \
        { \
            return static_cast<className##QuickParent *>(list->data)->m_children.at(index); \
        } \
        static void clearFunction(QQmlListProperty<QObject> *list) \
        { \
            static_cast<className##QuickParent *>(list->data)->m_children.clear(); \
        } \
    private: \
        QVector<QObject *> m_children; \
    };
#endif

Q_COMPOSITOR_DECLARE_QUICK_PARENT_CLASS(QuickOutput)
Q_COMPOSITOR_DECLARE_QUICK_EXTENSION_CLASS(QWaylandWlShell)
Q_COMPOSITOR_DECLARE_QUICK_PARENT_CLASS(QWaylandWlShellSurface)
Q_COMPOSITOR_DECLARE_QUICK_EXTENSION_CLASS(QWaylandXdgShellV5)
Q_COMPOSITOR_DECLARE_QUICK_PARENT_CLASS(QWaylandXdgSurfaceV5)
Q_COMPOSITOR_DECLARE_QUICK_PARENT_CLASS(QWaylandXdgPopupV5)
Q_COMPOSITOR_DECLARE_QUICK_PARENT_CLASS(WaylandWindow)

class ShellPrivatePlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")
public:
    void registerTypes(const char *uri)
    {
        // @uri Liri.private.shell
        Q_ASSERT(QLatin1String(uri) == QLatin1String("Liri.private.shell"));

        const int versionMajor = 1;
        const int versionMinor = 0;

        // Components

        qmlRegisterType<ChromeItem>(uri, versionMajor, versionMinor, "ChromeItem");
        qmlRegisterType<FpsCounter>(uri, versionMajor, versionMinor, "FpsCounter");
        qmlRegisterType<HotSpot>(uri, versionMajor, versionMinor, "HotSpot");
        qmlRegisterType<IndicatorsModel>(uri, versionMajor, versionMinor, "IndicatorsModel");
        qmlRegisterType<InputSettings>(uri, versionMajor, versionMinor, "InputSettings");
        qmlRegisterType<KeyEventFilter>(uri, versionMajor, versionMinor, "KeyEventFilter");
        qmlRegisterType<QuickOutputQuickParent>(uri, versionMajor, versionMinor, "WaylandOutput");
        qmlRegisterType<ScreenModel>(uri, versionMajor, versionMinor, "ScreenModel");
        qmlRegisterUncreatableType<ScreenMode>(uri, versionMajor, versionMinor, "ScreenMode",
                                               QStringLiteral("Cannot create instance of ScreenMode"));
        qmlRegisterUncreatableType<ScreenItem>(uri, versionMajor, versionMinor, "ScreenItem",
                                               QStringLiteral("Cannot create instance of ScreenItem"));
        qmlRegisterType<ShellSurfaceItem>(uri, versionMajor, versionMinor, "ShellSurfaceItem");
        qmlRegisterType<WaylandWindowQuickParent>(uri, versionMajor, versionMinor, "WaylandWindow");
        qmlRegisterType<WindowMouseTracker>(uri, versionMajor, versionMinor, "WindowMouseTracker");

        // Wayland protocols

        qmlRegisterType<QWaylandWlShellQuickExtension>(uri, versionMajor, versionMinor, "WlShell");
        qmlRegisterType<QWaylandWlShellSurfaceQuickParent>(uri, versionMajor, versionMinor, "WlShellSurface");

        qmlRegisterUncreatableType<QWaylandXdgShellV5>(uri, versionMajor, versionMinor, "XdgShellV5Base",
                                                       QStringLiteral("Cannot create instance of XdgShellV5Base"));
        qmlRegisterType<QWaylandXdgShellV5QuickExtension>(uri, versionMajor, versionMinor, "XdgShellV5");
        qmlRegisterType<QWaylandXdgSurfaceV5QuickParent>(uri, versionMajor, versionMinor, "XdgSurfaceV5");
        qmlRegisterType<QWaylandXdgPopupV5QuickParent>(uri, versionMajor, versionMinor, "XdgPopupV5");

        // D-Bus interfaces

        qmlRegisterType<ScreenCast>(uri, versionMajor, versionMinor, "ScreenCast");
    }
};

#include "plugin.moc"

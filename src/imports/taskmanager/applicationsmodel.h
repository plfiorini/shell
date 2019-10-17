/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2019 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
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

#ifndef APPLICATIONSMODEL_H
#define APPLICATIONSMODEL_H

#include <QAbstractListModel>

#include <Qt5GSettings/QGSettings>
#include <LiriWaylandClient/WlrForeignToplevelManagementV1>

class Application;

class ApplicationsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool hasMaximizedWindow READ hasMaximizedWindow NOTIFY hasMaximizedWindowChanged)
    Q_PROPERTY(bool hasFullscreenWindow READ hasFullscreenWindow NOTIFY hasFullscreenWindowChanged)
public:
    enum Roles {
        AppIdRole = Qt::UserRole + 1,
        ApplicationRole,
        NameRole,
        GenericNameRole,
        CommentRole,
        IconNameRole,
        CategoriesRole,
        FilterInfoRole,
        PinnedRole,
        PinnedIndexRole,
        RunningRole,
        StartingRole,
        ActiveRole,
        HasWindowsRole,
        HasCountRole,
        CountRole,
        HasProgressRole,
        ProgressRole
    };
    Q_ENUM(Roles)

    explicit ApplicationsModel(QObject *parent = nullptr);
    ~ApplicationsModel();

    bool hasMaximizedWindow() const;
    bool hasFullscreenWindow() const;

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    Q_INVOKABLE Application *get(int index) const;
    Q_INVOKABLE int indexFromAppId(const QString &appId) const;

    Q_INVOKABLE void activate(const QString &appId);
    Q_INVOKABLE bool launch(const QString &appId, const QStringList &urls = QStringList());

    static void refresh(ApplicationsModel *model);

Q_SIGNALS:
    void hasMaximizedWindowChanged();
    void hasFullscreenWindowChanged();
    void refreshed();

private:
    QtGSettings::QGSettings *m_settings = nullptr;
    WlrForeignToplevelManagerV1 *m_manager = nullptr;
    QVector<Application *> m_apps;
    QVector<WlrForeignToplevelHandleV1 *> m_maximizedHandles;
    QVector<WlrForeignToplevelHandleV1 *> m_fullscreenHandles;

    Application *findApplication(const QString &appId);
    Application *newApplication(const QString &appId);

    void changeData(Application *app, const QVector<int> &roles);

private Q_SLOTS:
    Application *addApplication(const QString &appId, const QString &category = QString());
    void removeApplication(QObject *object);

    void handleAppIdChanged(const QString &oldAppId, const QString &newAppId);
};

#endif // APPLICATIONSMODEL_H

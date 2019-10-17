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

#ifndef APPLICATION_H
#define APPLICATION_H

#include <QAbstractListModel>
#include <QLoggingCategory>
#include <QObject>
#include <QVector>

#include <LiriWaylandClient/WlrForeignToplevelManagementV1>
#include <LiriXdg/DesktopFile>

Q_DECLARE_LOGGING_CATEGORY(lcTaskManager)

class ApplicationAction : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString comment READ comment CONSTANT)
    Q_PROPERTY(QString command READ command CONSTANT)
public:
    explicit ApplicationAction(QObject *parent = nullptr);

    QString name() const;
    QString comment() const;
    QString command() const;

    Q_INVOKABLE bool execute();

private:
    QString m_name;
    QString m_comment;
    QString m_command;

    friend class Application;
};

class ApplicationActionsModel : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        CommentRole,
        CommandRole,
        ActionRole
    };
    Q_ENUM(Roles)

    explicit ApplicationActionsModel(QObject *parent = nullptr);
    ~ApplicationActionsModel();

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    void addAction(ApplicationAction *action);
    void clear();

private:
    QVector<ApplicationAction *> m_actions;
};

class Application : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString appId READ appId CONSTANT)
    Q_PROPERTY(bool valid READ isValid NOTIFY validChanged)
    Q_PROPERTY(QString name READ name NOTIFY dataChanged)
    Q_PROPERTY(QString genericName READ genericName NOTIFY dataChanged)
    Q_PROPERTY(QString comment READ comment NOTIFY dataChanged)
    Q_PROPERTY(QString iconName READ iconName NOTIFY dataChanged)
    Q_PROPERTY(QStringList categories READ categories NOTIFY dataChanged)
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool running READ isRunning NOTIFY stateChanged)
    Q_PROPERTY(bool starting READ isStarting NOTIFY stateChanged)
    Q_PROPERTY(bool active READ isActive NOTIFY activeChanged)
    Q_PROPERTY(bool pinned READ isPinned WRITE setPinned NOTIFY pinnedChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
public:
    enum State
    {
        //! The application is not running
        NotRunning,
        //! The application was launched and it's starting up.
        Starting,
        //! The application is currently running.
        Running,
        //! The application is in the background and it was suspended by
        //! the system to save resources.
        Suspended,
        //! The application is in the background and its activity was
        //! stopped by the system in order to save resources, acts as
        //! being closed but the state is saved on disk and can be
        //! restored.
        Stopped
    };
    Q_ENUM(State)

    explicit Application(const QString &appId, QObject *parent = nullptr);
    ~Application();

    QString appId() const;
    bool isValid() const;

    QString name() const;
    QString genericName() const;
    QString comment() const;
    QString iconName() const;
    QStringList categories() const;
    bool hasCategory(const QString &category) const;

    State state() const;

    bool isRunning() const;
    bool isStarting() const;

    bool isActive() const;

    bool isPinned() const;
    void setPinned(bool pinned);

    int count() const;
    int progress() const;

    ApplicationActionsModel *actionsModel() const;

    Q_INVOKABLE void refresh();

    Q_INVOKABLE void setRectangle(QWindow *window, const QRect &rect);

    Q_INVOKABLE void setMinimized();
    Q_INVOKABLE void unsetMinimized();
    Q_INVOKABLE void toggleMinimized();

    Q_INVOKABLE void activate();

    Q_INVOKABLE bool launch(const QStringList &urls = QStringList());

    Q_INVOKABLE bool quit();

Q_SIGNALS:
    void validChanged();
    void dataChanged();
    void stateChanged(Application::State state);
    void activeChanged(bool active);
    void pinnedChanged(bool pinned);
    void countChanged(int count);
    void progressChanged(int progress);
    void launched();

private:
    QString m_appId;
    Liri::DesktopFile *m_desktopFile = nullptr;
    ApplicationActionsModel *m_actionsModel = nullptr;
    QStringList m_categories;
    State m_state = NotRunning;
    bool m_active = false;
    bool m_pinned = false;
    int m_count = 0;
    int m_progress = 0;
    QVector<WlrForeignToplevelHandleV1 *> m_handles;

    void setState(State state);
    void setActive(bool active);

    void addHandle(WlrForeignToplevelHandleV1 *handle);
    void removeHandle(WlrForeignToplevelHandleV1 *handle);

    friend class ApplicationsModel;

private Q_SLOTS:
    void handleClosed();
};

#endif // APPLICATION_H

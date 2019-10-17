// SPDX-FileCopyrightText: 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

#ifndef LIRI_SHELL_AUTHENTICATOR_H
#define LIRI_SHELL_AUTHENTICATOR_H

#include <QObject>

struct pam_message;
struct pam_response;

class Authenticator : public QObject
{
    Q_OBJECT
public:
    explicit Authenticator(QObject *parent = nullptr);

public Q_SLOTS:
    void authenticate(const QString &password);

Q_SIGNALS:
    void authenticationSucceded();
    void authenticationFailed();
    void authenticationError();

private:
    pam_response *m_response;

    static int conversationHandler(int num, const pam_message **message,
                                   pam_response **response, void *data);
};

#endif // LIRI_SHELL_AUTHENTICATOR_H

include(CheckIncludeFile)
check_include_file("sys/prctl.h" HAVE_SYS_PRCTL_H)

if(LIRI_ENABLE_SYSTEMD)
    find_package(Libsystemd)
endif()

find_package(PAM REQUIRED)

if(NOT TARGET Liri::Qt5GSettings)
    find_package(Qt5GSettings REQUIRED)
endif()
if(NOT TARGET Liri::PlatformHeaders)
    find_package(Liri1PlatformHeaders REQUIRED)
endif()
if(NOT TARGET Liri::Logind)
    find_package(Liri1Logind REQUIRED)
endif()
if(NOT TARGET Liri::LocalDevice)
    find_package(Liri1LocalDevice REQUIRED)
endif()
if(NOT TARGET Liri::Xdg)
    find_package(Liri1Xdg REQUIRED)
endif()

set(LiriShell_DEFINES "")
set(LiriShell_LIBRARIES "")
if(LIRI_SHELL_DEVELOPMENT_BUILD)
    list(APPEND LiriShell_DEFINES "DEVELOPMENT_BUILD")
endif()
if(HAVE_SYS_PRCTL_H)
    list(APPEND LiriShell_DEFINES "HAVE_SYS_PRCTL_H")
endif()
if(LIRI_ENABLE_SYSTEMD)
    if(TARGET PkgConfig::Libsystemd)
        list(APPEND LiriShell_DEFINES "HAVE_SYSTEMD")
        list(APPEND LiriShell_LIBRARIES "PkgConfig::Libsystemd")
    endif()
endif()

include(LiriCreateGitHeadRevisionFile)
liri_create_git_head_revision_file("gitsha1.h")

# Translations
file(GLOB LiriShell_TRANSLATIONS "${CMAKE_CURRENT_SOURCE_DIR}/translations/*_*.ts")
qt5_add_translation(LiriShell_QM_FILES ${LiriShell_TRANSLATIONS})
install(FILES ${LiriShell_QM_FILES}
        DESTINATION "${INSTALL_DATADIR}/liri-shell/translations")

liri_add_executable(LiriShell
    OUTPUT_NAME
        "liri-shell"
    INSTALL_DIRECTORY
        "${INSTALL_LIBEXECDIR}"
    SOURCES
        application.cpp
        application.h
        main.cpp
        multimediakeys/multimediakeys.cpp
        multimediakeys/multimediakeys.h
        onscreendisplay.cpp
        onscreendisplay.h
        sessionmanager/authenticator.cpp
        sessionmanager/authenticator.h
        sessionmanager/qmlauthenticator.cpp
        sessionmanager/qmlauthenticator.h
        sessionmanager/sessionmanager.cpp
        sessionmanager/sessionmanager.h
        sessionmanager/loginmanager/fakebackend.cpp
        sessionmanager/loginmanager/fakebackend.h
        sessionmanager/loginmanager/logindbackend.cpp
        sessionmanager/loginmanager/logindbackend.h
        sessionmanager/loginmanager/loginmanagerbackend.cpp
        sessionmanager/loginmanager/loginmanagerbackend.h
        sessionmanager/loginmanager/loginmanager.cpp
        sessionmanager/loginmanager/loginmanager.h
        sessionmanager/screensaver/screensaver.cpp
        sessionmanager/screensaver/screensaver.h
        ${LiriShell_QM_FILES}
    RESOURCES
        "compositor.qrc"
    QTQUICK_COMPILER
        ${LIRI_SHELL_ENABLE_QTQUICK_COMPILER}
    DBUS_ADAPTOR_SOURCES
        "${CMAKE_CURRENT_SOURCE_DIR}/sessionmanager/screensaver/org.freedesktop.ScreenSaver.xml"
    DEFINES
        QT_NO_CAST_FROM_ASCII
        QT_NO_FOREACH
        QT_WAYLAND_COMPOSITOR_QUICK
        LIRISHELL_VERSION="${PROJECT_VERSION}"
        ${LiriShell_DEFINES}
    LIBRARIES
        Qt5::Core
        Qt5::Concurrent
        Qt5::DBus
        Qt5::Gui
        Qt5::Svg
        Qt5::Qml
        Qt5::Quick
        Qt5::QuickControls2
        Qt5::WaylandCompositor
        Liri::Qt5GSettings
        Liri::PlatformHeaders
        Liri::Logind
        Liri::LocalDevice
        Liri::Xdg
        shell-privateplugin
        ${PAM_LIBRARIES}
        ${LiriShell_LIBRARIES}
)

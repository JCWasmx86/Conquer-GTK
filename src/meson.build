conquer_lib_sources = [
    'model/scenario.vala',
    'model/scenarioloader.vala',
    'model/context.vala',
    'model/gamestate.vala',
    'model/citygraph.vala',
    'model/clan.vala',
    'model/city.vala',
    'model/resource.vala',
    'model/messagequeue.vala',
    'model/message/initmessage.vala',
    'model/message/message.vala',
    'model/message/attackmessage.vala',
    'model/message/movemessage.vala',
    'model/message/startgamemessage.vala',
    'model/message/configurationupdatedmessage.vala',
    'model/message/configloadedmessage.vala',
    'model/message/endgamemessage.vala',
    'model/message/newroundmessage.vala',
    'model/saver.vala',
    'model/config.vala',
    'model/configloader.vala',
]
conquer_sources = [
    'main.vala',
    'application.vala',
    'window.vala',
    'mainscreen.vala',
    'newselectionscreen.vala',
    'screen.vala',
    'map.vala',
    'cityactions.vala',
    'cityinfo.vala',
    'diagram.vala',
    'claninfo.vala',
    'config.vala',
    'databaselistener.vala',
    'statistics.vala',
]

conquer_lib_deps = [
    dependency('gio-2.0'),
    dependency('libpeas-1.0'),
    dependency('zlib'),
    dependency('json-glib-1.0'),
]

conquer_lib = static_library(
    'conquerlib',
    conquer_lib_sources,
    dependencies: conquer_lib_deps,
    install: true,
)
# Hack for https://github.com/mesonbuild/meson/issues/1229
conquer_lib_build_dir = include_directories('.')

subdir('model/default')

conquer_deps = [
    dependency('gtk4'),
    dependency('libadwaita-1'),
    dependency('gio-2.0'),
    dependency('libpeas-1.0'),
    dependency('gstreamer-1.0'),
    dependency('sqlite3'),
    meson.get_compiler('c').find_library('m', required: false),
]

conquer_sources += conquer_resources

executable(
    'conquer',
    conquer_sources,
    dependencies: conquer_deps,
    link_with: conquer_lib,
    c_args: '-DGETTEXT_PACKAGE="conquer"',
    install: true,
)

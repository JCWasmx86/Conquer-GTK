conquer_lib_sources = [
    'model/scenario.vala',
    'model/scenarioloader.vala',
    'model/context.vala',
]
conquer_sources = [
    'main.vala',
    'application.vala',
    'window.vala',
    'mainscreen.vala',
    'newselectionscreen.vala',
]

conquer_lib_deps = [
    dependency('gio-2.0'),
    dependency('libpeas-1.0'),
]

conquer_lib = static_library('conquerlib',
    conquer_lib_sources,
    dependencies: conquer_lib_deps,
    install: true,
)
# Hack for https://github.com/mesonbuild/meson/issues/1229
conquer_lib_build_dir = meson.current_build_dir()

subdir('model/default')

conquer_deps = [
    dependency('gtk4'),
    dependency('libadwaita-1'),
    dependency('gio-2.0'),
    dependency('libpeas-1.0'),
]

conquer_sources += gnome.compile_resources(
    'conquer-resources',
    'conquer.gresource.xml',
    c_name: 'conquer',
)

executable(
    'conquer',
    conquer_sources,
    dependencies: conquer_deps,
    link_with: conquer_lib,
    install: true,
)

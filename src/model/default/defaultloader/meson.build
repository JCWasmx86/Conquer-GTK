install_data('defaultloader.plugin', install_dir: plugin_install_dir)
defaultloader_sources = [
    'defaultloader.vala',
    'defaultscenario.vala',
]
shared_module(
    'defaultloader',
    defaultloader_sources,
    dependencies: conquer_lib_deps + dependency('libarchive') + dependency(
        'json-glib-1.0',
    ),
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

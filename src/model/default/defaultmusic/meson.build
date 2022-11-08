install_data('defaultmusic.plugin', install_dir: plugin_install_dir)
defaultmusic_sources = [
    'defaultmusic.vala'
]
shared_module(
    'defaultmusic',
    defaultmusic_sources,
    dependencies: conquer_lib_deps + dependency('gstreamer-1.0'),
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

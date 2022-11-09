install_data('defaultsaver.plugin', install_dir: plugin_install_dir)
defaultsaver_sources = ['defaultsaver.vala']
shared_module(
    'defaultsaver',
    defaultsaver_sources,
    dependencies: conquer_lib_deps + dependency('gstreamer-1.0'),
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

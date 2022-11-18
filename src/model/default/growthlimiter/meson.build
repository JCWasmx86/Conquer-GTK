install_data('growthlimiter.plugin', install_dir: plugin_install_dir)
growthlimiter_sources = ['growthlimiter.vala']
shared_module(
    'growthlimiter',
    growthlimiter_sources,
    dependencies: conquer_lib_deps + dependency('gee-0.8'),
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

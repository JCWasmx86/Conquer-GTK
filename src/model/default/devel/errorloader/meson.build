install_data('errorloader.plugin', install_dir: plugin_install_dir)
errorloader_sources = [
    'errorloader.vala',
]
shared_module(
    'errorloader',
    errorloader_sources,
    dependencies: conquer_lib_deps,
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

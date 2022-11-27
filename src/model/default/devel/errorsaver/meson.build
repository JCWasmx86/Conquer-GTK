install_data('errorsaver.plugin', install_dir: plugin_install_dir)
errorsaver_sources = [
    'errorsaver.vala',
]
shared_module(
    'errorsaver',
    errorsaver_sources,
    dependencies: conquer_lib_deps,
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

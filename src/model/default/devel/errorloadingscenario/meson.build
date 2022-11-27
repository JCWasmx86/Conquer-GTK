install_data('errorloadingscenario.plugin', install_dir: plugin_install_dir)
errorloadingscenario_sources = [
    'errorloadingscenario.vala',
]
shared_module(
    'errorloadingscenario',
    errorloadingscenario_sources,
    dependencies: conquer_lib_deps,
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

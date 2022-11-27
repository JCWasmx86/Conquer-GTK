install_data('errorsavelister.plugin', install_dir: plugin_install_dir)
errorsavelister_sources = [
    'errorsavelister.vala',
]
shared_module(
    'errorsavelister',
    errorsavelister_sources,
    dependencies: conquer_lib_deps,
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

install_data('defaultalgorithms.plugin', install_dir: plugin_install_dir)
defaultalgorithms_sources = [
    'nullalgorithm.vala',
    'defaultalgorithms.vala',
]
shared_module(
    'defaultalgorithms',
    defaultalgorithms_sources,
    dependencies: conquer_lib_deps,
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

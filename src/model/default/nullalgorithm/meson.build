install_data('nullalgorithm.plugin', install_dir: plugin_install_dir)
nullalgorithm_sources = [
    'nullalgorithm.vala'
]
shared_module(
    'nullalgorithm',
    nullalgorithm_sources,
    dependencies: conquer_lib_deps,
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

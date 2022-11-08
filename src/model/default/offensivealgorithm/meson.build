install_data('offensivealgorithm.plugin', install_dir: plugin_install_dir)
offensivealgorithm_sources = ['offensivealgorithm.vala']
shared_module(
    'offensivealgorithm',
    offensivealgorithm_sources,
    dependencies: conquer_lib_deps,
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

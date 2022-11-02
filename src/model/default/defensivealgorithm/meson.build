install_data('defensivealgorithm.plugin', install_dir: plugin_install_dir)
defensivealgorithm_sources = [
    'defensivealgorithm.vala'
]
shared_module(
    'defensivealgorithm',
    defensivealgorithm_sources,
    dependencies: conquer_lib_deps,
    link_with: conquer_lib,
    install_dir: plugin_install_dir,
    include_directories: conquer_lib_build_dir,
    install: true,
)

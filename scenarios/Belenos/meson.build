files = [
    'map.json',
    'metadata.json',
    'players.json',
]
custom_target(
    'Belenos',
    input: files,
    output: 'belenos.scenario',
    command: [zip, '@OUTPUT0@', '@INPUT@'],
    install: true,
    install_dir: scenario_install_dir,
)

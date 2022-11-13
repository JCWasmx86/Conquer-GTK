files = [
    'map.json',
    'metadata.json',
    'players.json',
    'cities.json',
    'map.png',
    'architecture-and-city.png',
    'castle.png',
    'castle(1).png',
    'castle(2).png',
    'castle(3).png',
    'cultures.png',
    'fortress.png',
    'fortress(1).png',
    'fortress(2).png',
    'medieval.png',
    'medieval(1).png',
    'background.png',
]
custom_target(
    'Belenos',
    input: files,
    output: 'belenos.scenario',
    command: [zip, '@OUTPUT0@', '@INPUT@'],
    install: true,
    install_dir: scenario_install_dir,
)

foreach json_file : json_files
    test('test_belenos_' + json_file, json_glib_format, args: files(json_file))
endforeach
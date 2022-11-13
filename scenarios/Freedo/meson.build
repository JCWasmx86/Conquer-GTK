files = [
    'map.json',
    'metadata.json',
    'players.json',
    'cities.json',
    'background.png',
    'architecture-and-city.png',
    'fortress.png',
    'fortress(1).png',
    'fortress(2).png',
    'medieval.png',
    'medieval(1).png',
    'stadt1.png',
    'stadt2.png',
    'stadt3.png',
    'stadt4.png',
    'stadt5.png',
]
custom_target(
    'Freedo',
    input: files,
    output: 'freedo.scenario',
    command: [zip, '@OUTPUT0@', '@INPUT@'],
    install: true,
    install_dir: scenario_install_dir,
)

foreach json_file : json_files
    test('test_freedo_' + json_file, json_glib_format, args: files(json_file))
endforeach
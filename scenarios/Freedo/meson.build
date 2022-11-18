files = [
    'map.json',
    'metadata.json',
    'players.json',
    'cities.json',
    'background.png',
    'Alexandrjna.png',
    'Argo.png',
    'Aurora.png',
    'Den.png',
    'Epsi.png',
    'Finitia.png',
    'Initia.png',
    'Lamda.png',
    'Medianes.png',
    'Nisentara.png',
    'Rhomortina.png',
    'Terre.png',
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

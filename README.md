# Lancet

[![CI](https://github.com/Sam-DarkBall-Mods/Lancet/actions/workflows/ci.yml/badge.svg)](https://github.com/Sam-DarkBall-Mods/Lancet/actions/workflows/ci.yml)

Lancet loitering munition and launcher system for Arma 3.

## Requirements

- Arma 3 2.22 or newer
- Additional runtime dependencies declared by `CfgPatches`

## Development

```bash
hemtt check
hemtt build --no-bin
python3 -B -m unittest discover -s tests -p "test_*.py" -v
```

Legacy `CfgPatches`, function names, virtual PBO prefixes, and release PBO
filenames are compatibility contracts and must not change in a patch release.

## License

SQF, Arma configuration, and tooling are GPL-2.0-or-later. Original Arma
models, textures, materials, animations, and audio are APL-SA. See
[LICENSES.md](LICENSES.md) and closer notices.

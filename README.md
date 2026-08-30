# Lancet

[![CI](https://github.com/Sam-DarkBall-Mods/Lancet/actions/workflows/ci.yml/badge.svg)](https://github.com/Sam-DarkBall-Mods/Lancet/actions/workflows/ci.yml)

This mod contains Lancet and Izdelie 53 loitering munitions. Both can be
launched from tripod systems carried in backpacks. The control scripts handle
the seeker display, mouse steering, speed changes, target search and target
lock.

## Requirements

- Arma 3 2.22 or newer
- CBA_A3
- `sdreal_uav`

## Building

```bash
python3 -B -m unittest discover -s tests -p "test_*.py" -v
hemtt check
hemtt build --no-bin
```

The PBO remains `lk_lancet.pbo` with the `lk_lancet` prefix. Existing
mission scripts depend on those names.

## License

Code and configs use GPL-2.0-or-later. Original models, textures, materials,
animations and audio use APL-SA. See [LICENSES.md](LICENSES.md).

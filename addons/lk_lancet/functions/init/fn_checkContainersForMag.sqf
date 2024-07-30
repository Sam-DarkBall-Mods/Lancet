params ["_object"];

private _playerPos = getPosATL _object;
private _containers = nearestObjects [_playerPos, ["All"], 15];
private _found = false;

{
    private _mags = getMagazineCargo _x # 0;
    private _magType = ["lancet_dummy_mag", "izdelie_dummy_mag"] select ((typeOf _object) == "izdelie_tripod_launcher");
    if (_magType in _mags) then {
        _found = true;
    };
} forEach _containers;

_found;

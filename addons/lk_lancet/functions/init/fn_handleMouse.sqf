#include "..\includes.hpp"

#define GRID_W( num ) ( num * ( pixelGridNoUIScale * pixelW * 2 ))
#define GRID_H( num ) ( num * ( pixelGridNoUIScale * pixelH * 2 ))

params [["_display", displayNull], ["_xDelta", 0], ["_yDelta", 0]];

private _lockPicture = uiNamespace getVariable ["DB_seeker_lock", controlNull];

private _width = GRID_W(7);
private _height = GRID_H(7);

if (isNull _lockPicture) then {
    _lockPicture = _display ctrlCreate ["RscPicture", -1];
    _lockPicture ctrlSetText "\lk_lancet\pictures\targetLock.paa";
    _lockPicture ctrlSetPosition [0.5 - _width / 2, 0.5 - _height / 2, _width, _height];
    _lockPicture ctrlSetTextColor [1,1,1,1];
    _lockPicture ctrlCommit 0;
    uiNamespace setVariable ["DB_seeker_lock", _lockPicture];
};

if ((uiNamespace getVariable ["isSlewing", false]) || {uiNamespace getVariable ["DB_isSlewing", false]}) exitWith {};

uiNamespace setVariable ["lancet_lastMouseEvent", diag_tickTime];

private _stick = uiNamespace getVariable ["lancet_mouseStick", [0, 0]];
private _zoomEnabled = uiNamespace getVariable ["_zoomStatus", false];
private _zoomInputScale = if (_zoomEnabled) then {0.25} else {1};

private _xSens = 0.55;
private _ySens = 0.55;

private _nextX = (_stick # 0) + (_xDelta * _xSens * _zoomInputScale);
private _nextY = (_stick # 1) - (_yDelta * _ySens * _zoomInputScale);

_nextX = _nextX max -1 min 1;
_nextY = _nextY max -1 min 1;

uiNamespace setVariable ["lancet_mouseStick", [_nextX, _nextY]];

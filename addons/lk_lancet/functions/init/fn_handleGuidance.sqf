params [
	["_projectile", objNull, [objNull]],
	["_v", [0, 1, 0], [[]]],
	["_responseTime", 0.2, [0]],
	["_dt", 0.02, [0]]
];

if (isNull _projectile) exitWith {};
if !(_v isEqualType [] && {count _v == 3}) exitWith {};

if (_responseTime <= 0) then {
	_responseTime = 0.01;
};
if (_dt <= 0) then {
	_dt = 0.01;
};

private _curDir = vectorDir _projectile;
private _curUp = vectorUp _projectile;
private _desiredDir = vectorNormalized _v;

private _right = [0, 0, 1] vectorCrossProduct _desiredDir;
if ((vectorMagnitudeSqr _right) < 0.000001) then {
	_right = [1, 0, 0];
} else {
	_right = vectorNormalized _right;
};
private _desiredUp = vectorNormalized (_desiredDir vectorCrossProduct _right);

private _alpha = (_dt / _responseTime) max 0 min 1;

private _newDirRaw = (_curDir vectorMultiply (1 - _alpha)) vectorAdd (_desiredDir vectorMultiply _alpha);
if ((vectorMagnitudeSqr _newDirRaw) < 0.000001) exitWith {};
private _newDir = vectorNormalized _newDirRaw;

private _newUpRaw = (_curUp vectorMultiply (1 - _alpha)) vectorAdd (_desiredUp vectorMultiply _alpha);
private _side = _newDir vectorCrossProduct _newUpRaw;
if ((vectorMagnitudeSqr _side) < 0.000001) then {
	_side = _newDir vectorCrossProduct [0, 0, 1];
	if ((vectorMagnitudeSqr _side) < 0.000001) then {
		_side = [1, 0, 0];
	};
};
_side = vectorNormalized _side;

private _newUp = vectorNormalized (_side vectorCrossProduct _newDir);
_projectile setVectorDirAndUp [_newDir, _newUp];

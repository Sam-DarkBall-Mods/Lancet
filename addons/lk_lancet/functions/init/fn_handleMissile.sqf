#include "..\includes.hpp"
//params["_projectile", "_offset", "_speedArr"];

private _projectile = param [0,objNull];
private _offset 	= param [1, 2.0];
private _speedArr 	= param [2, []];
private _dialogName = param [3, "lancet_seeker"];

//Handle camera
private _camera = [_projectile, 2.0] call lancet_fnc_camCreate; // 2.0 def

//Create dialog
private _diag = createDialog ["lancet_seeker", true];

//Change FOV / thermals / autolock
uiNamespace setVariable ["isSlewing", false];
uiNamespace setVariable ["_mainCamera", _camera];
uiNamespace setVariable ["_thermalState", true];
uiNamespace setVariable ["_autoLockState", true];
uiNamespace setVariable ["_zoomStatus", false];
uiNamespace setVariable ["_itemLock", false];
uiNamespace setVariable ["DB_isSlewing", false];
uiNamespace setVariable ["lancet_mouseStick", [0, 0]];
uiNamespace setVariable ["lancet_mouseStickSmoothed", [0, 0]];
uiNamespace setVariable ["lancet_lastMouseEvent", diag_tickTime];

//Current projectile for manual detonation
uiNamespace setVariable ["lancet_currentProjectile", _projectile];

//Missile stuff
//Main variables
private _target = objNull;
private _posProj = []; //Projectile pos
private _posWorld = []; //World target position
private _v = []; //Target versor (from projectile)
private _timeManouver = 0; //Time for manouver
private _timeCheck = time; //Time now
private _targetEnabled = true; //Smart targetting
private _crossTarget = []; //Position for the crosshair
private _crtlSize = []; //Size of the control thing 
private _wordToScreenPos = []; //Position on the screen of the current target
private _targetOffset = [0,0,0]; //Offset from target center 
private _targetArr = []; 

private _lastControlUpdate = diag_tickTime;
private _returnRate = 2.0;
private _steerYawRate = 6.8;
private _steerPitchRate = 7.2;
private _zoomSteerScale = 0.45;
private _zoomCursorScale = 0.55;
private _manualVectorDist = 1200;
private _cursorRangeX = 0.18;
private _cursorRangeY = 0.18;
private _guideTick = 0.02;
private _nextGuideAt = 0;
private _manualInputDeadZone = 0.01;
private _lastMousePos = getMousePosition;

//Fast cleanup when the missile dies
_projectile setVariable ["_projAttachedCamera", _camera, true];
_projectile addEventHandler ["Explode", {
	params ["_projectile"];
	//_camera is saved to uiNamespace meaning if you are using another projectile it's overwritten
	_camera = uiNamespace getVariable "_mainCamera";
	_attachedCam = _projectile getVariable "_projAttachedCamera";

	private _uav_temp = _projectile getVariable ["DB_lancet_subUAV", objNull];
	deleteVehicle _uav_temp;

	if(_camera == _attachedCam) then {
		[_camera] call lancet_fnc_cleanEffectsCam;
	};
}];

_projectile addEventHandler ["Explode", {
	[] spawn {
		if (isNull (uiNamespace getVariable ["_mainCamera", objNull])) exitWith {};
		
		PP_film = ppEffectCreate ["FilmGrain",2000]; 
		PP_film ppEffectAdjust [1,0,0,1.03,1.05,true];
		PP_film ppEffectCommit 0;
		PP_film ppEffectEnable true;

		waitUntil {isNull (uiNamespace getVariable "_mainCamera")};


		PP_film = ppEffectCreate ["FilmGrain",2000]; 
		PP_film ppEffectAdjust [1,0,0,1.03,1.05,true];
		PP_film ppEffectCommit 0;
		PP_film ppEffectEnable true;

		sleep 0.8;

		ppEffectDestroy PP_film;
	};
}];

//Effects
[] call lancet_fnc_handleEffects;

//Detect button presses
[_diag] call lancet_fnc_dialogEventHandlers;

if(count _speedArr > 0) then {
	[_projectile, _speedArr] spawn lancet_fnc_handleSpeed;
};

//Updates all the text values for the seeker
[_diag, _projectile] spawn lancet_fnc_handleText;

//Target cursor box and crosshair
private _crosshair = _diag displayCtrl seeker_head;
private _targetCursor = _diag displayCtrl target_cursor;
_targetCursor ctrlShow false;

//Main loop
while {alive _projectile and dialog} do {
	if(time - _timeCheck > _guideTick) then {
		_targetEnabled = uiNamespace getVariable ["_autoLockState", true];

		if(!_targetEnabled) then {
			_target = objNull;
			_targetOffset = [0,0,0]; 
		};

		private _isAutoSlewing = uiNamespace getVariable ["DB_isSlewing", false];
		if (!_isAutoSlewing) then {
			private _nowTick = diag_tickTime;
			private _dt = _nowTick - _lastControlUpdate;
			_lastControlUpdate = _nowTick;

			private _lastMouseEventAt = uiNamespace getVariable ["lancet_lastMouseEvent", 0];
			if ((_nowTick - _lastMouseEventAt) > 0.05) then {
				private _mousePos = getMousePosition;
				private _mouseDx = (_mousePos # 0) - (_lastMousePos # 0);
				private _mouseDy = (_mousePos # 1) - (_lastMousePos # 1);
				_lastMousePos = _mousePos;

				if ((abs _mouseDx) > 0.000001 || {(abs _mouseDy) > 0.000001}) then {
					[_diag, _mouseDx, _mouseDy] call lancet_fnc_handleMouse;
				};
			} else {
				_lastMousePos = getMousePosition;
			};

			private _stick = uiNamespace getVariable ["lancet_mouseStick", [0, 0]];
			private _zoomEnabled = uiNamespace getVariable ["_zoomStatus", false];
			private _steerScale = if (_zoomEnabled) then {_zoomSteerScale} else {1};
			private _cursorScale = if (_zoomEnabled) then {_zoomCursorScale} else {1};
			private _spring = 1 - (_returnRate * _dt);
			if (_spring < 0) then {
				_spring = 0;
			};

			private _stickX = (_stick # 0) * _spring;
			private _stickY = (_stick # 1) * _spring;
			if (abs _stickX < 0.002) then { _stickX = 0; };
			if (abs _stickY < 0.002) then { _stickY = 0; };

			_stick = [_stickX, _stickY];
			uiNamespace setVariable ["lancet_mouseStick", _stick];

			private _smoothedStick = uiNamespace getVariable ["lancet_mouseStickSmoothed", [0, 0]];
			private _smoothRate = if (_zoomEnabled) then {6} else {10};
			private _smoothAlpha = (_dt * _smoothRate) max 0 min 1;
			private _ctrlX = (_smoothedStick # 0) + ((_stickX - (_smoothedStick # 0)) * _smoothAlpha);
			private _ctrlY = (_smoothedStick # 1) + ((_stickY - (_smoothedStick # 1)) * _smoothAlpha);
			_smoothedStick = [_ctrlX, _ctrlY];
			uiNamespace setVariable ["lancet_mouseStickSmoothed", _smoothedStick];

			private _seekerLock = uiNamespace getVariable ["DB_seeker_lock", controlNull];
			if !(isNull _seekerLock) then {
				private _lockPos = ctrlPosition _seekerLock;
				private _lockW = _lockPos # 2;
				private _lockH = _lockPos # 3;

				private _newX = (0.5 - (_lockW / 2)) + (_ctrlX * _cursorRangeX * _cursorScale);
				private _newY = (0.5 - (_lockH / 2)) - (_ctrlY * _cursorRangeY * _cursorScale);
				_newX = _newX max safeZoneX min (safeZoneX + safeZoneW - _lockW);
				_newY = _newY max safeZoneY min (safeZoneY + safeZoneH - _lockH);

				_seekerLock ctrlSetPosition [_newX, _newY, _lockW, _lockH];
				_seekerLock ctrlCommit 0;
			};

			if (time >= _nextGuideAt) then {
				_posProj = AGLTOASL positionCameraToWorld [0,0,0];
				private _absX = abs _ctrlX;
				private _absY = abs _ctrlY;
				private _yawAssist = (1 - (_absY * 0.55)) max 0.45;
				private _pitchAssist = (1 - (_absX * 0.20)) max 0.65;
				private _yawCmd = _ctrlX * _yawAssist;
				private _pitchCmd = _ctrlY * _pitchAssist;
				private _manualActive = (_absX > _manualInputDeadZone) || {(_absY > _manualInputDeadZone)};

				private _forward = vectorNormalized (vectorDir _projectile);
				private _worldUp = [0, 0, 1];
				private _right = _forward vectorCrossProduct _worldUp;
				if ((vectorMagnitudeSqr _right) < 0.000001) then {
					_right = _forward vectorCrossProduct (vectorUp _projectile);
				};
				if ((vectorMagnitudeSqr _right) < 0.000001) then {
					_right = [1, 0, 0];
				} else {
					_right = vectorNormalized _right;
				};

				private _pitchUp = _right vectorCrossProduct _forward;
				if ((vectorMagnitudeSqr _pitchUp) < 0.000001) then {
					_pitchUp = _worldUp;
				} else {
					_pitchUp = vectorNormalized _pitchUp;
				};

				private _yawStep = _yawCmd * _steerYawRate * _steerScale * _dt;
				private _pitchStep = _pitchCmd * _steerPitchRate * _steerScale * _dt;
				private _manualDirRaw = _forward;
				_manualDirRaw = _manualDirRaw vectorAdd (_right vectorMultiply _yawStep);
				_manualDirRaw = _manualDirRaw vectorAdd (_pitchUp vectorMultiply _pitchStep);
				if ((vectorMagnitudeSqr _manualDirRaw) < 0.000001) then {
					_manualDirRaw = _forward;
				};
				private _manualDir = vectorNormalized _manualDirRaw;

				_v = _manualDir vectorMultiply _manualVectorDist;
				_posWorld = _posProj vectorAdd _v;

				if (_targetEnabled && {!_manualActive}) then {
					_targetArr = [_projectile, _v] call lancet_fnc_findTarget;
					_target = _targetArr # 0;
					_targetOffset = _targetArr # 1;

					if (!isNull _target) then {
						_v = ((getPosASL _target) vectorAdd _targetOffset) vectorDiff _posProj;
						_posWorld = _posProj vectorAdd _v;
					};
				} else {
					_target = objNull;
					_targetOffset = [0, 0, 0];
				};

				uiNamespace setVariable ["_itemLock", !(isNull _target)];
				private _angleFac = (1 - abs((vectorDir _projectile) vectorCos _v));
				private _responseMin = if (_manualActive) then {0.08} else {0.16};
				private _responseMax = if (_manualActive) then {0.22} else {0.34};
				_timeManouver = [_projectile, _responseMin + (_angleFac * (_responseMax - _responseMin)), _responseMax] call lancet_fnc_manouverTime;
				[_projectile, _v, _timeManouver, _dt] call lancet_fnc_handleGuidance;

				_nextGuideAt = time + _guideTick;
			};
		};
			
		//Target cursor
		if(ctrlShown _targetCursor) then {
			_crtlSize = (ctrlPosition _targetCursor) # 3;
			_crossTarget = [];
			if(isNull _target) then {
				_wordToScreenPos = worldToScreen ((ASLTOAGL _posWorld) vectorAdd _targetOffset);
				if(count _wordToScreenPos > 0) then {
					_crossTarget = _wordToScreenPos vectorDiff [_crtlSize/2, _crtlSize/2];
				};
			} else {
				_wordToScreenPos = (worldToScreen ((ASLTOAGL getposASl _target) vectorAdd _targetOffset)); 
				if(count _wordToScreenPos > 0) then {
					_crossTarget = _wordToScreenPos vectorDiff [_crtlSize/2, _crtlSize/2];
				};
			};
				//Check if the cursor is outside the screen, in that case disable it
				if(count _crossTarget > 0) then {
					_crossTarget deleteAt 2;
					_targetCursor ctrlSetPosition _crossTarget;
					_targetCursor ctrlCommit 0;
					} else {
					_targetCursor ctrlShow false;
				};

				uiNamespace setVariable ["_itemLock", !(isNull _target)];
			};

		_timeCheck = time;
	};

	sleep 0.01;
};

//If we closed the dialog while the missile is still alive, it will auto track the target, if any
if(alive _projectile and !isNull _target) then {
	_projectile setMissileTarget _target; //Some projectiles allow handoff
};

//Clean 
if(!isNull _camera) then {
	closeDialog 1;
	false setCamUseTI 0;
	_camera cameraEffect ["terminate","back"];
	camDestroy _camera;
};

private _effects = (uiNamespace getVariable ["lancet_effectsArr", []]);
if(count _effects > 0) then {
	{
		ppEffectDestroy _x;
	}forEach _effects;
};
uiNamespace setVariable ["lancet_effectsArr",  []];

		//_id = [str _projectile, "onEachFrame", { drawLine3D [_this # 0, _this # 1, [1,1,1,1]]}, [aslToAGL positionCameraToWorld [0,0,0], (aslToAGL _posProj) vectorAdd _v]] call BIS_fnc_addStackedEventHandler;
		

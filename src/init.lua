--!strict
local Players = game:GetService('Players');

local isTypeScriptEnv = script.Name == 'src';
local dependencies = if isTypeScriptEnv then script.Parent.Parent else script.Parent;
local Observers = require(isTypeScriptEnv and dependencies['roblox-observers'].src or dependencies.Observers);

local localPlayer = Players.LocalPlayer;

local UIExclusiveGroup = {};
UIExclusiveGroup.__index = UIExclusiveGroup;

UIExclusiveGroup._taggedUIGroups = {} :: { [string]: typeof(setmetatable({}, UIExclusiveGroup)) };

function UIExclusiveGroup._getUIObjectEnabledPropertyName(uiObject: GuiBase2d)
	if uiObject:IsA('LayerCollector') then
		return 'Enabled';
	elseif uiObject:IsA('GuiObject') then
		return 'Visible';
	end;

	error(`UIExclusiveGroup: Unsupported UI object ({uiObject:GetFullName()}) of type {uiObject.ClassName}.`);
end;

function UIExclusiveGroup._isUIObjectEnabled(uiObject: GuiBase2d)
	local enabledPropertyName = UIExclusiveGroup._getUIObjectEnabledPropertyName(uiObject);
	return (uiObject :: any)[enabledPropertyName];
end;

function UIExclusiveGroup._disableUIObject(uiObject: GuiBase2d)
	local enabledPropertyName = UIExclusiveGroup._getUIObjectEnabledPropertyName(uiObject);
	(uiObject :: any)[enabledPropertyName] = false;
end;

function UIExclusiveGroup.init()
	Observers.observeTag('UIExclusiveGroup', function(uiObject: GuiBase2d)
		assert(uiObject:IsA('GuiBase2d'), `UIExclusiveGroup instance {uiObject:GetFullName()} must be a GuiBase2d`);

		local uiGroupAttr = uiObject:GetAttribute('UIGroup');
		assert(typeof(uiGroupAttr) == 'string', `UIExclusiveGroup instance {uiObject:GetFullName()} UIGroup attribute must be of type string`);

		local UIGroup = UIExclusiveGroup._taggedUIGroups[uiGroupAttr];
		if not UIGroup then
			UIGroup = UIExclusiveGroup.new();
			UIExclusiveGroup._taggedUIGroups[uiGroupAttr] = UIGroup;
		end;

		UIGroup:add(uiObject);

		return function()
			UIGroup:remove(uiObject);

			local isEmpty = next(UIGroup._uiObjects) == nil;
			if isEmpty then
				UIExclusiveGroup._taggedUIGroups[uiGroupAttr] = nil;
			end;
		end;
	end, { localPlayer.PlayerGui });
end;

function UIExclusiveGroup.new()
	local self = setmetatable({}, UIExclusiveGroup);

	self._uiObjects = {} :: { [GuiBase2d]: RBXScriptConnection };

	return self;
end;

function UIExclusiveGroup:_disableGuisExcept(uiObject: GuiBase2d)
	for otherUIObject in self._uiObjects do
		if otherUIObject == uiObject then continue; end;
		UIExclusiveGroup._disableUIObject(otherUIObject);
	end;
end;

function UIExclusiveGroup:add(uiObject: GuiBase2d)
	if UIExclusiveGroup._isUIObjectEnabled(uiObject) then
		self:_disableGuisExcept(uiObject);
	end;

	self._uiObjects[uiObject] = uiObject:GetPropertyChangedSignal(UIExclusiveGroup._getUIObjectEnabledPropertyName(uiObject)):Connect(function()
		local enabled = UIExclusiveGroup._isUIObjectEnabled(uiObject);
		if not enabled then return; end;

		self:_disableGuisExcept(uiObject);
	end);
end;

function UIExclusiveGroup:remove(uiObject: GuiBase2d)
	local connection = self._uiObjects[uiObject];
	if not connection then return; end;

	connection:Disconnect();
	self._uiObjects[uiObject] = nil;
end;

return UIExclusiveGroup;
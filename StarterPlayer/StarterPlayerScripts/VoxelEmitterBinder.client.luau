-- Internal/VoxelEmitterBinder (LocalScript) — FULL REPLACE
-- Биндер только:
--  • следит за тегом CollectionService "VoxelEmitter"
--  • читает Attribute "VoxelPreset"
--  • триггерит бёрсты по Attribute "VoxelBurst"
-- Направление эмиссии полностью считается внутри VoxelParticleSystem
-- из локального emissionDirection и CFrame эмиттера.

-- Luau-safe

local RunService        = game:GetService("RunService")
if not RunService:IsRunning() then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace         = game:GetService("Workspace")

-- ==== Константы/атрибуты ======================================================
local TAG                       = "VoxelEmitter"
local PRESET_ATTRIBUTE          = "VoxelPreset"
local BURST_ATTRIBUTE           = "VoxelBurst"
local BURST_ON_ENABLE_ATTRIBUTE = "VoxelBurstOnEnable"
local IGNORE_CULLING_ATTRIBUTE  = "VoxelIgnoreCulling"

-- ==== Доступ к Shared =========================================================
local Shared        = ReplicatedStorage:WaitForChild("Shared")
local PresetsFolder = Shared:WaitForChild("VoxelEmitterPresets")
local VPS           = require(Shared:WaitForChild("VoxelParticleSystem"))

-- ==== Состояние биндера =======================================================
-- active[part] = emitter
local active: {[BasePart]: any} = setmetatable({}, { __mode = "k" })

-- ==== Утилиты =================================================================
local function deepCopy(v)
	if typeof(v) == "table" then
		local t = {}
		for k, val in pairs(v) do
			t[k] = deepCopy(val)
		end
		return t
	end
	return v
end

local function loadPresetState(name: string): any?
	if typeof(name) ~= "string" or name == "" then return nil end
	local mod = PresetsFolder:FindFirstChild(name)
	if not (mod and mod:IsA("ModuleScript")) then return nil end
	local ok, data = pcall(function() return require(mod) end)
	if not ok then return nil end

	local src = (typeof(data) == "table" and (data.state or data)) or data
	if typeof(src) ~= "table" then return nil end
	return deepCopy(src)
end

local function unbind(part: BasePart)
	local emitter = active[part]
	if emitter then
		active[part] = nil
		pcall(function() emitter:Destroy() end)
	end
end

local function bind(part: BasePart)
	unbind(part)
	if not part:IsDescendantOf(Workspace) then
		return
	end

	local presetName = part:GetAttribute(PRESET_ATTRIBUTE)
	if typeof(presetName) ~= "string" or presetName == "" then
		return
	end

	local cfg = loadPresetState(presetName)
	if not cfg then
		return
	end

	if part:GetAttribute(IGNORE_CULLING_ATTRIBUTE) == true then
		cfg.ignoreVisibilityCulling = true
	end

	local burstOnEnable = (part:GetAttribute(BURST_ON_ENABLE_ATTRIBUTE) == true)
	if burstOnEnable then
		cfg.burstOnEnable = true
	end

	local emitter = VPS.Attach(part, cfg)
	active[part] = emitter

	-- Первичный BURST, если атрибут уже выставлен
	local wantAttr = part:GetAttribute(BURST_ATTRIBUTE)
	local want = (typeof(wantAttr) == "number") and wantAttr or 0
	if want ~= 0 then
		if want == -1 then
			local count = tonumber(cfg.burstCount) or 0
			if count > 0 then
				emitter:Emit(count)
			end
		elseif want > 0 then
			emitter:Emit(math.floor(want))
		end
		part:SetAttribute(BURST_ATTRIBUTE, 0)
	end
end

local function rebinder(part: BasePart)
	bind(part)
end

local function watch(part: BasePart)
	-- Смена пресета → ребинд
	part:GetAttributeChangedSignal(PRESET_ATTRIBUTE):Connect(function()
		local name = part:GetAttribute(PRESET_ATTRIBUTE)
		if typeof(name) == "string" and #name > 0 then
			rebinder(part)
		else
			unbind(part)
		end
	end)

	-- Сигнал бёрста: просто вызываем Emit у уже привязанного эмиттера
	part:GetAttributeChangedSignal(BURST_ATTRIBUTE):Connect(function()
		local emitter = active[part]
		if not emitter then
			return
		end

		local vAttr = part:GetAttribute(BURST_ATTRIBUTE)
		local v = (typeof(vAttr) == "number") and vAttr or 0
		if v == 0 then
			return
		end

		if v == -1 then
			local cfg = loadPresetState(tostring(part:GetAttribute(PRESET_ATTRIBUTE) or ""))
			local count = cfg and tonumber(cfg.burstCount) or 0
			if count and count > 0 then
				emitter:Emit(count)
			end
			part:SetAttribute(BURST_ATTRIBUTE, 0)
		elseif v >= 1 then
			emitter:Emit(math.floor(v))
			part:SetAttribute(BURST_ATTRIBUTE, 0)
		end
	end)

	-- Изменение родителя/удаление
	part.AncestryChanged:Connect(function(_, parent)
		if not parent then
			unbind(part)
		elseif part:IsDescendantOf(Workspace) then
			bind(part)
		end
	end)

	bind(part)
end

-- ==== Инициализация по уже существующим тегам ================================
for _, inst in ipairs(CollectionService:GetTagged(TAG)) do
	if inst:IsA("BasePart") then
		watch(inst)
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(function(inst)
	if inst:IsA("BasePart") then
		watch(inst)
	end
end)

CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
	if inst:IsA("BasePart") then
		unbind(inst)
	end
end)

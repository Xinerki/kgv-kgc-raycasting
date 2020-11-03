
-- CROSS COMPAT
local FIVEM = IsPcVersion ~= nil
local MTA = dxSetTexturePixels ~= nil

if FIVEM == true then
	aspectRatio = GetAspectRatio(0)

	function RenderLine(startX, startY, startZ, endX, endY, endZ, r, g, b, a)
		return DrawLine(startX, startY, startZ, endX, endY, endZ, r, g, b, a)
	end
	
	--[[
	function RenderPixel(x, y, r, g, b, a)
		local scaleX = (1/1920.0/aspectRatio)
		local scaleY = (1/1080.0)
	
		-- return DrawRect((scale)+x/(1920.0*(scale/2.7)), (scale)+y/(1080.0*(scale/2.7)), scale/aspectRatio, scale, r, g, b, a)
		return DrawRect((scaleX/2)+x/1920.0, (scaleY/2)+y/1080.0, scaleX, scaleY, r, g, b, a)
	end
	]]
	
	function CastRay(startX, startY, startZ, endX, endY, endZ)
		local ray = StartShapeTestRay(startX, startY, startZ, endX, endY, endZ, -1, nil, 0)
		local retVal, hit, endCoords, surfaceNormal, hitEnt = GetShapeTestResult(ray)
		-- return retVal, hit, endCoords, surfaceNormal, hitEnd
		return {hit == 1, endCoords}
	end
	
	function AddCommand(cmd, func)
		RegisterCommand(cmd, func)
	end
	
	function RenderImage()
		DrawSprite("ray", "image", 0.15, 0.15, 0.2/aspectRatio, 0.2, 0.0, 255, 255, 255, 255)
	end
	
	function SetPixel(x, y, r, g, b, a)
		SetRuntimeTexturePixel(tex, x, y, r, g, b, a)
		CommitRuntimeTexture(tex)
	end
elseif MTA == true then
	vector3 = Vector3
	
	function getPositionFromElementOffset(element,offX,offY,offZ)
		local m = getElementMatrix ( element )  -- Get the matrix
		local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]  -- Apply transform
		local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
		local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
		return x, y, z                               -- Return the transformed point
	end
	
	function RenderLine(startX, startY, startZ, endX, endY, endZ, r, g, b, a)
		dxDrawLine3D(startX, startY, startZ, endX, endY, endZ, tocolor(r,g,b,a))
	end
	
	function CastRay(startX, startY, startZ, endX, endY, endZ)
		local hit, hitX, hitY, hitZ = processLineOfSight(startX, startY, startZ, endX, endY, endZ)
		return {hit, vector3(hitX, hitY, hitZ)}
	end
	
	function AddCommand(cmd, func)
		addCommandHandler(cmd, func)
	end
	
	function RenderImage()
		dxDrawImage(250, 250, 256, 256, tex)
	end
	
	function SetPixel(x, y, r, g, b, a)
		dxSetPixelColor(pixels, x, y, r, g, b, a)
		dxSetTexturePixels(tex, pixels)
	end
end

-- MAIN CODE

local resX = math.floor(128)
local resY = math.floor(128)

local nearZ = 0.1
local farZ = 100.0
local fov = 70.0

local startPos = vector3(0.0, 0.0, 4.0)
local startRot = vector3(0.0, 0.0, 0.0)
	
-- startPos = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 1.0, 0.0)
-- startRot = vector3(0.0, 0.0, GetEntityHeading(PlayerPedId()))

function translateAngle(x1, y1, ang, offset)
	x1 = x1 + math.sin(ang) * offset
	y1 = y1 + math.cos(ang) * offset
	return x1, y1
end

function math.clamp(value, minClamp, maxClamp)
	return math.min(maxClamp, math.max(value, minClamp))
end

function CalcColor(dist)
	return math.clamp(math.floor((dist/50)*255), 0, 255)
end

function DoRaycasting()
		
	-- startPos = GetFinalRenderedCamCoord()
	-- local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
	-- startPos = vector3(x, y+1.0, z)
	-- startRot = GetFinalRenderedCamRot(1)
	-- startRot = vector3(-startRot.x, startRot.y, startRot.z)
		
	for x=0,resX do
	for y=0,resY do
		
		local progress = (x/resX)
		local angleX = startRot.z+-((-fov/2) + fov * progress)
		-- local rotX = math.sin(math.rad(-angle))
		
		local progress = (y/resY)
		local angleY = startRot.x+(-fov/2) + fov * progress
		-- local rotY = math.sin(math.rad(-angle))
		
		local idk1, startZ = translateAngle(startPos.y, startPos.z, math.rad(-angleY-90.0), nearZ)
		local idk3, endZ = translateAngle(startPos.y, startPos.z, math.rad(-angleY-90.0), farZ)
		
		local startX, startY = translateAngle(startPos.x, startPos.y, math.rad(-angleX), nearZ)
		local endX, endY = translateAngle(startPos.x, startPos.y, math.rad(-angleX), farZ)
		
		RenderLine(startX, startY, startZ, endX, endY, endZ, 255, 255, 255, 255)
		
		local r, g, b, a = 150, 150, 255, 255
		
		local ray = CastRay(startX, startY, startZ, endX, endY, endZ)
		
		if ray[1] == true then
			local dist = #(ray[2] - vector3(startX, startY, startZ))
			local color = CalcColor(dist)
			r, g, b = 255-color, 255-color, 255-color
		end
		
		-- SetRuntimeTexturePixel(tex, x, y, g, r, a, b)
		SetPixel(x, y, r, g, b, a)
		
		-- ForwardX, ForwardY = translateAngle(pos.x, pos.y, math.rad(-rotation.x), ForwardControl*(fov / 50.0))
	end
		-- Wait(0)
		-- CommitRuntimeTexture(tex)
	end
	-- Wait(1)
	
end

AddCommand("startray", DoRaycasting)

function perFrame()
	-- DoRaycasting()
	RenderImage()
end

-- OTHER HANDLERS

if FIVEM == true then
	Citizen.CreateThread(function()
		txd = CreateRuntimeTxd("ray")
		tex = CreateRuntimeTexture(txd, "image", resX, resY)
		
		for x=0,resX do
		for y=0,resY do
			SetRuntimeTexturePixel(tex, x, y, math.random(0, 255), math.random(0, 255), math.random(0, 255), 255)
		end
		end
		
		CommitRuntimeTexture(tex)
		
		while true do Wait(0)
			perFrame()
		end
	end)
elseif MTA == true then
	addEventHandler("onClientResourceStart", resourceRoot, function()
		tex = dxCreateTexture(resX, resY)
		pixels = dxGetTexturePixels(tex)
		
		for x=0,resX do
		for y=0,resY do
			dxSetPixelColor(pixels, x, y, math.random(0, 255), math.random(0, 255), math.random(0, 255), 255)
		end
		end
		
		dxSetTexturePixels(tex, pixels)
	end)
	
	addEventHandler("onClientRender", root, perFrame)
end
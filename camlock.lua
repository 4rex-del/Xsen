--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Variables
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local CamlockEnabled = false
local LockedTarget = nil
local Tracer = nil
local AimPartName = "HumanoidRootPart"
local LastYPosition = nil
local AimOffset = Vector3.new()

--// UI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "CamlockUI"

local ToggleButton = Instance.new("ImageButton", ScreenGui)
ToggleButton.Position = UDim2.new(0, 20, 0, 100)
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Image = "rbxassetid://117646389994766" -- 🔓 ปิดอยู่
ToggleButton.BackgroundTransparency = 1

--// Tracer Line
local function createTracer()
	if Tracer then Tracer:Destroy() end
	Tracer = Drawing.new("Line")
	Tracer.Thickness = 2
	Tracer.Color = Color3.new(1, 0, 0)
end

--// Get Closest Target to Center
local function getClosestToCenter()
	local closest = nil
	local closestDist = math.huge
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			local part = player.Character:FindFirstChild(AimPartName)
			if part then
				local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
					if dist < closestDist and dist < 120 then -- ใกล้จอ
						closest = player
						closestDist = dist
					end
				end
			end
		end
	end
	return closest
end

--// Aim Assist (ดึงเมาส์เข้าใกล้เป้าหมาย)
local function applyAimAssist()
	local best = nil
	local closest = math.huge
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(AimPartName) and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character[AimPartName].Position)
			if onScreen then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
				if dist < closest and dist < 80 then -- ระยะเมาส์
					best = player
					closest = dist
				end
			end
		end
	end

	if best then
		local aimPos = best.Character[AimPartName].Position
		local cameraPos = Camera.CFrame.Position
		Camera.CFrame = CFrame.new(cameraPos, aimPos)
	end
end

--// Camlock Main Loop
RunService.RenderStepped:Connect(function()
	if CamlockEnabled then
		-- Lock เป้าหมายกลางจอ
		if not LockedTarget or not LockedTarget.Character or LockedTarget.Character.Humanoid.Health <= 0 then
			LockedTarget = getClosestToCenter()
			if LockedTarget and LockedTarget.Character then
				LastYPosition = LockedTarget.Character:FindFirstChild(AimPartName).Position.Y
			end
		end

		-- Move กล้อง
		if LockedTarget and LockedTarget.Character then
			local aimPart = LockedTarget.Character:FindFirstChild(AimPartName)
			if aimPart then
				local currentY = aimPart.Position.Y

				-- เปลี่ยน offset หากกระโดด
				if math.abs(currentY - LastYPosition) > 2 then
					local offsets = {
						Vector3.new(1.5, 0, 0),
						Vector3.new(-1.5, 0, 0),
						Vector3.new(0, 1.5, 0),
						Vector3.new(0, -1.5, 0)
					}
					AimOffset = offsets[math.random(1, #offsets)]
					LastYPosition = currentY
				end

				-- กล้องเล็ง
				local targetPos = aimPart.Position + AimOffset
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)

				-- Tracer
				local screenPos1, visible1 = Camera:WorldToViewportPoint(Camera.CFrame.Position)
				local screenPos2, visible2 = Camera:WorldToViewportPoint(targetPos)
				if visible1 and visible2 then
					Tracer.Visible = true
					Tracer.From = Vector2.new(screenPos1.X, screenPos1.Y)
					Tracer.To = Vector2.new(screenPos2.X, screenPos2.Y)
				else
					Tracer.Visible = false
				end
			end
		else
			if Tracer then Tracer.Visible = false end
		end

		-- Aim Assist ช่วยเล็งใกล้เมาส์
		applyAimAssist()
	else
		if Tracer then Tracer.Visible = false end
	end
end)

--// Toggle Camlock On/Off
ToggleButton.MouseButton1Click:Connect(function()
	CamlockEnabled = not CamlockEnabled
	if CamlockEnabled then
		ToggleButton.Image = "rbxassetid://139278632183493" -- 🔒 เปิด
		createTracer()
	else
		ToggleButton.Image = "rbxassetid://117646389994766" -- 🔓 ปิด
		if Tracer then Tracer:Destroy() end
		Tracer = nil
		LockedTarget = nil
	end
end)

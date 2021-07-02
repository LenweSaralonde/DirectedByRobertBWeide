--- Main module
-- @module DBRBW

DBRBW = {}

local creditsFrame
local creditsBackground
local creditsText
local creditsFadeAnimation
local creditsTextAnimation

local isPlaying = false
local timers = {}
local musicHandle

--- Main initialization
--
function DBRBW.Initialize()
	-- Create UI elements

	creditsFrame = CreateFrame("Frame", "DBRBW_Credits", UIParent)
	creditsFrame:EnableMouse(true)
	creditsFrame:SetAllPoints()
	creditsFrame:Hide()

	creditsBackground = creditsFrame:CreateTexture("DBRBW_CreditsBackground", "OVERLAY", nil, 7)
	creditsBackground:SetColorTexture(0, 0, 0, 1)
	creditsBackground:SetAllPoints()

	creditsText = creditsFrame:CreateFontString(nil, "OVERLAY")
	creditsText:SetAllPoints()
	creditsText:SetFont("Interface\\AddOns\\DirectedByRobertBWeide\\Clarendon-Medium.ttf", 50)
	creditsText:SetSpacing(20)
	creditsText:SetTextColor(1, 1, 1, 1)

	-- Create animations

	creditsFadeAnimation = creditsFrame:CreateAnimationGroup()
	creditsFadeAnimation:SetToFinalAlpha(true)
	local fadeIn = creditsFadeAnimation:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(1)
	fadeIn:SetDuration(.5)
	fadeIn:SetSmoothing("OUT")

	creditsTextAnimation = creditsText:CreateAnimationGroup()
	creditsTextAnimation:SetToFinalAlpha(true)
	local textFade = creditsTextAnimation:CreateAnimation("Alpha")
	textFade:SetFromAlpha(0)
	textFade:SetToAlpha(1)
	textFade:SetDuration(.5)
	textFade:SetSmoothing("OUT")

	-- Stop credits animation when escape is pressed
	creditsFrame:SetScript(
		"OnKeyDown",
		function(self, keyValue)
			if keyValue == "ESCAPE" then
				DBRBW.HideCredits()
				self:SetPropagateKeyboardInput(false)
				return
			end
			self:SetPropagateKeyboardInput(true)
		end
	)

	-- Play credits animation when dead
	creditsFrame:RegisterEvent("PLAYER_DEAD")
	creditsFrame:SetScript(
		"OnEvent",
		function()
			C_Timer.After(2.5, DBRBW.ShowCredits)
		end
	)

	-- /dbrbw command
	SlashCmdList["DBRBW"] = DBRBW.ShowCredits
	SLASH_DBRBW1 = "/dbrbw"
	SLASH_DBRBW2 = "/curb"
end

--- Get customized credits
-- @return credits (table)
function DBRBW.GetCredits()
	local himself = UnitSex("player") == 3 and "Herself" or "Himself"
	local player = string.upper(UnitName("player"))

	return {
		{"Directed by", "ROBERT B. WEIDE", 1},
		{"Executive Producer", "LARRY DAVID", 3.3},
		{"Executive Producer", "JEFF GARLIN", 3.3},
		{"Executive Producer", "GAVIN POLONE", 3.3},
		{"Co-Executive Producer", "ROBERT B. WEIDE", 3.3},
		{"Produced by", "TIM GIBBONS", 3.3},
		{"Co-Producer", "ERIN O'MALLEY", 3.3},
		{"Consulting Producer", "ALAN ZWEIBEL", 3.3},
		{"Starring", player .. " as " .. himself, 3.3}
	}
end

--- Start credits animation
--
function DBRBW.ShowCredits()
	-- Stop previously playing credits
	DBRBW.HideCredits()

	-- Mute game music
	PlayMusic("Interface\\AddOns\\DirectedByRobertBWeide\\silent.mp3")

	-- Preload audio
	local _, preloadHandle = PlaySoundFile("Interface\\AddOns\\DirectedByRobertBWeide\\frolic.mp3", "Master")
	StopSound(preloadHandle, 0)

	-- UI needs to be shown
	UIParent:Show()

	-- Enable keyboard control
	creditsFrame:EnableKeyboard(true)

	-- Prepare credits
	creditsText:SetText("")

	-- Enqueue credits
	local time = 0
	local credit
	for _, credit in pairs(DBRBW.GetCredits()) do
		local row1, row2, delay = unpack(credit)
		time = time + delay
		table.insert(
			timers,
			C_Timer.NewTimer(
				time,
				function()
					creditsText:SetText(row1 .. "\n" .. row2)
				end
			)
		)
	end

	-- Enqueue music
	table.insert(
		timers,
		C_Timer.NewTimer(
			1 + 3.3 - 2.2,
			function()
				_, musicHandle = PlaySoundFile("Interface\\AddOns\\DirectedByRobertBWeide\\frolic.mp3", "Master")
			end
		)
	)

	-- Enqueue animation end sequence

	table.insert(
		timers,
		C_Timer.NewTimer(
			30,
			function()
				StopSound(musicHandle, 5000)
				musicHandle = nil
			end
		)
	)

	table.insert(
		timers,
		C_Timer.NewTimer(
			34,
			function()
				creditsTextAnimation:Play(true)
			end
		)
	)

	table.insert(
		timers,
		C_Timer.NewTimer(
			35,
			function()
				creditsFadeAnimation:Play(true)
			end
		)
	)

	table.insert(
		timers,
		C_Timer.NewTimer(
			36,
			function()
				DBRBW.HideCredits()
			end
		)
	)

	-- Init frame
	creditsFrame:SetFrameStrata("TOOLTIP")
	creditsFrame:SetFrameLevel(UIParent:GetFrameLevel() + 1000)
	creditsFrame:SetAlpha(0)
	creditsText:SetAlpha(1)
	creditsFrame:Show()
	creditsFrame:SetScale(1 / UIParent:GetScale())

	-- Play animation
	creditsFadeAnimation:Play()

	isPlaying = true
end

--- Stop credits animation
--
function DBRBW.HideCredits()
	if not (isPlaying) then
		return
	end

	-- Disable keyboard control
	creditsFrame:EnableKeyboard(false)

	-- Stop all timers
	local timer
	for _, timer in pairs(timers) do
		timer:Cancel()
	end
	timers = {}

	-- Stop animations, hide frame
	creditsFadeAnimation:Stop()
	creditsTextAnimation:Stop()
	creditsFrame:Hide()

	-- Stop music
	if musicHandle then
		StopSound(musicHandle, 100)
	end
	musicHandle = nil
	StopMusic()

	isPlaying = false
end

DBRBW.Initialize()

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)

if not playerGui then
    warn("[매크로 우회] PlayerGui를 10초 안에 못 찾음 → 스크립트 종료")
    return
end

print("[매크로 우회] 스크립트 시작 - PlayerGui 로드 완료")

-- ================= 설정 =================
local bypassCount = 0
local lastProcessedGui = nil
local lastCode = nil

-- ================= 카운터 UI =================
local counterGui = Instance.new("ScreenGui")
counterGui.Name = "MacroBypassCounter"
counterGui.ResetOnSpawn = false
counterGui.Parent = playerGui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 300, 0, 50)
label.Position = UDim2.new(1, -320, 0.5, -25)   -- 오른쪽 중앙쯤
label.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
label.BackgroundTransparency = 0.35
label.BorderSizePixel = 0
label.TextColor3 = Color3.fromRGB(100, 255, 180)
label.Font = Enum.Font.SourceSansBold
label.TextSize = 20
label.TextXAlignment = Enum.TextXAlignment.Center
label.Text = "매크로 우회 대기 중... (0회)"
label.Parent = counterGui

print("[매크로 우회] 카운터 UI 생성 완료")

-- ================= 핵심 우회 함수 =================
local function tryBypassMacro(macroGui)
    -- 같은 GUI 재처리 방지
    if macroGui == lastProcessedGui then
        return false
    end

    print("[매크로 우회] 처리 시도 → " .. macroGui:GetFullName())

    local inputObj = nil
    local targetTextBox = nil

    -- 모든 자손 뒤져서 찾기 (대소문자 무시)
    for _, obj in ipairs(macroGui:GetDescendants()) do
        local nameLower = string.lower(obj.Name)

        -- 코드가 보이는 TextLabel 찾기
        if obj:IsA("TextLabel") and (
            nameLower:find("code") or 
            nameLower:find("input") or 
            nameLower == "text" or 
            (obj.Text and obj.Text:match("%d%d%d%d"))
        ) then
            inputObj = obj
            print("  → 코드 표시 TextLabel 발견: " .. obj:GetFullName())
        end

        -- 입력할 TextBox 찾기
        if obj:IsA("TextBox") and (
            nameLower:find("input") or 
            nameLower:find("box") or 
            nameLower:find("text") or 
            nameLower == "textbox"
        ) then
            targetTextBox = obj
            print("  → 입력용 TextBox 발견: " .. obj:GetFullName())
        end

        if inputObj and targetTextBox then
            break
        end
    end

    if not inputObj then
        print("  → 코드가 보이는 TextLabel을 찾지 못함")
        return false
    end

    if not targetTextBox then
        print("  → 입력 가능한 TextBox를 찾지 못함")
        return false
    end

    local rawText = inputObj.Text or ""
    local code = rawText:gsub("[^%d]", ""):sub(1,4)

    if #code ~= 4 then
        print("  → 유효한 4자리 숫자 추출 실패 (" .. code .. ")")
        return false
    end

    print("  → 추출된 코드: " .. code)

    -- 이미 입력돼 있으면 스킵
    if targetTextBox.Text == code then
        print("  → 이미 동일한 코드가 입력되어 있음 → 스킵")
        lastProcessedGui = macroGui
        lastCode = code
        return false
    end

    -- 실제 입력
    targetTextBox.Text = code
    print("  → TextBox에 입력 완료: " .. code)

    -- 카운트 & UI 갱신
    bypassCount += 1
    label.Text = "매크로 우회 성공: " .. bypassCount .. "회"

    lastProcessedGui = macroGui
    lastCode = code

    return true
end

-- ================= 초기 1회 체크 (이미 떠있는 경우) =================
local function checkExistingMacroGui()
    for _, child in ipairs(playerGui:GetChildren()) do
        if child:IsA("ScreenGui") and string.lower(child.Name) == "macrogui" then
            print("[매크로 우회] 시작 시 이미 떠있는 MacroGui 발견")
            tryBypassMacro(child)
        end
    end
end

checkExistingMacroGui()

-- ================= 새로 추가될 때마다 체크 =================
playerGui.ChildAdded:Connect(function(child)
    if not child:IsA("ScreenGui") then return end
    
    local nameLower = string.lower(child.Name)
    if nameLower == "macrogui" or nameLower:find("macro") then
        print("[매크로 우회] 새 MacroGui 감지 → " .. child.Name)
        
        -- 약간의 지연 후 처리 (애니메이션/텍스트 로딩 대기)
        task.delay(0.8, function()
            if child.Parent == playerGui then
                local success = tryBypassMacro(child)
                if success then
                    print(" → 성공적으로 우회 처리됨")
                end
            end
        end)
    end
end)

print("[매크로 우회] 이벤트 연결 완료 - 이제 MacroGui가 나타나면 자동 처리합니다")

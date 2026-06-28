#Requires AutoHotkey v2.0
#SingleInstance Force

AppName := "POE2 Expedition Tracker"
AppVersion := "0.3.0"

DiscordWebhookUrl := ""

RemnantRuneOptions := [
    "Time", "Death", "Opulent", "Cyclonic", "Power", "Moon", "Soul", "Bond",
    "Prismatic", "Arcane", "Earth", "Fire", "Cold", "Sky", "Stone", "Tidal",
    "Rage", "Momentum", "Electrocuting", "Bloodletting", "Lightning", "Toxic",
    "Oath", "Rebirth", "Vision", "Celestial", "Adaptive", "Ward", "Wisdom"
]

CurrencyOptions := [
    "Mirror of Kalandra", "Hinekora Lock", "Divine", "Perfect Chaos",
    "Greater Chaos", "Chaos", "Orb of Annulment", "Perfect Exalted",
    "Greater Exalted", "Perfect Regal", "Greater Regal", "Perfect Jeweller",
    "Orb of Chance", "Perfect Augmentation", "Perfect Transmutation"
]

SocketableRuneOptions := [
    "Cadigans", "Astrids", "Aldur's", "Serles", "Perfect Flux",
    "Legacy", "Masterwork", "Transcendent", "Celestial"
]

LayoutOptions := [
    "Frigid Bluffs", "Lush Isle", "Exhumed Ruins", "Bleached Shoals",
    "Sloughed Gully", "Craggy Pennisula", "Grazed Prairie",
    "Stagnant Basin", "Scorched Cay"
]

CreateEncounter() {
    return Map(
        "Layout", "",
        "RemnantRunes", [],
        "SocketableRunes", [],
        "CurrencyTotals", Map()
    )
}

CurrentEncounter := CreateEncounter()

TrackerGui := ""
GuiVisible := false

LayoutList := ""
Rune1List := ""
Rune2List := ""
SocketableList := ""
CurrencyList := ""
QuantityEdit := ""

SummaryLayout := ""
SummaryRunes := ""
SummarySocketables := ""
SummaryCurrency := ""
StatusText := ""

BuildGui()

#HotIf WinActive("ahk_exe PathOfExileSteam.exe") || WinActive("ahk_class POEWindowClass")
^Space::{
    KeyWait "Space"
    KeyWait "Ctrl"
    ToggleGui()
}
#HotIf

F10::ToggleGui() ; temporary test hotkey

BuildGui() {
    global TrackerGui
    global LayoutList, Rune1List, Rune2List, SocketableList, CurrencyList, QuantityEdit
    global SummaryLayout, SummaryRunes, SummarySocketables, SummaryCurrency, StatusText
    global AppName, AppVersion, LayoutOptions, RemnantRuneOptions, SocketableRuneOptions, CurrencyOptions

    TrackerGui := Gui("+ToolWindow", AppName " v" AppVersion)
    TrackerGui.SetFont("s9", "Segoe UI")

    TrackerGui.Add("Text", "xm ym", "Layout")
    LayoutList := TrackerGui.Add("ListBox", "xm w180 h70", LayoutOptions)
    setLayoutBtn := TrackerGui.Add("Button", "xm y+4 w100", "Set Layout")
    setLayoutBtn.OnEvent("Click", OnSetLayout)

    TrackerGui.Add("Text", "xm y+10", "Rune 1")
    TrackerGui.Add("Text", "x200 yp", "Rune 2")

    Rune1List := TrackerGui.Add("ListBox", "xm w175 h95", RemnantRuneOptions)
    Rune2List := TrackerGui.Add("ListBox", "x200 yp w175 h95", RemnantRuneOptions)

    addRuneBtn := TrackerGui.Add("Button", "xm y+5 w120", "Add Rune Pair")
    addRuneBtn.OnEvent("Click", OnAddRunePair)

    TrackerGui.Add("Text", "xm y+10", "Socketable Rune")
    SocketableList := TrackerGui.Add("ListBox", "xm w180 h75", SocketableRuneOptions)

    addSocketBtn := TrackerGui.Add("Button", "xm y+5 w120", "Add Socketable")
    addSocketBtn.OnEvent("Click", OnAddSocketable)

    TrackerGui.Add("Text", "xm y+10", "Currency")
    CurrencyList := TrackerGui.Add("ListBox", "xm w180 h85", CurrencyOptions)

    TrackerGui.Add("Text", "x+10 yp", "Qty")
    QuantityEdit := TrackerGui.Add("Edit", "w50 Number", "1")

    addCurrencyBtn := TrackerGui.Add("Button", "xp y+8 w120", "Add Currency")
    addCurrencyBtn.OnEvent("Click", OnAddCurrency)

    TrackerGui.Add("Text", "x400 ym", "Current Encounter")

    TrackerGui.Add("Text", "x400 y+8", "Layout")
    SummaryLayout := TrackerGui.Add("Text", "x400 y+2 w280 h20", "None")

    TrackerGui.Add("Text", "x400 y+8", "Runes")
    SummaryRunes := TrackerGui.Add("ListBox", "x400 y+2 w280 h85")
    SummaryRunes.OnEvent("DoubleClick", OnRemoveRune)

    TrackerGui.Add("Text", "x400 y+8", "Socketable Runes")
    SummarySocketables := TrackerGui.Add("ListBox", "x400 y+2 w280 h75")
    SummarySocketables.OnEvent("DoubleClick", OnRemoveSocketable)

    TrackerGui.Add("Text", "x400 y+8", "Currency")
    SummaryCurrency := TrackerGui.Add("ListBox", "x400 y+2 w280 h85")
    SummaryCurrency.OnEvent("DoubleClick", OnRemoveCurrency)

    submitBtn := TrackerGui.Add("Button", "x400 y+12 w120", "Submit Encounter")
    submitBtn.OnEvent("Click", OnSubmitEncounter)

    clearBtn := TrackerGui.Add("Button", "x+10 w80", "Clear")
    clearBtn.OnEvent("Click", OnClear)

    hideBtn := TrackerGui.Add("Button", "x+10 w80", "Hide")
    hideBtn.OnEvent("Click", (*) => HideGui())

    StatusText := TrackerGui.Add("Text", "x400 y+10 w280", "Ready")

    TrackerGui.OnEvent("Close", (*) => HideGui())

    RefreshUI()
}

ToggleGui() {
    global GuiVisible
    GuiVisible ? HideGui() : ShowGui()
}

ShowGui() {
    global TrackerGui, GuiVisible

    if GuiVisible
        return

    TrackerGui.Show("x950 y120")
    GuiVisible := true
}

HideGui() {
    global TrackerGui, GuiVisible
    TrackerGui.Hide()
    GuiVisible := false
}

OnSetLayout(*) {
    global CurrentEncounter, LayoutList

    try {
        SetEncounterLayout(CurrentEncounter, LayoutList.Text)
        SetStatus("Layout set.")
        RefreshUI()
    } catch as err {
        SetStatus(err.Message)
        MsgBox err.Message
    }
}

OnAddRunePair(*) {
    global CurrentEncounter, Rune1List, Rune2List

    try {
        AddRemnantRuneCombo(CurrentEncounter, Rune1List.Text, Rune2List.Text)
        Rune1List.Choose(0)
        Rune2List.Choose(0)
        SetStatus("Rune pair added.")
        RefreshUI()
    } catch as err {
        SetStatus(err.Message)
        MsgBox err.Message
    }
}

OnAddSocketable(*) {
    global CurrentEncounter, SocketableList

    try {
        AddSocketableRune(CurrentEncounter, SocketableList.Text)
        SocketableList.Choose(0)
        SetStatus("Socketable rune added.")
        RefreshUI()
    } catch as err {
        SetStatus(err.Message)
        MsgBox err.Message
    }
}

OnAddCurrency(*) {
    global CurrentEncounter, CurrencyList, QuantityEdit

    try {
        AddCurrency(CurrentEncounter, CurrencyList.Text, QuantityEdit.Value)
        CurrencyList.Choose(0)
        QuantityEdit.Value := "1"
        SetStatus("Currency added.")
        RefreshUI()
    } catch as err {
        SetStatus(err.Message)
        MsgBox err.Message
    }
}

OnSubmitEncounter(*) {
    global CurrentEncounter

    try {
        ValidateEncounterForSubmit(CurrentEncounter)

        logPath := GetEncounterLogPath()
        encounterNumber := GetNextEncounterNumber(logPath)
        output := FormatEncounter(CurrentEncounter, encounterNumber)

        FileAppend output "`n", logPath, "UTF-8"

        discordResult := SendEncounterToDiscord(output)

        ClearEncounter()
        ClearInputs()
        RefreshUI()

        if discordResult = "Skipped" {
            SetStatus("Encounter " encounterNumber " saved locally.")
            MsgBox "Encounter " encounterNumber " saved locally.`n`n" logPath
        } else {
            SetStatus("Encounter " encounterNumber " saved and posted.")
            MsgBox "Encounter " encounterNumber " saved and posted to Discord.`n`n" logPath
        }
    } catch as err {
        SetStatus(err.Message)
        MsgBox err.Message
    }
}

OnRemoveRune(*) {
    global CurrentEncounter, SummaryRunes

    index := SummaryRunes.Value
    if index <= 0 || CurrentEncounter["RemnantRunes"].Length = 0
        return

    CurrentEncounter["RemnantRunes"].RemoveAt(index)
    SetStatus("Rune removed.")
    RefreshUI()
}

OnRemoveSocketable(*) {
    global CurrentEncounter, SummarySocketables

    index := SummarySocketables.Value
    if index <= 0 || CurrentEncounter["SocketableRunes"].Length = 0
        return

    CurrentEncounter["SocketableRunes"].RemoveAt(index)
    SetStatus("Socketable rune removed.")
    RefreshUI()
}

OnRemoveCurrency(*) {
    global CurrentEncounter, SummaryCurrency

    selected := SummaryCurrency.Text
    if selected = "" || selected = "None"
        return

    for currency, quantity in CurrentEncounter["CurrencyTotals"] {
        if selected = quantity " " currency {
            CurrentEncounter["CurrencyTotals"].Delete(currency)
            SetStatus("Currency removed.")
            RefreshUI()
            return
        }
    }
}

OnClear(*) {
    result := MsgBox("Clear the current encounter?", "Confirm Clear", "YesNo Icon?")
    if result != "Yes"
        return

    ClearEncounter()
    ClearInputs()
    SetStatus("Current encounter cleared.")
    RefreshUI()
}

ClearInputs() {
    global LayoutList, Rune1List, Rune2List, SocketableList, CurrencyList, QuantityEdit

    LayoutList.Choose(0)
    Rune1List.Choose(0)
    Rune2List.Choose(0)
    SocketableList.Choose(0)
    CurrencyList.Choose(0)
    QuantityEdit.Value := "1"
}

RefreshUI() {
    global CurrentEncounter
    global SummaryLayout, SummaryRunes, SummarySocketables, SummaryCurrency

    SummaryLayout.Text := ValueOrNone(CurrentEncounter["Layout"])
    RefreshListBox(SummaryRunes, CurrentEncounter["RemnantRunes"])
    RefreshListBox(SummarySocketables, CurrentEncounter["SocketableRunes"])
    RefreshCurrencyListBox(SummaryCurrency, CurrentEncounter["CurrencyTotals"])
}

RefreshListBox(listBox, items) {
    listBox.Delete()

    if items.Length = 0 {
        listBox.Add(["None"])
        return
    }

    index := 1
    for item in items {
        listBox.Add([index ". " item])
        index++
    }
}

RefreshCurrencyListBox(listBox, currencyTotals) {
    listBox.Delete()

    if currencyTotals.Count = 0 {
        listBox.Add(["None"])
        return
    }

    for currency, quantity in currencyTotals {
        listBox.Add([quantity " " currency])
    }
}

SetStatus(message) {
    global StatusText
    StatusText.Text := message
}

SetEncounterLayout(encounter, layout) {
    layout := Trim(layout)

    if layout = ""
        throw Error("Please select a layout.")

    encounter["Layout"] := layout
}

AddRemnantRuneCombo(encounter, rune1, rune2 := "") {
    rune1 := Trim(rune1)
    rune2 := Trim(rune2)

    if rune1 = ""
        throw Error("Rune 1 is required.")

    if rune2 != "" && rune1 = rune2
        throw Error("Rune 1 and Rune 2 cannot be the same.")

    if rune2 = "" {
        combo := rune1
    } else {
        pair := [rune1, rune2]
        SortTwoItemArray(pair)
        combo := pair[1] " + " pair[2]
    }

    if ArrayContains(encounter["RemnantRunes"], combo)
        throw Error("This rune combination has already been added.")

    encounter["RemnantRunes"].Push(combo)
    return combo
}

AddSocketableRune(encounter, rune) {
    rune := Trim(rune)

    if rune = ""
        throw Error("Socketable rune is required.")

    encounter["SocketableRunes"].Push(rune)
    return rune
}

AddCurrency(encounter, currency, quantity) {
    currency := Trim(currency)
    quantity := Integer(quantity)

    if currency = ""
        throw Error("Currency is required.")

    if quantity <= 0
        throw Error("Quantity must be greater than 0.")

    totals := encounter["CurrencyTotals"]

    if totals.Has(currency)
        totals[currency] += quantity
    else
        totals[currency] := quantity

    return totals[currency]
}

ClearEncounter() {
    global CurrentEncounter
    CurrentEncounter := CreateEncounter()
}

ValidateEncounterForSubmit(encounter) {
    if Trim(encounter["Layout"]) = ""
        throw Error("Please set a layout before submitting.")

    if encounter["RemnantRunes"].Length = 0
        && encounter["SocketableRunes"].Length = 0
        && encounter["CurrencyTotals"].Count = 0 {
        throw Error("Nothing to submit.")
    }
}

FormatEncounter(encounter, encounterNumber := 1) {
    text := ""

    text .= "Encounter " encounterNumber "`n"
    text .= "====================`n"
    text .= "Layout: " ValueOrNone(encounter["Layout"]) "`n`n"

    text .= "Runes`n"
    text .= "-----------`n"
    text .= FormatArrayList(encounter["RemnantRunes"])

    text .= "`nSocketable Runes`n"
    text .= "----------------`n"
    text .= FormatArrayList(encounter["SocketableRunes"])

    text .= "`nCurrency`n"
    text .= "------------`n"
    text .= FormatCurrencyTotals(encounter["CurrencyTotals"])

    text .= "`n"

    return text
}

FormatArrayList(items) {
    if items.Length = 0
        return "None`n"

    text := ""
    index := 1

    for item in items {
        text .= index ". " item "`n"
        index++
    }

    return text
}

FormatCurrencyTotals(currencyTotals) {
    if currencyTotals.Count = 0
        return "None`n"

    text := ""

    for currency, quantity in currencyTotals {
        text .= quantity " " currency "`n"
    }

    return text
}

GetEncounterLogPath() {
    logDir := A_ScriptDir "\logs"

    if !DirExist(logDir)
        DirCreate(logDir)

    return logDir "\Encounter_Log_" FormatTime(, "yyyy-MM-dd") ".txt"
}

GetNextEncounterNumber(filePath) {
    if !FileExist(filePath)
        return 1

    content := FileRead(filePath)
    count := 0
    pos := 1

    while pos := RegExMatch(content, "Encounter\s+\d+", &match, pos) {
        count++
        pos += StrLen(match[0])
    }

    return count + 1
}

ArrayContains(arr, value) {
    for item in arr {
        if item = value
            return true
    }

    return false
}

SortTwoItemArray(arr) {
    if arr.Length < 2
        return

    if StrCompare(arr[1], arr[2]) > 0 {
        temp := arr[1]
        arr[1] := arr[2]
        arr[2] := temp
    }
}

ValueOrNone(value) {
    value := Trim(value)
    return value = "" ? "None" : value
}

SendEncounterToDiscord(message) {
    global DiscordWebhookUrl

    webhook := Trim(DiscordWebhookUrl)

    if webhook = ""
        return "Skipped"

    content := "```" . message . "```"
    payload := "{""content"":""" JsonEscape(content) """}"

    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("POST", webhook, false)
    http.SetRequestHeader("Content-Type", "application/json")
    http.Send(payload)

    status := http.Status

    if status < 200 || status >= 300
        throw Error("Discord webhook failed. HTTP Status: " status)

    return "Posted"
}

JsonEscape(value) {
    value := StrReplace(value, "\", "\\")
    value := StrReplace(value, """", "\""")
    value := StrReplace(value, "`r", "")
    value := StrReplace(value, "`n", "\n")
    value := StrReplace(value, "`t", "\t")

    return value
}
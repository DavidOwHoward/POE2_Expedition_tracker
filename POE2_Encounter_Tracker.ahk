#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; POE2 Expedition Tracker
; Phase 2: Compact GUI
; ============================================================

AppName := "POE2 Expedition Tracker"
AppVersion := "0.2.0"

SaveFile := A_ScriptDir "\POE2_Encounter_Log.txt"
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
        "CurrencyTotals", Map(),
        "Waystone", Map(
            "Name", "",
            "Tier", "",
            "ItemRarity", "",
            "MonsterRarity", "",
            "WaystoneDropChance", "",
            "RevivesAvailable", ""
        )
    )
}

CurrentEncounter := CreateEncounter()

; ============================================================
; GUI STATE
; ============================================================

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

; Optional testing hotkey outside POE:
; F10::ToggleGui()

; ============================================================
; GUI
; ============================================================

BuildGui() {
    global TrackerGui
    global LayoutList, Rune1List, Rune2List, SocketableList, CurrencyList, QuantityEdit
    global SummaryLayout, SummaryRunes, SummarySocketables, SummaryCurrency, StatusText
    global AppName, AppVersion, LayoutOptions, RemnantRuneOptions, SocketableRuneOptions, CurrencyOptions

    TrackerGui := Gui("+ToolWindow", AppName " v" AppVersion)
    TrackerGui.SetFont("s9", "Segoe UI")

    TrackerGui.Add("Text", "xm ym", "Layout")
    LayoutList := TrackerGui.Add("ListBox", "xm w180 h90", LayoutOptions)

    TrackerGui.Add("Text", "xm y+10", "Rune 1")
    Rune1List := TrackerGui.Add("ListBox", "xm w180 h110", RemnantRuneOptions)

    TrackerGui.Add("Text", "x+10 yp", "Rune 2")
    Rune2List := TrackerGui.Add("ListBox", "w180 h110", RemnantRuneOptions)

    addRuneBtn := TrackerGui.Add("Button", "xm y+6 w120", "Add Rune Pair")
    addRuneBtn.OnEvent("Click", OnAddRunePair)

    TrackerGui.Add("Text", "xm y+12", "Socketable Rune")
    SocketableList := TrackerGui.Add("ListBox", "xm w180 h90", SocketableRuneOptions)

    addSocketBtn := TrackerGui.Add("Button", "xm y+6 w120", "Add Socketable")
    addSocketBtn.OnEvent("Click", OnAddSocketable)

    TrackerGui.Add("Text", "xm y+12", "Currency")
    CurrencyList := TrackerGui.Add("ListBox", "xm w180 h100", CurrencyOptions)

    TrackerGui.Add("Text", "x+10 yp", "Qty")
    QuantityEdit := TrackerGui.Add("Edit", "w50 Number", "1")

    addCurrencyBtn := TrackerGui.Add("Button", "xm y+6 w120", "Add Currency")
    addCurrencyBtn.OnEvent("Click", OnAddCurrency)

    TrackerGui.Add("Text", "x400 ym", "Current Encounter")

    TrackerGui.Add("Text", "x400 y+8", "Layout")
    SummaryLayout := TrackerGui.Add("Text", "x400 y+2 w280 h20", "None")

    TrackerGui.Add("Text", "x400 y+10", "Runes")
    SummaryRunes := TrackerGui.Add("ListBox", "x400 y+2 w280 h95")

    TrackerGui.Add("Text", "x400 y+10", "Socketable Runes")
    SummarySocketables := TrackerGui.Add("ListBox", "x400 y+2 w280 h85")

    TrackerGui.Add("Text", "x400 y+10", "Currency")
    SummaryCurrency := TrackerGui.Add("ListBox", "x400 y+2 w280 h95")

    clearBtn := TrackerGui.Add("Button", "x400 y+12 w100", "Clear")
    clearBtn.OnEvent("Click", OnClear)

    hideBtn := TrackerGui.Add("Button", "x+10 w100", "Hide")
    hideBtn.OnEvent("Click", (*) => HideGui())

    StatusText := TrackerGui.Add("Text", "xm y+12 w650", "Ready")

    TrackerGui.OnEvent("Close", (*) => HideGui())

    RefreshUI()
}

ToggleGui() {
    global GuiVisible

    if GuiVisible
        HideGui()
    else
        ShowGui()
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

; ============================================================
; EVENT HANDLERS
; ============================================================

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

; ============================================================
; UI REFRESH
; ============================================================

RefreshUI() {
    global CurrentEncounter
    global LayoutList, SummaryLayout, SummaryRunes, SummarySocketables, SummaryCurrency

    if LayoutList.Text != ""
        SetEncounterLayout(CurrentEncounter, LayoutList.Text)

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

; ============================================================
; ENCOUNTER FUNCTIONS
; ============================================================

SetEncounterLayout(encounter, layout) {
    encounter["Layout"] := Trim(layout)
}

AddRemnantRuneCombo(encounter, rune1, rune2 := "") {
    rune1 := Trim(rune1)
    rune2 := Trim(rune2)

    if rune1 = ""
        throw Error("Rune 1 is required.")

    if rune2 != "" && rune1 = rune2
        throw Error("Rune 1 and Rune 2 cannot be the same.")

    combo := ""

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

; ============================================================
; FORMATTER
; ============================================================

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

; ============================================================
; UTILITIES
; ============================================================

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
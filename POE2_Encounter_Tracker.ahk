#Requires AutoHotkey v2.0

#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; POE2 Expedition Tracker
; Phase 1: Foundation
; ============================================================

; =========================
; CONFIGURATION
; =========================

AppName := "POE2 Expedition Tracker"
AppVersion := "0.1.0"

SaveFile := A_ScriptDir "\POE2_Encounter_Log.txt"
DiscordWebhookUrl := "" ; Optional later

; =========================
; PROVIDED LISTS
; =========================

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

; =========================
; DATA MODEL
; =========================

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

; =========================
; ENCOUNTER FUNCTIONS
; =========================

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

; =========================
; FORMATTER
; =========================

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

; =========================
; UTILITIES
; =========================

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

; =========================
; PHASE 1 SMOKE TEST
; =========================

; Uncomment this block if you want to test Phase 1 manually.
; It does not write files yet.
;
; SetEncounterLayout(CurrentEncounter, "Frigid Bluffs")
; AddRemnantRuneCombo(CurrentEncounter, "Time", "Opulent")
; AddSocketableRune(CurrentEncounter, "Aldur's")
; AddCurrency(CurrentEncounter, "Divine", 3)
; MsgBox FormatEncounter(CurrentEncounter, 1)
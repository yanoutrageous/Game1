extends RefCounted
class_name ItemRarityDescriptor

# Presentation-only normalization for item rarity. Content keeps owning the
# canonical rarity value; views consume this descriptor instead of maintaining
# independent label/color tables.

const TIER_1 := &"tier_1"
const TIER_2 := &"tier_2"
const TIER_3 := &"tier_3"
const TIER_4 := &"tier_4"
const TIER_5 := &"tier_5"
const TIER_6 := &"tier_6"
const UNIQUE := &"unique"
const UNKNOWN := &"unknown"

const FORMAL_TIERS := [TIER_1, TIER_2, TIER_3, TIER_4, TIER_5, TIER_6]

const LABELS := {
	TIER_1: "普通",
	TIER_2: "优良",
	TIER_3: "稀有",
	TIER_4: "珍贵",
	TIER_5: "传奇",
	TIER_6: "秘藏",
	UNIQUE: "唯一",
	UNKNOWN: "未鉴定",
}

const BADGES := {
	TIER_1: "T1",
	TIER_2: "T2",
	TIER_3: "T3",
	TIER_4: "T4",
	TIER_5: "T5",
	TIER_6: "T6",
	UNIQUE: "◆",
	UNKNOWN: "?",
}

const BORDER_TOKENS := {
	TIER_1: &"rarity.border.tier_1",
	TIER_2: &"rarity.border.tier_2",
	TIER_3: &"rarity.border.tier_3",
	TIER_4: &"rarity.border.tier_4",
	TIER_5: &"rarity.border.tier_5",
	TIER_6: &"rarity.border.tier_6",
	UNIQUE: &"rarity.border.unique_locked",
	UNKNOWN: &"rarity.border.unknown",
}

const SHAPE_TOKENS := {
	TIER_1: &"rarity.shape.1_bar",
	TIER_2: &"rarity.shape.2_bars",
	TIER_3: &"rarity.shape.3_bars",
	TIER_4: &"rarity.shape.4_bars",
	TIER_5: &"rarity.shape.5_bars",
	TIER_6: &"rarity.shape.6_bars",
	UNIQUE: &"rarity.shape.locked_diamond",
	UNKNOWN: &"rarity.shape.question",
}

const TONES := {
	TIER_1: &"common",
	TIER_2: &"uncommon",
	TIER_3: &"rare",
	TIER_4: &"epic",
	TIER_5: &"legendary",
	TIER_6: &"mythic",
	UNIQUE: &"unique_locked",
	UNKNOWN: &"unknown",
}

const COLORS := {
	TIER_1: Color("d0d8e0"),
	TIER_2: Color("78dcaa"),
	TIER_3: Color("5fa5ff"),
	TIER_4: Color("be78ff"),
	TIER_5: Color("ffc346"),
	TIER_6: Color("fa5f55"),
	UNIQUE: Color("f6e079"),
	UNKNOWN: Color("a9b0ad"),
}


static func normalize(value: Variant) -> StringName:
	var text := str(value).strip_edges().to_lower()
	text = text.replace("-", "_").replace(" ", "_")
	match text:
		"1", "t1", "tier1", "tier_1", "common", "普通":
			return TIER_1
		"2", "t2", "tier2", "tier_2", "uncommon", "good", "优良":
			return TIER_2
		"3", "t3", "tier3", "tier_3", "rare", "稀有":
			return TIER_3
		"4", "t4", "tier4", "tier_4", "epic", "珍贵":
			return TIER_4
		"5", "t5", "tier5", "tier_5", "legendary", "传奇":
			return TIER_5
		"6", "t6", "tier6", "tier_6", "mythic", "秘藏", "神话":
			return TIER_6
		"unique", "唯一":
			return UNIQUE
		_:
			return UNKNOWN


static func describe(value: Variant) -> Dictionary:
	var normalized := normalize(value)
	var locked := normalized == UNIQUE
	var known := normalized != UNKNOWN
	var label := String(LABELS[normalized])
	var badge := String(BADGES[normalized])
	var natural_text := "%s %s（锁定）" % [badge, label] if locked else label
	return {
		"normalized_key": normalized,
		"key": normalized,
		"label": label,
		"badge": badge,
		"natural_text": natural_text,
		"display_text": "[%s] %s%s" % [badge, label, "（锁定）" if locked else ""],
		"border_token": StringName(BORDER_TOKENS[normalized]),
		"shape_token": StringName(SHAPE_TOKENS[normalized]),
		"tone": StringName(TONES[normalized]),
		"color": Color(COLORS[normalized]),
		"tier": FORMAL_TIERS.find(normalized) + 1 if normalized in FORMAL_TIERS else 0,
		"known": known,
		"locked": locked,
		"presentation_only": true,
	}


static func describe_item(item: Dictionary) -> Dictionary:
	return describe(item.get("rarity", UNKNOWN))


static func display_text(value: Variant) -> String:
	return String(describe(value).get("display_text", "[?] 未鉴定"))

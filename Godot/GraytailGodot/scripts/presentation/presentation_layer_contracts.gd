extends RefCounted
class_name PresentationLayerContracts

# G9 contract-only presentation schemas.
# This file must not load resources, touch scenes, or mutate run state.

const CONTRACT_STAGE := &"g9_ui_presentation_layering_revision"

const LAYER_BASE_BACKGROUND := &"base_background"
const LAYER_THEME_OVERLAY := &"theme_overlay"
const LAYER_SCENE_PROP_OVERLAY := &"scene_prop_overlay"
const LAYER_CHARACTER := &"character"
const LAYER_CHARACTER_OVERLAY := &"character_overlay"
const LAYER_FOREGROUND_FX := &"foreground_fx"
const LAYER_UI_PANEL := &"ui_panel"
const LAYER_POPUP_TOOLTIP := &"popup_tooltip"

const LAYER_ORDER := [
	LAYER_BASE_BACKGROUND,
	LAYER_THEME_OVERLAY,
	LAYER_SCENE_PROP_OVERLAY,
	LAYER_CHARACTER,
	LAYER_CHARACTER_OVERLAY,
	LAYER_FOREGROUND_FX,
	LAYER_UI_PANEL,
	LAYER_POPUP_TOOLTIP,
]

const THEME_PROFILE_REQUIRED_FIELDS := [
	"theme_id",
	"schema_version",
	"display_name_key",
	"base_background_id",
	"color_grade_id",
	"lighting_overlay_id",
	"ambient_vfx_ids",
	"prop_overlay_ids",
	"foreground_overlay_ids",
	"panel_skin_id",
	"map_icon_theme_id",
	"risk_overlay_policy",
	"fallback_theme_id",
	"tags",
	"deprecated_state",
]

const PRESENTATION_LAYER_ENTRY_REQUIRED_FIELDS := [
	"layer_id",
	"schema_version",
	"kind",
	"asset_id",
	"fallback_asset_id",
	"z_index",
	"anchor",
	"offset",
	"scale",
	"opacity",
	"blend_mode",
	"tint",
	"parallax_factor",
	"visibility_condition",
	"interactive",
	"blocks_input",
	"occlusion_policy",
	"reduction_group",
	"tags",
	"deprecated_state",
]

const CHARACTER_PRESENTATION_CONFIG_REQUIRED_FIELDS := [
	"character_id",
	"schema_version",
	"display_name_key",
	"base_sprite_id",
	"portrait_id",
	"default_pose_id",
	"available_pose_ids",
	"outfit_overlay_ids",
	"equipment_overlay_ids",
	"status_overlay_ids",
	"anchor",
	"scale",
	"fallback_character_id",
	"tags",
	"deprecated_state",
]

const OUTFIT_PRESENTATION_DEF_REQUIRED_FIELDS := [
	"outfit_id",
	"schema_version",
	"character_id",
	"display_name_key",
	"overlay_asset_ids",
	"slot",
	"rarity",
	"unlock_condition",
	"compatible_pose_ids",
	"tags",
	"deprecated_state",
]

const PANEL_STATE_REQUIRED_FIELDS := [
	"page_id",
	"panel_id",
	"expanded_state",
	"last_selected_tab",
	"compact_mode",
	"summary_mode",
	"remember_state",
	"animation_profile_id",
]

const UI_VISIBILITY_POLICY_REQUIRED_FIELDS := [
	"policy_id",
	"page_id",
	"entry_id",
	"visible",
	"compact_allowed",
	"dev_only",
	"reduction_group",
	"unlock_condition",
	"priority",
]

const NAVIGATION_ENTRY_REQUIRED_FIELDS := [
	"entry_id",
	"schema_version",
	"label_key",
	"icon_id",
	"page",
	"target_panel",
	"category",
	"is_primary",
	"is_visible",
	"unlock_condition",
	"sort_order",
	"dev_only",
]

const SHORTCUT_ENTRY_REQUIRED_FIELDS := [
	"shortcut_id",
	"schema_version",
	"source_page",
	"target_page",
	"target_panel",
	"label_key",
	"icon_id",
	"is_pinned",
	"priority",
	"last_used_sequence",
	"visibility_condition",
]

const EXPEDITION_SUMMARY_VIEW_MODEL_REQUIRED_FIELDS := [
	"loadout_items",
	"consumables",
	"capacity_current",
	"capacity_max",
	"run_effects",
	"risk_warnings",
	"blocked_reason",
	"tracked_objective",
	"recommended_route",
	"theme_id",
]

const LONG_TERM_SUMMARY_VIEW_MODEL_REQUIRED_FIELDS := [
	"profile_level",
	"profile_exp",
	"next_reward",
	"permanent_bonus",
	"task_progress",
	"codex_progress",
	"achievement_progress",
	"research_progress",
	"tracked_objective",
]


static func layer_order() -> Array:
	return LAYER_ORDER.duplicate()


static func contract_names() -> Array:
	return [
		&"ThemeProfile",
		&"PresentationLayerEntry",
		&"CharacterPresentationConfig",
		&"OutfitPresentationDef",
		&"PanelState",
		&"UIVisibilityPolicy",
		&"NavigationEntry",
		&"ShortcutEntry",
		&"ExpeditionSummaryViewModel",
		&"LongTermSummaryViewModel",
	]


static func required_fields_for(contract_name: StringName) -> Array:
	match contract_name:
		&"ThemeProfile":
			return THEME_PROFILE_REQUIRED_FIELDS.duplicate()
		&"PresentationLayerEntry":
			return PRESENTATION_LAYER_ENTRY_REQUIRED_FIELDS.duplicate()
		&"CharacterPresentationConfig":
			return CHARACTER_PRESENTATION_CONFIG_REQUIRED_FIELDS.duplicate()
		&"OutfitPresentationDef":
			return OUTFIT_PRESENTATION_DEF_REQUIRED_FIELDS.duplicate()
		&"PanelState":
			return PANEL_STATE_REQUIRED_FIELDS.duplicate()
		&"UIVisibilityPolicy":
			return UI_VISIBILITY_POLICY_REQUIRED_FIELDS.duplicate()
		&"NavigationEntry":
			return NAVIGATION_ENTRY_REQUIRED_FIELDS.duplicate()
		&"ShortcutEntry":
			return SHORTCUT_ENTRY_REQUIRED_FIELDS.duplicate()
		&"ExpeditionSummaryViewModel":
			return EXPEDITION_SUMMARY_VIEW_MODEL_REQUIRED_FIELDS.duplicate()
		&"LongTermSummaryViewModel":
			return LONG_TERM_SUMMARY_VIEW_MODEL_REQUIRED_FIELDS.duplicate()
		_:
			return []


static func theme_profile_example() -> Dictionary:
	return {
		"theme_id": &"theme.base.default",
		"schema_version": 1,
		"display_name_key": &"theme.default.name",
		"base_background_id": &"background.base.graytail.placeholder",
		"color_grade_id": &"color_grade.neutral.placeholder",
		"lighting_overlay_id": &"overlay.light.neutral.placeholder",
		"ambient_vfx_ids": [&"vfx.ambient.none"],
		"prop_overlay_ids": [&"prop.overlay.none"],
		"foreground_overlay_ids": [&"foreground.overlay.none"],
		"panel_skin_id": &"panel.skin.default",
		"map_icon_theme_id": &"map_icon_theme.default",
		"risk_overlay_policy": &"risk_overlay.semantic_only",
		"fallback_theme_id": &"theme.base.default",
		"tags": [&"placeholder", &"contract_only"],
		"deprecated_state": &"active",
	}


static func presentation_layer_entry_example() -> Dictionary:
	return {
		"layer_id": LAYER_THEME_OVERLAY,
		"schema_version": 1,
		"kind": &"theme_overlay",
		"asset_id": &"overlay.theme.default.placeholder",
		"fallback_asset_id": &"overlay.theme.fallback.placeholder",
		"z_index": 100,
		"anchor": &"full_rect",
		"offset": Vector2.ZERO,
		"scale": Vector2.ONE,
		"opacity": 1.0,
		"blend_mode": &"normal",
		"tint": Color.WHITE,
		"parallax_factor": 0.0,
		"visibility_condition": &"always",
		"interactive": false,
		"blocks_input": false,
		"occlusion_policy": &"behind_ui_panels",
		"reduction_group": &"atmosphere",
		"tags": [&"placeholder", &"contract_only"],
		"deprecated_state": &"active",
	}


static func character_presentation_config_example() -> Dictionary:
	return {
		"character_id": &"character.default",
		"schema_version": 1,
		"display_name_key": &"character.default.name",
		"base_sprite_id": &"character.base.default.placeholder",
		"portrait_id": &"portrait.character.default.placeholder",
		"default_pose_id": &"pose.idle",
		"available_pose_ids": [&"pose.idle"],
		"outfit_overlay_ids": [&"outfit.default.placeholder"],
		"equipment_overlay_ids": [],
		"status_overlay_ids": [],
		"anchor": &"left_stage",
		"scale": Vector2.ONE,
		"fallback_character_id": &"character.default",
		"tags": [&"placeholder", &"contract_only"],
		"deprecated_state": &"active",
	}


static func outfit_presentation_def_example() -> Dictionary:
	return {
		"outfit_id": &"outfit.default.placeholder",
		"schema_version": 1,
		"character_id": &"character.default",
		"display_name_key": &"outfit.default.name",
		"overlay_asset_ids": [&"outfit.overlay.default.placeholder"],
		"slot": &"body",
		"rarity": &"common",
		"unlock_condition": &"default_unlocked",
		"compatible_pose_ids": [&"pose.idle"],
		"tags": [&"cosmetic", &"contract_only"],
		"deprecated_state": &"active",
	}


static func panel_state_example() -> Dictionary:
	return {
		"page_id": &"page.home",
		"panel_id": &"panel.center",
		"expanded_state": &"collapsed",
		"last_selected_tab": &"tab.default",
		"compact_mode": false,
		"summary_mode": &"standard",
		"remember_state": true,
		"animation_profile_id": &"animation.panel.default",
	}


static func ui_visibility_policy_example() -> Dictionary:
	return {
		"policy_id": &"visibility.default",
		"page_id": &"page.home",
		"entry_id": &"entry.expedition",
		"visible": true,
		"compact_allowed": true,
		"dev_only": false,
		"reduction_group": &"navigation",
		"unlock_condition": &"always",
		"priority": 100,
	}


static func navigation_entry_example() -> Dictionary:
	return {
		"entry_id": &"entry.expedition",
		"schema_version": 1,
		"label_key": &"nav.expedition",
		"icon_id": &"icon.nav.expedition.placeholder",
		"page": &"page.expedition",
		"target_panel": &"panel.expedition.prepare",
		"category": &"primary",
		"is_primary": true,
		"is_visible": true,
		"unlock_condition": &"always",
		"sort_order": 10,
		"dev_only": false,
	}


static func shortcut_entry_example() -> Dictionary:
	return {
		"shortcut_id": &"shortcut.confirm_expedition",
		"schema_version": 1,
		"source_page": &"page.home",
		"target_page": &"page.expedition",
		"target_panel": &"panel.expedition.confirm",
		"label_key": &"shortcut.confirm_expedition",
		"icon_id": &"icon.shortcut.expedition.placeholder",
		"is_pinned": true,
		"priority": 100,
		"last_used_sequence": 0,
		"visibility_condition": &"always",
	}


static func expedition_summary_view_model_example() -> Dictionary:
	return {
		"loadout_items": [],
		"consumables": [],
		"capacity_current": 0,
		"capacity_max": 10,
		"run_effects": [],
		"risk_warnings": [],
		"blocked_reason": &"",
		"tracked_objective": &"",
		"recommended_route": [],
		"theme_id": &"theme.base.default",
	}


static func long_term_summary_view_model_example() -> Dictionary:
	return {
		"profile_level": 1,
		"profile_exp": 0,
		"next_reward": {},
		"permanent_bonus": [],
		"task_progress": {},
		"codex_progress": {},
		"achievement_progress": {},
		"research_progress": {},
		"tracked_objective": &"",
	}

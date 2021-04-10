extends Node
class_name Enum

enum StatType {
	HP,
	STR,
	AGI,
	INT,
	DEF,
	NA
}

enum ItemType {
	WEAPON,
	MARTIAL_SKILL,
	SPECIAL_SKILL,
	TOME,
	TOOL
}

enum SubItemType {
	AXE,
	BOOMERANG,
	BOW,
	DAGGER,
	GUN,
	MACE,
	SHIELD,
	SPEAR,
	SWORD,
	WAND,
	AIR,
	ANCIENT,
	ARCANE,
	EARTH,
	FIRE,
	HEALING,
	WATER,
	WITCHCRAFT,
	CRAFT,
	DANCE,
	MARTIAL_ARTS,
	SORCERY,
	THIEVERY
	NA
}

enum TargetType {
	MYSELF,
	ANY_ALLY,
	OTHER_ALLY,
	OTHER_ALLIES_ONLY,
	ALL_ALLIES,
	RANDOM_ALLY,
	ONE_ENEMY,
	ONE_FRONT,
	ONE_BACK,
	ANY_ROW,
	FRONT_ROW,
	BACK_ROW,
	ALL_ENEMIES,
	RANDOM_ENEMY,
	RANDOM_ANYONE
}

enum DamageType {
	MARTIAL,
	AIR,
	EARTH,
	FIRE,
	WATER,
	PURE,
	HEAL,
	EFFECT_ONLY
}

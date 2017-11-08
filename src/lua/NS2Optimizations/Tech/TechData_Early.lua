kTechDataId                       = 0
kTechDataDisplayName              = 1
kTechDataSponitorCode             = 2
kTechIDShowEnables                = 3
kTechDataMapName                  = 4
kTechDataModel                    = 5
kTechDataCostKey                  = 6
kTechDataBuildTime                = 7
kTechDataResearchTimeKey          = 8
kTechDataMaxHealth                = 9
kTechDataMaxArmor                 = 10
kTechDataDamageType               = 11
kCommanderSelectRadius            = 12
kStructureAttachClass             = 13
kStructureBuildNearClass          = 14
kStructureBuildOnWall             = 15
kStructureAttachRange             = 16
kStructureAttachRequiresPower     = 17
kVisualRange                      = 18
kTechDataAttachOptional           = 19
kStructureAttachId                = 20
kTechDataGestateName              = 21
kTechDataUpgradeCost              = 22
kTechDataGestateTime              = 23
kTechDataSpawnHeightOffset        = 24
kTechDataMaxExtents               = 25
kTechDataObstacleRadius           = 26
kTechDataInitialEnergy            = 27
kTechDataMaxEnergy                = 28
kTechDataMenuPriority             = 29
kTechDataAlertPriority            = 30
kTechDataUpgradeTech              = 31
kTechDataSpecifyOrientation       = 32
kTechDataOverrideCoordsMethod     = 33
kTechDataPointValue               = 34
kTechDataImplemented              = 35
kTechDataNew                      = 36
kTechDataGrows                    = 37
kTechDataHotkey                   = 38
kTechDataAlertSound               = 39
kTechDataAlertText                = 40
kTechDataAlertType                = 41
kTechDataAlertTeam                = 42
kTechDataAlertIgnoreDistance      = 43
kTechDataAlertSendTeamMessage     = 44
kTechDataOrderSound               = 45
kTechDataAlertOthersOnly          = 46
kTechDataTooltipInfo              = 47
kTechDataHint                     = 48
kTechDataEngagementDistance       = 49
kTechDataRequiresInfestation      = 50
kTechDataNotOnInfestation         = 51
kTechDataGhostGuidesMethod        = 52
kTechDataBuildRequiresMethod      = 53
kTechDataAllowStacking            = 54
kTechDataCollideWithWorldOnly     = 55
kTechDataIgnorePathingMesh        = 56
kTechDataMaxAmount                = 57
kTechDataRequiresPower            = 58
kTechDataGhostModelClass          = 59
kTechDataAllowConsumeDrop         = 60
kTechDataRequiresMature           = 61
kTechDataCooldown                 = 62
kTechDataAlertIgnoreInterval      = 63
kTechDataCategory                 = 64
kTechDataBuildMethodFailedMessage = 65
kTechDataAbilityType              = 66
kTechDataSupply                   = 67
kTechDataSpawnBlock               = 68
kTechDataBioMass                  = 69
kTechDataShowOrderLine            = 70
kTechDataOriginalCostKey          = 71

local actual = LookupTechId
function LookupTechId(x, y)
	return actual(x, y)
end
_G.LookupTechId_NS2Opti = LookupTechId

local actual = LookupTechData
function LookupTechData(x, y, z)
	return actual(x, y, z)
end
_G.LookupTechData_NS2Opti = LookupTechData

local actual = GetTechForCategory
function GetTechForCategory(x)
	return actual(x)
end
_G.GetTechForCategory_NS2Opti = GetTechForCategory

class "MapConnector" (Entity)

MapConnector.kMapName = "mapconnector"

local networkVars =
{
	m_origin = "position (by 0.2 [2 3 5], by 0.2 [2 3 5], by 0.2 [2 3 5])",
    m_angles = "angles   (by 10000 [0],   by 10000 [3],     by 10000 [0])",
	m_parentId = "integer (-1 to -1)",
	m_attachPoint = "integer (-1 to -1)",
	endPoint = "position (by 0.2 [2 3 5], by 0.2 [2 3 5], by 0.2 [2 3 5])"
}

Shared.LinkClassToMap("MapConnector", MapConnector.kMapName, networkVars)

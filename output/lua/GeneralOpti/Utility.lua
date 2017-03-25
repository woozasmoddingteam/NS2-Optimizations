function EntityFilterOne(entity)
	return SLambda [[ self ent; ... == ent ]] {entity}
end

function EntityFilterOneAndIsa(entity, classname)
	return SLambda [[self ent cls; ... == ent or (...):isa(cls)]] {entity, classname}
end

function EntityFilterTwo(entity1, entity2)
	return SLambda [[self ent1 ent2; ... == ent1 or ... == ent2]] {entity1, entity2}
end

function EntityFilterTwoAndIsa(ent1, ent2, cls)
	return SLambda [[self ent1 ent2 cls; ... == ent1 or ... == ent2 or (...):isa(cls)]] {ent1, ent2, cls}
end
--]=]

function EntityFilterOnly(entity)
	return SLambda [[ ... ~= self[1] ]] {entity}
end

-- filter out all entities
function EntityFilterAll()
	return Lambda [[ ... ~= nil ]]
end

function EntityFilterAllButIsa(classname)
	return SLambda [[not (...):isa(cls)]] (classname)
end

function EntityFilterAllButMixin(mixinType)
	return SLambda [[not HasMixin(..., self)]] (mixinType)
end

--[=[
function EntityFilterMixinAndSelf(entity, mixinType)
	return CLambda [[self ent mixin; ... == ent or HasMixin(..., mixin)]] {entity, mixinType}
end
--]=]

function EntityFilterMixin(mixinType)
	return SLambda [[HasMixin(..., self)]] (mixinType)
end

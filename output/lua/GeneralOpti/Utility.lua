function EntityFilterOne(entity)
	return SClosure [[ ... == self ]] (entity)
end

--[=[
function EntityFilterOneAndIsa(entity, classname)
	return CLambda [[self ent cls; ... == ent or (...):isa(cls)]] {entity, classname}
end

function EntityFilterTwo(entity1, entity2)
	return CLambda [[self ent1 ent2; ... == ent1 or ... == ent2]] {entity1, entity2}
end

function EntityFilterTwoAndIsa(entity1, entity2, classname)
	return CLambda [[self ent1 ent2 cls; ... == ent1 or ... == ent2 or (...):isa(cls)]]
end
--]=]

function EntityFilterOnly(entity)
	return SClosure [[ ... ~= self ]] (entity)
end

-- filter out all entities
function EntityFilterAll()
	return Lambda [[ ... ~= nil ]]
end

function EntityFilterAllButIsa(classname)
	return SClosure [[not (...):isa(self)]] (classname)
end

function EntityFilterAllButMixin(mixinType)
	return SClosure [[not HasMixin(..., self)]] (mixinType)
end

--[=[
function EntityFilterMixinAndSelf(entity, mixinType)
	return CLambda [[self ent mixin; ... == ent or HasMixin(..., mixin)]] {entity, mixinType}
end
--]=]

function EntityFilterMixin(mixinType)
	return SClosure [[HasMixin(..., self)]] (mixinType)
end

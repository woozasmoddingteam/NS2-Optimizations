-- You can't pass these functions to the engine, so the engine functions will also have to be replaced before these will be enabled.
if true then
	return
end

function EntityFilterOne(entity)
	return CLambda [[ ... == self[1] ]] {entity}
end

function EntityFilterOneAndIsa(entity, classname)
	return CLambda [[self ent cls; ... == ent or (...):isa(cls)]] {entity, classname}
end

function EntityFilterTwo(entity1, entity2)
	return CLambda [[self ent1 ent2; ... == ent1 or ... == ent2]] {entity1, entity2}
end

function EntityFilterTwoAndIsa(entity1, entity2, classname)
	return CLambda [[self ent1 ent2 cls; ... == ent1 or ... == ent2 or (...):isa(cls)]]
end

function EntityFilterOnly(entity)
	return CLambda [[ ... ~= self[1] ]] {entity}
end

-- filter out all entities
function EntityFilterAll()
	return CLambda [[ ... ~= nil ]]
end

function EntityFilterAllButIsa(classname)
	return CLambda [[not (...):isa(self[1])]] {classname}
end

function EntityFilterAllButMixin(mixinType)
	return CLambda [[not HasMixin(..., self[1])]] {mixinType}
end

function EntityFilterMixinAndSelf(entity, mixinType)
	return CLambda [[self ent mixin; ... == ent or HasMixin(..., mixin)]] {entity, mixinType}
end

function EntityFilterMixin(mixinType)
	return CLambda [[HasMixin(..., self[1])]] {mixinType}
end

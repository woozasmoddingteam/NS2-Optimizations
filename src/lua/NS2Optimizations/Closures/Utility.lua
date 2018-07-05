assert(EntityFilterOne)

function EntityFilterOne(entity)
	if entity == nil then
		return Lambda  [[false]]
	else
		return SLambda [[ self ent; ... == ent ]] (entity)
	end
end

function EntityFilterOneAndIsa(entity, classname)
	return SLambda [[self ent cls; ... == ent or (...):isa(cls)]] (entity, classname)
end

function EntityFilterTwo(entity1, entity2)
	return SLambda [[self ent1 ent2; ... == ent1 or ... == ent2]] (entity1, entity2)
end

function EntityFilterTwoAndIsa(ent1, ent2, cls)
	return SLambda [[self ent1 ent2 cls; ... == ent1 or ... == ent2 or (...):isa(cls)]] (ent1, ent2, cls)
end

function EntityFilterOnly(entity)
	return SLambda [[ ... ~= self[1] ]] (entity)
end

function EntityFilterAll()
	return Lambda [[true]]
end

function EntityFilterAllButIsa(classname)
	return SLambda [[self cls; not (...):isa(cls)]] (classname)
end

function EntityFilterAllButMixin(mixinType)
	return SLambda [[self mixin; not HasMixin(..., mixin)]] (mixinType)
end

function EntityFilterMixinAndSelf(entity, mixinType)
	return SLambda [[self ent mixin; ... == ent or HasMixin(..., mixin)]] (entity, mixinType)
end

function EntityFilterMixin(mixinType)
	return SLambda [[self mixin; HasMixin(..., mixin)]] (mixinType)
end

function Copy(t)
	if type(t) == "table" then
		return table.iduplicate(t)
	elseif type(t) == "cdata" then
		if t:isa("Vector") then
			return Vector(t)
		elseif t:isa("Angles") then
			return Angles(t)
		elseif t:isa("Coords") then
			return Coords(t)
		elseif t:isa("Trace") then
			return Trace(t)
		else
			return t
		end
	else
		return t
	end
end

----------------------------------------------------------------------------------------------------
--- Making Lua look like Prolog:
---
--- Let's use metatables for something other than emulating prototype-based OO. By making the
--- __index metamethod create values for undefined things, we can make Lua look like Prolog!
--- We create empty tables for anything starting with a capital letter, functions that populate
--- those tables for lowercase things (to assign relationships) and if a name begins with "is_"
--- then it becomes a function that queries those tables.
----------------------------------------------------------------------------------------------------
local cjson=require "cjson";
 
setmetatable(_G,{ __index = 
                  function(globals, name)
					 if name=="goal" then
					 	return rawget(globals,name);
					 end
					 if name=="facts" then
						if rawget(globals,name)==nil then
							rawset(globals, name, {})
						end
					 	return rawget(globals,name);
					 end

					 if name:match("^[A-Z]") then
						if rawget(globals, name)==nil then
							rawset(globals, name, {name=name,vtype="value"})
						end
                     else -- rule
                        local rule = make_facts(name)
                        rawset(globals, name, rule)
                     end
                     return rawget(globals, name)
                  end })
 
function make_predicate(name)
   return function(a, b)
             return b[name] == a
          end
end
function start_query()
	_G.goal=true;
end	
function stop_query()
	_G.goal=false;
end	

function call_facts(obj,...)
	local name=obj.name;
	local arg={...};
	--print("call:",name,cjson.encode(obj),cjson.encode(arg));
	local query=_G.goal;
	for i,v in ipairs(arg) do
		if v.vtype=="value" then
			query=true;
		end
	end
	if _G.facts[name]==nil then
		_G.facts[name]={};
	end
	local len=#arg;
	local match={};
	if _G.facts[name]==nil then
		_G.facts[name]={};
	end
	for i,v in ipairs(_G.facts[name]) do
		if v.len==len then
			local flag=true;
			for j,vv in ipairs(v.fact) do
				if arg[j].vtype~="value" then
					if arg[j].name~=vv.name then
						flag=false;
					end
				end
			end
			if flag then
				table.insert(match,{value=v,arg=arg});
				if not query then
					v.times=v.times+1;
				end
			end
		end
	end
	if not query  then
		if #match==0 then
			table.insert(_G.facts[name],{len=#arg,fact=arg,times=1});
		end
	end
	if #match > 0 then
		return match;
	end
	return false;
end

function make_facts(name)
	local obj={vtype="atom" ,name=name};
	setmetatable(obj,{__call=call_facts});
	return obj;
end

function call_rand(index,result,args,all_result)
	if index>#args then
		local obj={};
		for i,v in pairs(result) do
			obj[i]=v;
		end
		table.insert(all_result,obj);
		return true;
	end
	local arg=args[index];
	for match_index=1,#arg do
		--print("index:",index,match_index,#arg);
		local cur={};
		local match=arg[match_index];
		local flag=true;
		for i,v in pairs(match.arg) do
			--print(cjson.encode(v));
			local value=match.value.fact[i];
			if result[v.name]==nil then
				result[v.name]=value;
				table.insert(cur,v.name);
			else
				if result[v.name].name~=value.name then
					flag=false;
				end
				--print(v.name,result[v.name].name,value.name,flag);
			end
		end
		if flag then
			--cjson.encode(result);
			call_rand(index+1,result,args,all_result);
		end
		for i,v in pairs(cur) do
			result[v]=nil;
		end
	end
	return false;
end
-- prolog  ,
function call_and(...)
	local arg={...};
	local result={};
	local all_result={};
	call_rand(1,result,arg,all_result);
	--print(cjson.encode(#all_result));
	return all_result;
end

function make_rule(func)
	return function(...)
		local arg={...};
		local result=func(unpack(arg));
		local match={};
		for i,v in ipairs(result) do
				local value={};
				for j,a in ipairs(arg) do
					table.insert(value,v[a.name]);
				end
				table.insert(match,{value=value,arg=arg});
		end
		if #match<1 then
			return false;
		end
		return match;
	end
end
 
----------------------------------------------------------------------------------------------------
--- Example: ---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
 
--father(Vader, Luke)
--father(Vader, Leia)
-- 
--friend(Vader, Emperor)
--friend(Emperor, Vader)
--friend(Han, Luke)
--friend(Luke, Han)
-- 
--brother(Luke, Leia)
--sister(Leia, Luke)

print(father(vader, luke))
--_G.goal=true; 
print("==================");

print(father(vader, luke))
print(father(lader, luke))
--assert(sister(Leia, Luke))
--assert(friend(Han, Luke))
--assert(friend(Luke, Han))
-- 
--assert(not friend(Vader, Luke))
--assert(not friend(Han, Jabba))


word(d,o,g);
word(r,u,n);
word(t,o,p);
word(f,i,v,e);

word(f,o,u,r);
word(l,o,s,t);
word(m,e,s,s);
word(u,n,i,t);

word(b,a,k,e,r);
word(f,o,r,u,m);
word(g,r,e,e,n);

word(s,u,p,e,r);
word(p,r,o,l,o,g);
word(v,a,n,i,s,h);

word(w,o,n,d,e,r);
word(y,e,l,l,o,w);
--
--
--

solution=make_rule(function(L1,L2,L3,L4,L5,L6,L7,L8,L9,L10,L11,L12,L13,L14,L15,L16)
	return call_and(
			word(L1,L2,L3,L4,L5),
			word(L1,L6,L9,L15),
			word(L3,L7,L11),
			word(L5,L8,L13,L16),
			word(L9,L10,L11,L12,L13,L14)
		);
end);
--
--print(cjson.encode(_Other.value));
--print(cjson.encode(_G.facts));
--
--start_query();
--print("=========================");
--print(cjson.encode(father(unpack({Vader, Luke}))))
--print(cjson.encode(father(Vader, Luke)))
--print(cjson.encode(father(Vader, Luke)))
--
local result=solution(L1,L2,L3,L4,L5,L6,L7,L8,L9,L10,L11,L12,L13,L14,L15,L16);
print(cjson.encode(result));
--for i,v in pairs(result[1]) do
--	print(i,v.name);
--end
--
--

father(a,b);
father(b,a);
father(b,c);

-- gr(X1,Y1):-father(X1,Z),father(Z,Y1).
gr=make_rule(function(X1,Y1)
	return call_and(father(X1,Z),father(Z,Y1));
end);
print(cjson.encode(gr(X,Y)));
print(cjson.encode(gr(X,X)));


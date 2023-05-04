class IOManager
{

	//We can't use linkkind in native classes
	static LINK_TARGET = 44;
	static LINK_SWITCHLINK = 21;
	static LINK_CONTAINS = 10;

	inputs = null;
	outputs = null;
	outputsLow = null;

	seed = null;
	
	constructor(cSeed)
	{
		inputs = [];
		outputs = [];
		outputsLow = [];
		
		seed = cSeed;
	}
	
	function GetInputsAndOutputsForAllObjectPools(obj, validInputTypes, prioritizeWorldObjects)
	{
		//print ("Prioritising world objects for " + obj + " set to " + prioritizeWorldObjects);
	
		foreach (ilink in Link.GetAll(-LINK_SWITCHLINK,obj))
		{
			local objectPool = sLink(ilink).dest;
			foreach (link in Link.GetAll(-LINK_TARGET,objectPool))
			{
				local target = sLink(link).dest;
				ProcessInput(target,validInputTypes);
			}
		}
		foreach (olink in Link.GetAll(LINK_SWITCHLINK,obj))
		{
			local objectPool = sLink(olink).dest;
			foreach (link in Link.GetAll(-LINK_TARGET,objectPool))
			{
				local target = sLink(link).dest;
				ProcessOutput(target,prioritizeWorldObjects);
			}
		}
		
		srand(seed);
		inputs = Array_Shuffle(inputs);
		outputs = GetOutputsArray();
	}
	
	function RefreshOutput(currentOutput, fuzzy)
	{
		local output = outputs[currentOutput];
		srand(seed + currentOutput + output.output);
		
		//print ("refreshing array position " + currentOutput);
		outputs.remove(currentOutput);
		
		//Add a little variation to the output, otherwise each container gets exactly 1 item
		if (fuzzy)
		{
			local min = outputs.len() * 0.35;
			local range = outputs.len() - 1 - min;
			local index = rand() % range + min;
			outputs.insert(index,output);
		}
		else
		{
			outputs.append(output);
		}
	}
	
	function IsContainer(item)
	{
		return Property.Get(item,"ContainDims","Width") != 0 || Property.Get(item,"ContainDims","Height") != 0;
	}
	
	function ProcessInput(item, validInputTypes)
	{
		if (Object.HasMetaProperty(item,"Object Randomiser - No Auto Input"))
			return;
	
		if (IsContainer(item))
		{
			foreach (link in Link.GetAll(LINK_CONTAINS,item))
			{
				local contained = sLink(link).dest;
				if (IsInputValid(contained,validInputTypes))
				{
					local input = Input(contained);
					inputs.append(input);
				}
			}
		}
		else if (IsInputValid(item,validInputTypes))
		{
			local input = Input(item);
			inputs.append(input);
		}
	}
	
	function IsInputValid(item,types)
	{
		//Check that the item can actually be an input
		if (Object.HasMetaProperty(item,"Object Randomiser - No Auto Input"))
			return false;
	
		//Check existing inputs
		foreach(input in inputs)
		{
			if (input.item == item)
				return false;
		}
	
		//Check archetypes
		foreach (archetype in types)
		{
			if (isArchetype(item,archetype))
				return true;
		}
		return false;
	}
	
	function ProcessOutput(item,prioritizeWorldObjects)
	{		
		//local isContainer = isArchetype(item,-379) || isArchetype(item,-118);
		//local isMarker = ShockGame.GetArchetypeName(item) == "rndOutputMarker";
		
		if (Object.HasMetaProperty(item,"Object Randomiser - No Auto Output"))
			return;
		
		if (IsContainer(item))
		{
			local output = Output(item);
			AddOutput(output,false);
		}
		else if (!Object.HasMetaProperty(item,"Object Randomiser - No Auto Input"))
		{
			local output = PhysicalOutput(item);
			AddOutput(output,prioritizeWorldObjects);
		}
	}

	function AddOutput(item,prioritize)
	{
		srand(seed + item.output);
		local highPriority = (prioritize && (rand() % 4) == 0)
			|| Object.HasMetaProperty(item.output,"Object Randomiser - High Priority Output");
		//local highPriority = prioritize || Object.HasMetaProperty(item.output,"Object Randomiser - High Priority Output");
		
		if (highPriority)
		{
			//print (item.output + " was high priority");
			outputs.append(item);
		}
		else
		{
			//print (item.output + " was low priority");
			outputsLow.append(item);
		}
	}
	
	function isArchetype(obj,type)
	{
		return obj == type || Object.Archetype(obj) == type || Object.InheritsFrom(obj,type);
	}
	
	function GetOutputsArray()
	{
		outputs = Array_Shuffle(outputs);
		outputsLow = Array_Shuffle(outputsLow);
		
		//combine both arrays
		foreach(lowPriority in outputsLow)
		{
			outputs.append(lowPriority);
		}
		
		return outputs;
	}
	
	//Shuffles an array
	//https://en.wikipedia.org/wiki/Knuth_shuffle
	function Array_Shuffle(shuffle = [])
	{		
		for (local position = shuffle.len() - 1;position > 0;position--)
		{
			local val = rand() % position;
			local temp = shuffle[position];
			shuffle[position] = shuffle[val];
			shuffle[val] = temp;
		}		
				
		return shuffle;
	}
}

class Input
{
	valid = null;
	item = null;
	name = null;
	containerOnly = null;
	isJunk = null;
	
	constructor(cItem)
	{
		item = cItem;
		name = ShockGame.GetArchetypeName(cItem);
		valid = true;
		containerOnly = Object.HasMetaProperty(cItem,"Object Randomiser - Container Only");
		isJunk = checkIsJunk(cItem);
	}
	
	//Items with these archetypes will be counted as junk.
	static junkArchetypes = [
		-68, //Plant #1
		-69, //Plant #2
		-1221, //Mug
		-1398, //Heart Pillow
		-1214, //Ring Buoy
		-1255, //Magazines
		-4286, //Basketball
		
		//Controversial Ones, might remove
		-91, //Soda
		-92, //Chips
		-964, //Vodka
		-965, //Champagne
		-966, //Juice
		-967, //Liquor
		-1396, //Cigarettes
		-3864, //GamePig
		-3865, //GamePig Cartridges
		-1105, //Beaker
	];
	
	function checkIsJunk(item)
	{
		foreach(type in junkArchetypes)
		{
			if (item == type || Object.Archetype(item) == type || Object.InheritsFrom(item,type))
				return true;
		}
		return false;
	}
}

class Output
{
	output = null;
	name = null;
	valid = null;
	secret = null;
	noJunk = null;
	
	constructor(cOutput)
	{
		output = cOutput;
		name = ShockGame.GetArchetypeName(cOutput);
		valid = true;
		secret = Object.HasMetaProperty(cOutput,"Object Randomiser - Secret");
		noJunk = Object.HasMetaProperty(cOutput,"Object Randomiser - No Junk");
	}
	
	function checkHandleMove(input,nosecret)
	{
		if (!valid)
			return false;
			
		//handle "secret" outputs
		if (nosecret && secret)
			return false;
			
		if ((secret || noJunk) && input.isJunk)
			return false;
		
		return true;
	}
	
	function HandleMove(input,nosecret)
	{
		if (!checkHandleMove(input,nosecret))
			return false;
	
		//print ("moving " + input.item + " to container " + output);
	
		Container.Remove(input.item);
		Link.Create(10,output,input.item); //Contains. We can't use linkkind in on SqRootScript classes
		Property.SetSimple(input.item, "HasRefs", FALSE);
		return true;
	}
}



class PhysicalOutput extends Output
{
	static LINK_TARGET = 44;

	facing = null;
	position = null;
	exactPosition = null;
	noFacing = null;
	
	constructor(cOutput)
	{
		base.constructor(cOutput);
		facing = Object.Facing(cOutput);
		position = Object.Position(cOutput);
		exactPosition = Object.HasMetaProperty(cOutput,"Object Randomiser - Exact Positioning");
		noFacing = Object.HasMetaProperty(cOutput,"Object Randomiser - No Facing");
	}
	
	function checkHandleMove(input,nosecret)
	{
		local check = base.checkHandleMove(input,nosecret);
		
		if (!check)
			return false;
			
		if (input.containerOnly)
			return false;
		
		return true;
	}
	
	function HandleMove(input, nosecret)
	{
		if (!checkHandleMove(input,nosecret))
			return false;
			
		if (!Link.AnyExist(LINK_TARGET,output))
			return false;
		
		/* Broken currently - do not use!
		if (!Physics.HasPhysics(input.item))
			return false;
		*/
			
		//prevent output from being used again
		foreach(target in Link.GetAll(LINK_TARGET,output))
			Link.Destroy(target);
	
		//Move object into position
		Container.Remove(input.item);
		
		if (exactPosition)
		{
			Object.Teleport(input.item, position, facing);
		}
		else
		{
			local position_up = vector(position.x, position.y, position.z + 0.2);
			Object.Teleport(input.item, position_up, FixItemFacing(input.item));
			
			//Fix up physics
			Property.Set(input.item, "PhysControl", "Controls Active", "");
			Physics.SetVelocity(input.item,vector(0,0,10));
		}
		
		Physics.Activate(input.item);
		
		//Make object render
		Property.SetSimple(input.item, "HasRefs", TRUE);
		return true;
	}
	
	//Items with these archetypes will have their X, Y and Z facing set to the specified value
	static fixArchetypes = [
		[-938,-1,0,-1], //Cyber Modules
		[-85,0,0,-1], //Nanites
		[-1396,4000,0,-1], //Ciggies
		//[-964,-1,-1,-1], //Vodka
	];
	
	function FixItemFacing(item)
	{
		if (noFacing)
			return vector(0, facing.y, 0);
	
		foreach (archetype in fixArchetypes)
		{
			local type = archetype[0];
			if (item == type || Object.Archetype(item) == type || Object.InheritsFrom(item,type))
			{
				local x = archetype[1];
				local y = archetype[2];
				local z = archetype[3];
				if (x == -1)
					x = facing.x;
				if (y == -1)
					y = facing.y;
				if (z == -1)
					z = facing.z;
				
				return vector(x, y, z);
				//return vector(archetype[1], archetype[2], archetype[3]);
				//return vector(facing.x + archetype[1], 0, facing.z + archetype[3]);
			}
		}
		return facing;
	}
}
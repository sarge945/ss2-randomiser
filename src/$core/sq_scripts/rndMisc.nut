class IOManager
{

	//We can't use linkkind in native classes
	static LINK_TARGET = 44;
	static LINK_SWITCHLINK = 21;
	static LINK_CONTAINS = 10;

	inputs = null;
	outputs = null;
	outputsLow = null;

	seed = null; //The random seed we are using to generate.
	ignorePriority = null; //Ignore all priority, give all outputs equal weight.
	randomiser = null; //The randomiser object that created this
	allowedTypes = null; //Archetypes that are allowed to randomise
	prioritizeWorldObjects = null; //Should world objects get priority (1 in 4 chance)
	fuzzy = null; //Whether or not items can "bubble" into the same containers, rather than simply iterating the entire list. Fuzzy will result in less sets where everything always has 1-2 items, and gives more variation.
	
	constructor(cRandomiser, cSeed, cIgnorePriority, cAllowedTypes, cPrioritizeWorld, cFuzzy)
	{
		inputs = [];
		outputs = [];
		outputsLow = [];
		
		randomiser = cRandomiser;
		seed = cSeed;
		ignorePriority = cIgnorePriority;
		allowedTypes = cAllowedTypes;
		prioritizeWorldObjects = cPrioritizeWorld;
		fuzzy = cFuzzy;
	}
	
	function GetInputsAndOutputsForAllObjectPools()
	{
		//print ("Prioritising world objects for " + randomiser + " set to " + prioritizeWorldObjects);
		
		foreach (ilink in Link.GetAll(-LINK_SWITCHLINK,randomiser))
		{	
			local objectPool = sLink(ilink).dest;
			foreach (link in Link.GetAll(-LINK_TARGET,objectPool))
			{			
				local target = sLink(link).dest;
				ProcessInput(target);
			}
		}
		foreach (olink in Link.GetAll(LINK_SWITCHLINK,randomiser))
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
	
	//Check if an input exists for a given output
	//This will only be true if it's a physical output
	function InputExistsForOutput(output)
	{
		foreach (input in inputs)
		{	
			if (input.item == output.output)
				return true;
		}
		return false;
	}
	
	function RefreshOutput(currentOutput, forceNoFuzzy)
	{
		local output = outputs[currentOutput];
		srand(seed + currentOutput + output.output);
		
		//print ("refreshing array position " + currentOutput);
		outputs.remove(currentOutput);
		
		//Add a little variation to the output, otherwise each container gets exactly 1 item
		if (fuzzy && !forceNoFuzzy)
		{
			local min = outputs.len() * 0.35;
			local range = outputs.len() - min;
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
	
	function ProcessInput(item)
	{
		if (Object.HasMetaProperty(item,"Object Randomiser - No Auto Input"))
			return;
	
		if (IsContainer(item))
		{
			foreach (link in Link.GetAll(LINK_CONTAINS,item))
			{
				local contained = sLink(link).dest;
				if (IsInputValid(contained))
				{
					local input = Input(contained);
					inputs.append(input);
				}
			}
		}
		else if (IsInputValid(item))
		{
			local input = Input(item);		
			inputs.append(input);
		}
	}
	
	function IsInputValid(item)
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
		foreach (archetype in allowedTypes)
		{
			if (isArchetype(item,archetype))
				return true;
		}
		
		return false;
	}
	
	function ProcessOutput(item,prioritizeWorldObjects)
	{		
		//local isContainer = isArchetype(item,-379) || isArchetype(item,-118);
		local isMarker = ShockGame.GetArchetypeName(item) == "rndOutputMarker";
		
		if (Object.HasMetaProperty(item,"Object Randomiser - No Auto Output"))
			return;
		
		if (IsContainer(item))
		{
			local output = Output(item,randomiser);
			AddOutput(output,false);
		}
		else if (!Object.HasMetaProperty(item,"Object Randomiser - No Auto Input"))
		{
			local output = PhysicalOutput(item,randomiser);
			AddOutput(output,prioritizeWorldObjects);
			
			if (InputExistsForOutput(output) || isMarker)
				output.Setup();
		}
	}

	function AddOutput(item,prioritize)
	{
		srand(seed + item.output);
		local highPriority = (prioritize && (rand() % 4) == 0) || item.highPriority;
		
		if (highPriority && !ignorePriority)
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
	
	static function isArchetype(obj,type)
	{
		return obj == type || Object.Archetype(obj) == type || Object.Archetype(obj) == Object.Archetype(type) || Object.InheritsFrom(obj,type);
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
			if (IOManager.isArchetype(item,type))
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
	highPriority = null;
	randomiser = null;
	
	constructor(cOutput, cRandomiser)
	{
		output = cOutput;
		name = ShockGame.GetArchetypeName(cOutput);
		valid = true;
		secret = Object.HasMetaProperty(cOutput,"Object Randomiser - Secret");
		highPriority = Object.HasMetaProperty(cOutput,"Object Randomiser - High Priority Output");
		noJunk = Object.HasMetaProperty(cOutput,"Object Randomiser - No Junk") || highPriority || secret;
		randomiser = cRandomiser;
	}
	
	function checkHandleMove(input,nosecret)
	{
		if (!valid)
			return false;
			
		//handle "secret" outputs
		if (nosecret && secret)
			return false;
		
		//handle junk items
		if (noJunk && input.isJunk)
			return false;
		
		return true;
	}
	
	function Setup()
	{
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
	noFacing = null;
	physicsControls = null;
	selfOnly = null;
	
	constructor(cOutput, cRandomiser)
	{
		base.constructor(cOutput, cRandomiser);
		facing = Object.Facing(cOutput);
		position = Object.Position(cOutput);
		noFacing = Object.HasMetaProperty(cOutput,"Object Randomiser - No Facing");
		physicsControls = Property.Get(cOutput, "PhysControl", "Controls Active");
		selfOnly = Object.HasMetaProperty(cOutput,"Object Randomiser - Output Self Only");
	}
	
	function checkHandleMove(input,nosecret)
	{
		local check = base.checkHandleMove(input,nosecret);
		
		if (!check)
			return false;
		
		if (input.item != output && selfOnly)
			return false;
		
		if (input.containerOnly && (input.item != output || !selfOnly))
			return false;
			
		if (!Link.AnyExist(LINK_TARGET,0,output))
			return false;
		
		/*
		//Disable - this is causing issues
		if (!Physics.HasPhysics(input.item))
			return false;
		*/
		
		return true;
	}
	
	function Setup()
	{	
		//Mark output as usable
		Link.Create(LINK_TARGET,randomiser,output);
	}
	
	//Items in this table will be considered the same archetype for the SameItemType function
	static similarArchetypes = [
		[-964, -965, -967], //Vodka, Champagne, Liquor
		[-52, -53, -54, -57, -58, -59, -61], //Med Hypo, Toxin Hypo, Rad Hypo, Psi Hypo, Speed Hypo, Strength Booster, PSI Booster
	];
	
	function SameItemType(input)
	{		
		if (IOManager.isArchetype(input.item,output))
			return true;
			
		local iArch = Object.Archetype(input.item);
		local oArch = Object.Archetype(output);
			
		//Similar Archetypes count for the same
		foreach (archList in similarArchetypes)
		{
			local iValid = false;
			local oValid = false;
			foreach (arch in archList)
			{
				if (iArch == arch)
					iValid = true;
				if (oArch == arch)
					oValid = true;
			}
			if (iValid && oValid)
				return true;
		}
	}
	
	function HandleMove(input, nosecret)
	{
		if (!checkHandleMove(input,nosecret))
			return false;
		
		//Set output as unusable
		foreach (ilink in Link.GetAll(LINK_TARGET,0,output))
			Link.Destroy(ilink);
		
		//Move object out of container
		Container.Remove(input.item);
		
		//Make object render
		Property.SetSimple(input.item, "HasRefs", TRUE);
		
		//If we are the same object, don't do anything
		if (input.item == output)
		{
		}
		//If we are the same archetype, don't bother doing any of the physics stuff, and don't remove controls
		//Instead, we need to just teleport the item to the output,
		//and give it the same physics controls, so that it looks the same
		else if (SameItemType(input))
		{
			Object.Teleport(input.item, position, facing);
			Property.Set(input.item, "PhysControl", "Controls Active", physicsControls);
		}
		else
		{
			local position_up = vector(position.x, position.y, position.z + 0.2);
			Object.Teleport(input.item, position_up, FixItemFacing(input.item));
			
			//Fix up physics
			Property.Set(input.item, "PhysControl", "Controls Active", "");
			Physics.SetVelocity(input.item,vector(0,0,10));
			Physics.Activate(input.item);
		}
		
		return true;
	}
	
	//Items with these archetypes will have their X, Y and Z facing set to the specified value
	static fixArchetypes = [
		[-938,0,0,-1], //Cyber Modules
		[-85,0,0,-1], //Nanites
		[-1396,90,0,-1], //Ciggies
		[-99,-1,0,-1], //Implants
		[-91,0,-1,-1], //Cola
		[-51,-1,0,-1], //Hypos
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
			}
		}
		//return facing;
		return vector(0,0,facing.z);
	}
}
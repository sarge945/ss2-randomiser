//IOCollection converts a mess of target/etc links into a usable structure of inputs and outputs
class rndIOCollection
{
	//We can't use linkkind in native classes
	static LINK_TARGET = 44;
	static LINK_SWITCHLINK = 21;
	static LINK_CONTAINS = 10;

	inputs = null;
	outputs = null;
	outputsContainers = null;
	outputsMarkers = null;
	outputsItems = null;
	randomiser = null;
	
	constructor(cRandomiser)
	{
		randomiser = cRandomiser;
		inputs = [];
		outputs = [];
		outputsContainers = [];
		outputsMarkers = [];
		outputsItems = [];
		GetInputsAndOutputsForRandomiser();
	}
	
	function GetInputsAndOutputsForRandomiser()
	{
		//-SWITCHLINKS are inputs
		foreach (ilink in Link.GetAll(-LINK_SWITCHLINK,randomiser))
		{	
			local objectPool = sLink(ilink).dest;
			foreach (link in Link.GetAll(-LINK_TARGET,objectPool))
			{			
				local target = sLink(link).dest;
				ProcessInput(target);
			}
		}
		
		//SWITCHLINKS are outputs
		foreach (olink in Link.GetAll(LINK_SWITCHLINK,randomiser))
		{
			local objectPool = sLink(olink).dest;
			foreach (link in Link.GetAll(-LINK_TARGET,objectPool))
			{
				local target = sLink(link).dest;
				ProcessOutput(target);
			}
		}
	}
	
	function ProcessInput(obj)
	{
		if (IsContainer(obj))
		{
			foreach (link in Link.GetAll(LINK_CONTAINS,obj))
			{
				local contained = sLink(link).dest;
				if (ValidateInput(contained))
				{
					local input = Input(contained);
					inputs.append(input);
				}
			}
		}
		else
		{
			if (ValidateInput(obj))
			{
				local input = Input(obj);
				inputs.append(input);
			}
		}
	}
	
	function ProcessOutput(obj)
	{
		if (!ValidateOutput(obj))
			return;
	
		local output;
		if (IsContainer(obj))
		{
			output = ContainerOutput(obj);
			outputsContainers.append(output);
		}
		else if (IsMarker(obj))
		{
			output = MarkerOutput(obj);
			outputsMarkers.append(output);
		}
		else
		{
			output = ItemOutput(obj);
			outputsItems.append(output);
		}
		outputs.append(output);
	}
	
	function ValidateInput(obj)
	{
		if (Object.HasMetaProperty(obj,"Object Randomiser - No Auto Input"))
			return false;
		return true;
	}
	
	function ValidateOutput(obj)
	{
		if (Object.HasMetaProperty(obj,"Object Randomiser - No Auto Output"))
			return false;
		return true;
	}
	
	function IsContainer(obj)
	{
		return Property.Get(obj,"ContainDims","Width") != 0 || Property.Get(obj,"ContainDims","Height") != 0;
	}
	
	function IsMarker(obj)
	{
		return ShockGame.GetArchetypeName(obj) == "rndOutputMarker";
	}
}

class Input
{
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
	
	function GetIsJunk()
	{
		foreach(type in junkArchetypes)
		{
			if (rndUtil.isArchetype(obj,type))
				return true;
		}
		return false;
	}

	obj = null;
	isJunk = null;

	constructor(cObj)
	{
		obj = cObj;
		isJunk = GetIsJunk();
	}
}

class Output
{
	static LINK_CONTAINS = 10;
	static LINK_TARGET = 44;
	static LINK_SWITCHLINK = 21;

	obj = null;
	highPriority = null;
	isMarker = null;
	isContainer = null;
	secret = null;
	noJunk = null;

	constructor(cObj)
	{
		obj = cObj;
		highPriority = Object.HasMetaProperty(cObj,"Object Randomiser - High Priority Output");
		secret = Object.HasMetaProperty(cObj,"Object Randomiser - Secret");
		noJunk = Object.HasMetaProperty(cObj,"Object Randomiser - No Junk") || secret || highPriority;
		isContainer = false;
		isMarker = false;
	}
	
	function CanMove(input)
	{
		if (noJunk && input.isJunk)
			return false;
	
		return true;
	}
	
	function HandleMove(input)
	{
		print ("Moving " + input.obj + " to " + obj);
	}
}

class ContainerOutput extends Output
{
	constructor(cObj)
	{
		base.constructor(cObj);
		isContainer = true;
	}
	
	function HandleMove(input)
	{
		base.HandleMove(input);
		Container.Remove(input.obj);
		Link.Create(LINK_CONTAINS,obj,input.obj);
		Property.SetSimple(input.obj, "HasRefs", FALSE);
	}
}

class PhysicalOutput extends Output
{
	position = null;
	facing = null;
	physicsControls = null;

	constructor(cObj)
	{
		base.constructor(cObj);
		position = Object.Position(obj);
		facing = Object.Facing(obj);
		physicsControls = Property.Get(obj, "PhysControl", "Controls Active");
	}
	
	function CanMove(input)
	{
		if (!base.CanMove(input))
			return false;
	
		if (!Link.AnyExist(LINK_TARGET,obj))
			return false;
	
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
		foreach (archetype in fixArchetypes)
		{
			local type = archetype[0];
			if (rndUtil.isArchetype(item,type))
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
		return vector(0,0,facing.z);
	}
	
	//Items in this table will be considered the same archetype for the SameItemType function
	static similarArchetypes = [
		[-964, -965, -967], //Vodka, Champagne, Liquor
		[-52, -53, -54, -57, -58, -59, -61], //Med Hypo, Toxin Hypo, Rad Hypo, Psi Hypo, Speed Hypo, Strength Booster, PSI Booster
		[-1256, -1257, -1258, -1259, -1260, -1261], //This Month in Ping-Pong, Rolling Monthly, Cigar Lover, DJ Lover, Kangaroo Quarterly, Vita Men's Monthly
	];
	
	function SameItemType(input)
	{		
		if (rndUtil.isArchetype(input.obj,obj))
			return true;
			
		local iArch = Object.Archetype(input.obj);
		local oArch = Object.Archetype(obj);
			
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
	
	function HandleMove(input)
	{
		base.HandleMove(input);
	
		//Set output as unusable
		foreach (ilink in Link.GetAll(LINK_TARGET,obj))
			Link.Destroy(ilink);
		
		//Move object out of container
		Container.Remove(input.obj);
		
		//Make object render
		Property.SetSimple(input.obj, "HasRefs", TRUE);
		
		//If we are the same object, don't bother doing anything.
		//Just remain in place.
		if (obj == input.obj)
		{
		}
		//If we are the same archetype, "lock" into position
		else if (SameItemType(input))
		{
			Object.Teleport(input.obj, position, facing);
			Property.Set(input.obj, "PhysControl", "Controls Active", physicsControls);
		}
		//Different objects, need to "jiggle" the object to fix physics issues
		else
		{
			local position_up = vector(position.x, position.y, position.z + 0.2);
			Object.Teleport(input.obj, position_up, FixItemFacing(input.obj));
			
			//Fix up physics
			Property.Set(input.obj, "PhysControl", "Controls Active", "");
			Physics.SetVelocity(input.obj,vector(0,0,10));
			Physics.Activate(input.obj);
		}
	}
}

class ItemOutput extends PhysicalOutput
{
	constructor(cObj)
	{
		base.constructor(cObj);
	}
}

class MarkerOutput extends PhysicalOutput
{
	constructor(cObj)
	{
		base.constructor(cObj);
		isMarker = true;
	}
}
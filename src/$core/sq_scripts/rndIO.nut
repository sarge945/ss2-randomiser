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
	seed = null;
	debugger = null;
	
	constructor(cRandomiser, cSeed, cDebugger)
	{
		randomiser = cRandomiser;
		inputs = [];
		outputs = [];
		outputsContainers = [];
		outputsMarkers = [];
		outputsItems = [];
		seed = cSeed;
		debugger = cDebugger;
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
		if (rndUtil.isContainer(obj))
		{
			foreach (link in Link.GetAll(LINK_CONTAINS,obj))
			{
				local contained = sLink(link).dest;
				if (ValidateInput(contained) && ValidateInput(obj))
				{
					local input = Input(contained,obj);
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
		
		local output = Output(obj,seed,debugger);
		outputs.append(output);
	
		if (rndUtil.isContainer(obj))
			outputsContainers.append(output);
		else if (output.isMarker)
			outputsMarkers.append(output);
		else
			outputsItems.append(output);
	}
	
	//Note: This is checked for both items AND containers.
	//If this returns false, containers will not be searched for items
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
}

class Input
{
	static LINK_CONTAINS = 10;
	static LINK_TARGET = 44;
	static LINK_SWITCHLINK = 21;

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
	containerOnly = null;
	originalContainer = null;

	constructor(cObj,cOriginalContainer = null)
	{
		obj = cObj;
		isJunk = GetIsJunk();
		containerOnly = Object.HasMetaProperty(cObj,"Object Randomiser - Container Only");
		originalContainer = cOriginalContainer;
	}
	
	function SetInvalid(randomiser)
	{
		Link.Create(LINK_TARGET,randomiser,obj);
	}
	
	function IsValid()
	{
		return !Link.AnyExist(-LINK_TARGET,obj)
	}
}

class Output
{
	static LINK_CONTAINS = 10;
	static LINK_TARGET = 44;
	static LINK_SWITCHLINK = 21;

	debugger = null;
	obj = null;
	highPriority = null;
	isMarker = null;
	isContainer = null;
	selfOnly = null;
	seed = null;
	outputLocations = null;
	currentOutputLocation = null;

	constructor(cObj, cSeed, cDebugger)
	{
		obj = cObj;
		highPriority = Object.HasMetaProperty(cObj,"Object Randomiser - High Priority Output");
		selfOnly = Object.HasMetaProperty(cObj,"Object Randomiser - Output Self Only");
		isContainer = rndUtil.isContainer(cObj);
		isMarker = rndUtil.isMarker(cObj);
		seed = cSeed;
		debugger = cDebugger;
		GetOutputLocations();
	}
	
	//Get all the possible locations this output can redirect to
	function GetOutputLocations()
	{
		outputLocations = [];
		
		//Add ourself, we are always a valid location
		if (isContainer)
			outputLocations.append(ContainerLocation(obj,highPriority));
		else
			outputLocations.append(PhysicalLocation(obj,highPriority));
			
		//Relocators are switchlinked to us, and markers are target linked to them
		foreach (slink in Link.GetAll(-LINK_SWITCHLINK,obj))
		{
			local relocator = sLink(slink).dest;
			//print ("found relocator: " + relocator);
			
			foreach (rlink in Link.GetAll(-LINK_TARGET,relocator))
			{
				local location = sLink(rlink).dest;
				if (rndUtil.isContainer(location))
					outputLocations.append(ContainerLocation(location,highPriority));
				else
					outputLocations.append(PhysicalLocation(location,highPriority));
			}
		}
		
		//We also accept markers which are directly targeted to us
		foreach (slink in Link.GetAll(-LINK_TARGET,obj))
		{
			local location = sLink(slink).dest;
			
			if (rndUtil.isMarker(location))
				outputLocations.append(PhysicalLocation(location,highPriority));
			
			//print ("found possible location: " + location);
		}
		
		outputLocations = rndFilterShuffle(outputLocations,seed).results;
	}
	
	//Get the first valid output location for a given input
	function GetValidOutputLocation(noSecret,input)
	{
		foreach(location in outputLocations)
		{		
			if (!location.IsValid())
				continue;
		
			//don't allow junk
			if (location.noJunk && input.isJunk)
				continue;
				
			//only allow junk
			if (location.onlyJunk && !input.isJunk)
				continue;
		
			//don't allow secrets
			if (location.secret && noSecret)
				continue;
				
			return location;
		}
		return null;
	}
	
	function CanMove(input,noSecret,allowOriginalLocation,debug = false)
	{
		//Check if the input is already moved
		if (!input.IsValid())
			return false;
			
		//Check if the output is valid
		if (!IsEnabled())
			return false;
	
		//Ensure that if self only is enabled, we only allow ourself
		if (selfOnly && !(rndUtil.isArchetype(input.obj,obj) || input.originalContainer == obj))
			return false;
	
		currentOutputLocation = GetValidOutputLocation(noSecret,input);
		
		if (currentOutputLocation == null)
			return false;
	
		return true;
	}
	
	function HandleMove(input)
	{
		if (currentOutputLocation == null)
			return;
	
		//print ("Moving " + input.obj + " to " + obj);		
		Container.Remove(input.obj);
		
		currentOutputLocation.HandleMove(input);
		
		if (!isContainer)
			DisableOutput();
	}
	
	function IsEnabled()
	{
		//Make sure the output is still enabled
		return Link.AnyExist(-LINK_SWITCHLINK,obj);
	}
	
	function Setup(randomiser)
	{
		//Link to Randomiser			
		Link.Create(-LINK_SWITCHLINK,obj,randomiser);
	
		foreach(location in outputLocations)
			location.Setup(randomiser);
	}
	
	function DisableOutput()
	{
		//Remove Randomiser link
		foreach (ilink in Link.GetAll(-LINK_SWITCHLINK,obj))
			Link.Destroy(ilink);
	}
}

class LocationBase
{
	static LINK_CONTAINS = 10;
	static LINK_TARGET = 44;
	static LINK_SWITCHLINK = 21;

	obj = null;

	secret = null;
	noJunk = null;
	onlyJunk = null;

	constructor(cObj,forceNoJunk)
	{
		obj = cObj;
		secret = Object.HasMetaProperty(cObj,"Object Randomiser - Secret");
		onlyJunk = Object.HasMetaProperty(cObj,"Object Randomiser - Junk Only") && !secret;
		noJunk = (Object.HasMetaProperty(cObj,"Object Randomiser - No Junk") || secret || forceNoJunk) && !onlyJunk;
	}
	
	//Overwrite this
	function HandleMove(input)
	{
	}
	
	//Overwrite this
	function IsValid()
	{
		return true;
	}
	
	function Setup(randomiser)
	{
	}
}

class ContainerLocation extends LocationBase
{
	function HandleMove(input)
	{
		base.HandleMove(input);
		Link.Create(LINK_CONTAINS,obj,input.obj);
		Property.SetSimple(input.obj, "HasRefs", FALSE);
	}
}

class PhysicalLocation extends LocationBase
{
	placer = null;
	
	constructor(cObj,forceNoJunk)
	{
		base.constructor(cObj,forceNoJunk)
		placer = ObjectPlacer(cObj);
	}

	function IsValid()
	{
		//Make sure the output is still enabled
		return Link.AnyExist(-LINK_SWITCHLINK,obj);
	}
	
	function DisableLocation(input)
	{
		//Remove Randomiser link
		foreach (ilink in Link.GetAll(-LINK_SWITCHLINK,obj))
			Link.Destroy(ilink);
	}
	
	function HandleMove(input)
	{
		base.HandleMove(input);
		placer.Place(input);
		DisableLocation(input);
	}
	
	function Setup(randomiser)
	{
		//Link to Randomiser			
		Link.Create(-LINK_SWITCHLINK,obj,randomiser);
	}
}

//This is responsible for making sure objects are placed correctly in the world
class ObjectPlacer
{
	obj = null;
	position = null;
	facing = null;
	physicsControls = null;
	
	function constructor(cObj)
	{
		obj = cObj;
		position = Object.Position(cObj);
		facing = Object.Facing(cObj);
		physicsControls = Property.Get(cObj, "PhysControl", "Controls Active");
	}

	function Place(input,noFacing = false)
	{	
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
		}
		//Different objects, need to "jiggle" the object to fix physics issues
		else
		{
			local position_up = vector(position.x, position.y, position.z + 0.2);
			Object.Teleport(input.obj, position_up, FixItemFacing(input.obj,noFacing));
			
			//Fix up physics
			Property.Set(input.obj, "PhysControl", "Controls Active", "");
			Physics.SetVelocity(input.obj,vector(0,0,10));
			Physics.Activate(input.obj);
		}
	}
	
	//Items with these archetypes will have their X, Y and Z facing set to the specified value
	static fixArchetypes = [
		[-938,0,0,-1], //Cyber Modules
		[-85,0,0,-1], //Nanites
		[-1396,90,0,-1], //Ciggies
		[-99,90,0,-1], //Implants
		[-91,0,-1,-1], //Cola
		[-51,-1,0,-1], //Hypos
		//[-964,-1,-1,-1], //Vodka
	];
	
	function FixItemFacing(item,noFacing)
	{
		if (noFacing)
			return vector(0,0,0);
	
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
		[-1455, -1485], //Circuit Board, RadKey Card
		[-1277, -2936], //Art Terminal, Code Art
	];
	
	function SameItemType(input)
	{		
		if (rndUtil.isArchetype(input.obj,obj))
			return true;
					
		//Similar Archetypes count for the same
		foreach (archList in similarArchetypes)
		{
			local iValid = false;
			local oValid = false;
			foreach (arch in archList)
			{
				if (rndUtil.isArchetype(input.obj,arch))
					iValid = true;
				if (rndUtil.isArchetype(obj,arch))
					oValid = true;
			}
			if (iValid && oValid)
				return true;
		}
	}
}
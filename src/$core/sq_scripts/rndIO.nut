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
	outputsRelocators = null;
	randomiser = null;
	seed = null;
	
	constructor(cRandomiser, cSeed)
	{
		randomiser = cRandomiser;
		inputs = [];
		outputs = [];
		outputsContainers = [];
		outputsMarkers = [];
		outputsRelocators = [];
		outputsItems = [];
		seed = cSeed;
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
		//If it's a redirector, add that instead
		local relocator = Link.GetOne(-LINK_SWITCHLINK,obj)
		if (relocator)
			obj = sLink(relocator).dest;
	
		if (!ValidateOutput(obj))
			return;
	
		local output;
		if (IsContainer(obj))
		{
			output = ContainerOutput(obj,seed);
			outputsContainers.append(output);
		}
		else if (IsRelocator(obj))
		{
			output = RelocatorOutput(obj,seed);
			outputsRelocators.append(output);
		}
		else
		{
			output = PhysicalOutput(obj,seed);
			
			if (output.isMarker)
				outputsMarkers.append(output);
			else
				outputsItems.append(output);
		}
		outputs.append(output);
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
	
	//TODO: Fix these
	function IsContainer(obj)
	{
		return Property.Get(obj,"ContainDims","Width") != 0 || Property.Get(obj,"ContainDims","Height") != 0;
	}
	
	function IsRelocator(obj)
	{
		return ShockGame.GetArchetypeName(obj) == "rndOutputRelocator"
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

	obj = null;
	highPriority = null;
	isMarker = null;
	isContainer = null;
	isRelocator = null;
	selfOnly = null;
	secret = null;
	noJunk = null;
	seed = null;

	constructor(cObj, cSeed)
	{
		obj = cObj;
		highPriority = Object.HasMetaProperty(cObj,"Object Randomiser - High Priority Output");
		secret = Object.HasMetaProperty(cObj,"Object Randomiser - Secret");
		noJunk = Object.HasMetaProperty(cObj,"Object Randomiser - No Junk") || secret || highPriority;
		selfOnly = Object.HasMetaProperty(cObj,"Object Randomiser - Output Self Only");
		isContainer = false;
		isMarker = false;
		isRelocator = false;
		seed = cSeed;
	}
	
	function CanMove(input,noSecret,allowOriginalLocation,debug = false)
	{
		//Check if the input is already moved
		if (!input.IsValid())
			return false;
	
		//Ensure that if self only is enabled, we only allow ourself
		if (selfOnly && !(rndUtil.isArchetype(input.obj,obj) || input.originalContainer == obj))
			return false;
	
		//don't allow junk
		if (noJunk && input.isJunk)
			return false;
		
		//don't allow secrets
		if (noSecret && secret)
			return false;
	
		return true;
	}
	
	function HandleMove(input)
	{
		//print ("Moving " + input.obj + " to " + obj);		
		Container.Remove(input.obj);
	}
	
	function Setup(randomiser)
	{
	}
}

class ContainerOutput extends Output
{
	constructor(cObj,cSeed)
	{
		base.constructor(cObj,cSeed);
		isContainer = true;
	}
	
	function HandleMove(input)
	{
		base.HandleMove(input);
		Link.Create(LINK_CONTAINS,obj,input.obj);
		Property.SetSimple(input.obj, "HasRefs", FALSE);
	}
}


class PhysicalOutput extends Output
{
	position = null;
	facing = null;
	physicsControls = null;

	constructor(cObj,cSeed)
	{
		base.constructor(cObj,cSeed);
		isMarker = ShockGame.GetArchetypeName(cObj) == "rndOutputMarker";
		position = Object.Position(cObj);
		facing = Object.Facing(cObj);
		physicsControls = Property.Get(cObj, "PhysControl", "Controls Active");
	}
	
	function OutputEnabled()
	{
		//Make sure the output is still enabled
		return Link.AnyExist(-LINK_SWITCHLINK,obj);
	}
	
	function DisableOutput(input)
	{
		//Remove Randomiser link
		foreach (ilink in Link.GetAll(-LINK_SWITCHLINK,obj))
			Link.Destroy(ilink);
	}
	
	function CanMove(input,noSecret,allowOriginalLocation,debug = false)
	{	
		if (!base.CanMove(input,noSecret,allowOriginalLocation,debug))
			return false;
	
		if (!OutputEnabled())
			return false;
	
		return true;
	}
	
	function HandleMove(input)
	{
		base.HandleMove(input);
		
		local placer = ObjectPlacer(obj,position,facing,physicsControls);
		placer.Place(input);
		
		DisableOutput(input);
	}
	
	function Setup(randomiser)
	{
		//Link to Randomiser			
		Link.Create(-LINK_SWITCHLINK,obj,randomiser);
	}
}

class RelocatorOutput extends Output
{
	linkedOutputs = null;
	currentOutput = null;
	
	constructor(cObj,cSeed)
	{
		base.constructor(cObj,cSeed);
		isRelocator = true;
		GetLinkedOuputs();
		GetHighPriority();
	}
	
	function GetHighPriority()
	{
		foreach(output in linkedOutputs)
		{
			if (output.highPriority)
			{
				highPriority = true;
				return;
			}
		}
	}
	
	//TODO: Refactor and properly add this to Utils
	function IsContainer(obj)
	{
		return Property.Get(obj,"ContainDims","Width") != 0 || Property.Get(obj,"ContainDims","Height") != 0;
	}
	
	function GetLinkedOuputs()
	{
		linkedOutputs = [];
	
		//~Targets are linked outputs
		foreach (ilink in Link.GetAll(-LINK_TARGET,obj))
		{
			local linkedObj = sLink(ilink).dest;
			//print ("Relocator " + obj + " found target destination " + linkedObj);
			if (IsContainer(linkedObj))
				linkedOutputs.append(ContainerOutput(linkedObj,seed));
			else
				linkedOutputs.append(PhysicalOutput(linkedObj,seed));
		}
		
		//SwitchLinks are used to keep track of how many objects we are "replacing", and are also outputs
		foreach (ilink in Link.GetAll(LINK_SWITCHLINK,obj))
		{
			local linkedObj = sLink(ilink).dest;
			//print ("Relocator " + obj + " found target object " + linkedObj);
			if (IsContainer(linkedObj))
				linkedOutputs.append(ContainerOutput(linkedObj,seed));
			else
				linkedOutputs.append(PhysicalOutput(linkedObj,seed));
		}
		
		linkedOutputs = rndFilterShuffle(linkedOutputs,seed).results;
		//foreach(lo in linkedOutputs)
			//print ("LinkedOutput -> " + lo.obj);
	}
	
	function CanMove(input,noSecret,allowOriginalLocation,debug = false)
	{	
		if (!OutputEnabled())
			return false;
		
		currentOutput = null;
		
		foreach (output in linkedOutputs)
		{
			if (output.CanMove(input,noSecret,allowOriginalLocation,true))
			{
				currentOutput = output;
				break;
			}
		}
		
		if (currentOutput == null)
			return false;
		
		return true;
	}
	
	function HandleMove(input)
	{
		if (currentOutput != null)
			currentOutput.HandleMove(input);
		
		DisableOutput();
	}
	
	function OutputEnabled()
	{
		//Make sure the output is still enabled
		return Link.AnyExist(-LINK_TARGET,obj);
	}
	
	//TODO: Refactor and properly add this to Utils
	function IsContainer(obj)
	{
		return Property.Get(obj,"ContainDims","Width") != 0 || Property.Get(obj,"ContainDims","Height") != 0;
	}
	
	function DisableOutput()
	{
		local switchlinks = [];
	
		//Remove a SwitchLink if we have any. If it's the last one, remove target link too
		foreach (link in Link.GetAll(LINK_SWITCHLINK,obj))
			switchlinks.append(link);
		
		if (switchlinks.len() > 0 && !IsContainer(obj))
		{
			//print ("Removing one switch link for " + obj);
			
			//Remove links from our current input so it can't be counted again
			Link.Destroy(switchlinks[0]);
			switchlinks.remove(0);
		}
		
		if (switchlinks.len() == 0)
		{
			//print ("Removing target links for " + obj);
		
			//Remove all Target Links
			foreach (ilink in Link.GetAll(-LINK_TARGET,obj))
				Link.Destroy(ilink);
		}
	}
	
	function Setup(randomiser)
	{
		//Link to Randomiser			
		Link.Create(-LINK_SWITCHLINK,obj,randomiser);
		
		//link all targets to randomiser
		foreach (ilink in Link.GetAll(-LINK_TARGET,obj))
			Link.Create(-LINK_SWITCHLINK,sLink(ilink).dest,randomiser);
	}
}

//This is responsible for making sure objects are placed correct;y
class ObjectPlacer
{
	obj = null;
	position = null;
	facing = null;
	physicsControls = null;
	
	function constructor(cObj, cPosition, cFacing, cPhysicsControls)
	{
		obj = cObj;
		position = cPosition;
		facing = cFacing;
		physicsControls = cPhysicsControls;
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
			Property.Set(input.obj, "PhysControl", "Controls Active", physicsControls);
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
		[-99,-1,0,-1], //Implants
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
}
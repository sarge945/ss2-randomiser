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
	obj = null;

	constructor(cObj)
	{
		obj = cObj;
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

	constructor(cObj)
	{
		obj = cObj;
		highPriority = Object.HasMetaProperty(cObj,"Object Randomiser - High Priority Output");
		isContainer = false;
		isMarker = false;
	}
	
	function CanMove(input)
	{
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

	constructor(cObj)
	{
		base.constructor(cObj);
		position = Object.Position(obj);
		facing = Object.Facing(obj);
	}
	
	function CanMove(input)
	{
		if (!Link.AnyExist(LINK_TARGET,obj))
			return false;
	
		return true;
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
		
		local position_up = vector(position.x, position.y, position.z + 0.2);
		Object.Teleport(input.obj, position_up, facing);
		
		//Fix up physics
		Property.Set(input.obj, "PhysControl", "Controls Active", "");
		Physics.SetVelocity(input.obj,vector(0,0,10));
		Physics.Activate(input.obj);
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
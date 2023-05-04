class IOManager
{

	//We can't use linkkind in native classes
	static LINK_TARGET = 44;
	static LINK_SWITCHLINK = 21;
	static LINK_CONTAINS = 10;

	inputs = null;
	outputs = null;
	outputsLow = null;
	
	constructor()
	{
		inputs = [];
		outputs = [];
		outputsLow = [];
	}
	
	function GetInputsAndOutputsForAllObjectPools(obj, validInputTypes, prioritizeWorldObjects)
	{
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
	}
	
	function ProcessInput(item, validInputTypes)
	{
		local isContainer = isArchetype(item,-379) || isArchetype(item,-118);
		
		if (isContainer)
		{
			if (!Object.HasMetaProperty(item,"Object Randomiser - No Auto Input"))
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
		}
		else if (!Object.HasMetaProperty(item,"Object Randomiser - No Auto Input"))
		{
			if (IsInputValid(item,validInputTypes))
			{
				local input = Input(item);
				inputs.append(input);
			}
		}
	}
	
	function IsInputValid(item,types)
	{
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
		local isContainer = isArchetype(item,-379) || isArchetype(item,-118);
		//local isMarker = ShockGame.GetArchetypeName(item) == "rndOutputMarker";
		
		if (isContainer && !Object.HasMetaProperty(item,"Object Randomiser - No Auto Output"))
		{
			local output = Output(item);
			AddOutput(output,false);
		}
		else if (!Object.HasMetaProperty(item,"Object Randomiser - No Auto Output"))
		{
			local output = PhysicalOutput(item);
			AddOutput(output,prioritizeWorldObjects);
		}
	}
	
	function AddOutput(item,prioritize)
	{
		local highPriority = (prioritize && Data.RandInt(0,3) == 0)
			|| Object.HasMetaProperty(item.output,"Object Randomiser - High Priority Output");
		
		if (highPriority)
			outputs.append(item);
		else
			outputsLow.append(item);
	}
	
	function isArchetype(obj,type)
	{
		return obj == type || Object.Archetype(obj) == type || Object.InheritsFrom(obj,type);
	}
	
	function GetInputsArray()
	{
		inputs = Array_Shuffle(inputs);
		
		return inputs;
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
		for (local position = shuffle.len() - 1;position >= 0;position--)
		{
			local val = Data.RandInt(0, position);
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
	
	constructor(cItem)
	{
		item = cItem;
		name = ShockGame.GetArchetypeName(cItem);
		valid = true;
	}
}

class Output
{
	output = null;
	name = null;
	valid = null;
	
	constructor(cOutput)
	{
		output = cOutput;
		name = ShockGame.GetArchetypeName(cOutput);
		valid = true;
	}
	
	function HandleMove(item)
	{
		if (!valid)
			return false;
	
		//print ("moving " + item + " to container " + output);
	
		Container.Remove(item);
		Link.Create(10,output,item); //Contains. We can't use linkkind in on SqRootScript classes
		Property.SetSimple(item, "HasRefs", FALSE);
		return true;
	}
}



class PhysicalOutput extends Output
{
	facing = null;
	position = null;
	
	constructor(cOutput)
	{
		output = cOutput;
		facing = Object.Facing(cOutput);
		position = Object.Position(cOutput);
		name = ShockGame.GetArchetypeName(cOutput);
		valid = true;
	}
	
	function HandleMove(item)
	{
		if (!valid || Object.HasMetaProperty(item,"Object Randomiser - Container Only"))
			return false;
			
		if (Object.IsTransient(output))
			return false;
		
		//if (!Physics.HasPhysics(item))
		//	return false;
			
		//prevent output from being used again
		//Object.AddMetaProperty(output, "Object Randomiser - Internal - Output Used");
		Object.SetTransience(output, true);
			
		//print ("moving " + item + " to physical output " + output);
	
		//GenerateOutput(item);
		Container.Remove(item);
		local position_up = vector(position.x, position.y, position.z + 0.2)
		Object.Teleport(item, position_up, FixItemFacing(item));
		Physics.DeregisterModel(item); //Fixes issues with "controlled" models
		Property.Set(item, "PhysAttr", "Flags", "[None]"); //Ditto
		Property.SetSimple(item, "HasRefs", TRUE);
		Physics.Activate(item);
		Physics.SetVelocity(item,vector(0,0,10));
		valid = false;
		return true;
	}
	
	//Items with these archetypes will have their X and Z facing set to the specified value
	static fixArchetypes = [
		[-938,0,0], //Cyber Modules
		[-85,0,0], //Nanites
		[-1396,3000,0], //Ciggies
		//[-964,0,0], //Vodka
	];
	
	function FixItemFacing(item)
	{
		if (Object.HasMetaProperty(output,"Object Randomiser - No Facing"))
			return vector(0, facing.y, 0);
	
		foreach (archetype in fixArchetypes)
		{
			local type = archetype[0];
			if (item == type || Object.Archetype(item) == type || Object.InheritsFrom(item,type))
			{
				return vector(archetype[1], facing.y, archetype[2]);
			}
		}
		return facing;
	}
}
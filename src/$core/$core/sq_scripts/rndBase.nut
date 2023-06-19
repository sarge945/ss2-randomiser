class rndBase extends SqRootScript
{
	static PHYSCONTROL_LOC_ROT = 24;

	seed = null;
	name = null;
	debugLevel = null;

	//Run Once
	function OnBeginScript()
	{
		debugLevel = getParam("debug",0);
		name = rndUtils.GetObjectName(self);
		//print (name + " (" + self + ") initialised");

		if (!GetData("Started"))
		{
			SetData("Started",true);
			Init(false);
		}
		else
			Init(true);
	}

	function SetSeed(reloaded)
	{
        if (reloaded)
        {
            seed = GetData("seed");
            return;
        }

		seed = getParam("forceSeed",-1);
		if (seed == -1)
		{
			seed = Data.RandInt(0,99999);
			SetData("seed",seed);
		}
	}

	function PrintDebug(msg,requiredDebugLevel = 0)
	{
		if (debugLevel >= requiredDebugLevel)
			print(GetIdentifier() + "> " + msg);
	}

	function ShowDebug(msg,requiredDebugLevel = 0)
	{
		if (debugLevel >= requiredDebugLevel)
		{
			ShockGame.AddText(GetIdentifier() + "> " + msg,"Player");
			print(GetIdentifier() + "> " + msg);
		}
	}

	//Make debug easier
	function GetIdentifier()
	{
		return "[" + self + "] " + name;
	}

	function Init(reloaded)
	{
	}

	// fetch a parameter or return default value
	// blatantly stolen from RSD
	function getParam(key, defVal)
	{
		return key in userparams() ? userparams()[key] : defVal;
	}

	// fetch an array of parameters
	// This is not complete - it will find values that aren't in the actual array
	// for instance, if you have myValue0, myValue1 they will be added correctly,
	// but myValueWhichIsReallyLong will also be added.
	// This needs to be updated to check that the only remaining parts after the name are numbers.
	function getParamArray(name,defVal = null)
	{
		local array = [];
		foreach(key,value in userparams())
		{
			if (key.find(name) == 0)
				array.append(value);
		}

		if (array.len() == 0 && defVal != null)
		{
			if (typeof(defVal == "array"))
				return defVal;
			else
				array.append(defVal);
		}

		return array;
	}

	//Copies over all the links of one type from one object to another.
	static function copyLinks(source,dest,linkType)
	{
		foreach (outLink in Link.GetAll(linkkind(linkType),source))
		{
			local realLink = sLink(outLink);
			Link.Create(realLink.flavor,dest,realLink.dest);
            //realLink.source = dest;
            //print("Creating new link " + linkType + " to " + dest);
		}
	}
}

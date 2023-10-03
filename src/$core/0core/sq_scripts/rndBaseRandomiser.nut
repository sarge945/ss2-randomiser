//Base class for all randomisers
//At bare minimum, randomisers will have a seed and some outputs
class rndBaseRandomiser extends rndBase
{
	outputs = null;
	rolls = null;
    allowedTypes = null;
    addedAllowedTypes = null;

    //If no allowed types are specified, use the default
    static allowedTypesDefault = [
        //-49,  //Goodies
        //-12,  //Weapons
        //-156, //Keys
        //-76,  //Audio Logs
        -30,    //Ammo
        -51,    //Patches
        -70,    //Devices (portable batteries etc)
        //-78,  //Armor
        -85,    //Nanites
        -99,    //Implants
        -320,   //Softwares
        -1105,  //Beakers
        -938,   //Cyber Modules
        -3863,  //GamePig Games
        -91,    //Soda Can
        -92,    //Chips
        -964,   //Vodka
        -965,   //Champagne
        -966,   //Juice
        -967,   //Liquor
        -1221,  //Mug
        -1396,  //Cigarettes
        -1398,  //Heart Pillow
        -4286,  //Basketall
        //-1214,    //Ring Buoy
        -1255,  //Magazines
        -4105,  //Annelid Healing Gland
        -1676,  //Medbed Key
        //-68,  //Potted plants
        //-69,  //Potted plants
    ];

    static bannedTypes = [
        "FakeNanites",
        //"PDA",
        "FakeCookie",
        "FakeKeys",
        "PDA Soft"
    ];
	
	function Init(reloaded)
	{	
		outputs = [];
		rolls = 0;
		SetSeed(reloaded);
        SetAllowedTypes();
	}

    function CheckAllowedTypes(input)
    {

        PrintDebug("CheckAllowedTypes: " + rndUtils.GetObjectName(input) + " (" + input + ")",99);
        if (rndUtils.isRandomiser(input))
        {
            return false;
        }

        foreach(type in bannedTypes)
        {
            if (rndUtils.isArchetype(input,type))
            {
                PrintDebug("Tried to add bad archetype: " + type + " (input " + input + ")",1);
                return false;
            }
        }
        foreach(type in allowedTypes)
        {
            if (rndUtils.isArchetype(input,type))
                return true;
        }
        foreach(type in addedAllowedTypes)
        {
            if (rndUtils.isArchetype(input,type))
                return true;
        }
        PrintDebug("Object " + input + " was not of allowed type (" + ShockGame.GetArchetypeName(input) + ")",2);
        return false;
    }

    function SetAllowedTypes()
    {
        //PrintDebug("SetAllowedTypes: " + self);
        allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
        addedAllowedTypes = getParamArray("addAllowedTypes",[]);

        PrintDebug("Allowed Types: ",99);
        foreach (allowedType in allowedTypes)
            PrintDebug("    " + allowedType,99);
        foreach (allowedType in addedAllowedTypes)
            PrintDebug("   +" + allowedType,99);
    }
	
	function ShowWelcomeMessage(randomiserType)
	{
		PrintDebug(randomiserType + " Randomiser Started. [seed: " + seed + ", outputs: " + outputs.len() + "]");
	}
	
	function Complete(randomiserType)
	{
		PrintDebug(randomiserType + " Randomiser Completed. Swapped " + rolls + " items");
		Object.Destroy(self);
	}
}

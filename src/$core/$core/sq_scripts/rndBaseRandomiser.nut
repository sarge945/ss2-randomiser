//Base class for all randomisers
//At bare minimum, randomisers will have a seed and some outputs
class rndBaseRandomiser extends rndBase
{
	outputs = null;
	rolls = null;
    allowedTypes = null;

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

	
	function Init(reloaded)
	{	
		outputs = [];
		rolls = 0;
		SetSeed(reloaded);
        SetAllowedTypes();
	}

    function CheckAllowedTypes(input)
    {
        foreach(type in allowedTypes)
        {
            if (rndUtils.isArchetype(input,type))
                return true;
        }
        return false;
    }

    function SetAllowedTypes()
    {
        allowedTypes = getParamArray("allowedTypes",allowedTypesDefault);
        local addAllowedTypes = getParamArray("addAllowedTypes",[]);
        foreach (add in addAllowedTypes)
            allowedTypes.append(add);
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

class rndOutput extends rndBase
{
    container = null;
    corpse = null;
    allowedTypes = null;

    outputItems = null;

    static REMOVE_TIMER = 3;

    timerID = null;

    function Init(reloaded)
    {
        outputItems = [];
        container = rndUtils.isContainer(self);
        corpse = rndUtils.isCorpse(self);
        SetData("position",Object.Position(self));
        SetData("facing",Object.Facing(self));
        SetData("physicsControls",Property.Get(self,"PhysControl","Controls Active"));
        PrintDebug("Output Online [container: " + container + ", corpse: " + corpse + "]",4);
        allowedTypes = getParamArray("allowedTypes",[]);
		SetSeed(reloaded);
    }

    function CheckAllowedTypes(input)
    {
        if (allowedTypes.len() == 0)
            return true;

        foreach(type in allowedTypes)
        {
            if (rndUtils.isArchetype(input,type))
                return true;
        }
        return false;
    }

    static function JunkCheck(input,output,RnoRespectJunk)
    {
        if (RnoRespectJunk == 1)
            return true;

        local isJunk = rndUtils.IsJunk(input);

        local junkOnlyM = rndUtils.HasMetaProp(output,"Object Randomiser - Junk Only");
        local noJunkM = rndUtils.HasMetaProp(output,"Object Randomiser - No Junk");
        local highPrioM = rndUtils.HasMetaProp(output,"Object Randomiser - High Priority Output");
        local secretM = rndUtils.HasMetaProp(output,"Object Randomiser - Secret");

        if (junkOnlyM && !isJunk)
            return false;

        //Deal with High Priority and Secret inputs
        if ((highPrioM || secretM) && !junkOnlyM && isJunk)
            return false;

        else if (noJunkM && isJunk)
            return false;

        return true;
    }

    static function LogCheck(input,output)
    {
        local noLogM = rndUtils.HasMetaProp(output,"Object Randomiser - No Logs");
        if (rndUtils.IsLog(input) && noLogM)
            return false;

        return true;
    }

    static function ContainerOnlyCheck(input,output)
    {
        if (rndUtils.HasMetaProp(output,"Object Randomiser - Output Self Only") && rndUtils.isArchetype(input,output))
            return true;

        if (rndUtils.HasMetaProp(input,"Object Randomiser - Container Only"))
            return rndUtils.isContainer(output);
        return true;
    }

    static function SameTypeCheck(input,output)
    {
        if (rndUtils.HasMetaProp(output,"Object Randomiser - Output Self Only"))
            return rndUtils.isContainer(output) || rndUtils.SameItemType(output,input);
        return true;
    }

    static function SecretCheck(output,RnoSecret)
    {
        local secretM = rndUtils.HasMetaProp(output,"Object Randomiser - Secret");
        if (secretM && RnoSecret)
            return false;
        return true;
    }

    static function CorpseCheck(output,RnoCorpse)
    {
        if (rndUtils.isCorpse(output) && RnoCorpse)
            return false;
        return true;
    }

    static function AllowOriginal(input,self,RallowOriginalLocations)
    {
        if (!RallowOriginalLocations && rndUtils.isArchetype(input,self))
            return false;
        return true;
    }

    function IsValid(input,randomiserSettings)
    {
        local RnoRespectJunk = randomiserSettings[0].tointeger();
        local RnoSecret = randomiserSettings[1].tointeger();
        local RnoCorpse = randomiserSettings[2].tointeger();
        local RallowOriginalLocations = randomiserSettings[3].tointeger();

        if (!Object.Exists(input) || IsPlaced() || !IsVerified())
            return 1;

        if (!CheckAllowedTypes(input))
            return 2;

        if (!SameTypeCheck(input,self))
            return 3;

        if (!ContainerOnlyCheck(input,self))
            return 4;

        if (!JunkCheck(input,self,RnoRespectJunk))
            return 5;

        if (!SecretCheck(self,RnoSecret))
            return 6;

        if (!CorpseCheck(self,RnoCorpse))
            return 7;

        if (!AllowOriginal(input,self,RallowOriginalLocations))
            return 8;

        if (!LogCheck(input,self))
            return 9;

        return 0;
    }

    function IsPlaced()
    {
        return GetData("placed") && !rndUtils.isContainer(self);
    }

    function IsVerified()
    {
        return GetData("verified") || rndUtils.isContainer(self) || rndUtils.isMarker(self);
    }

    function OnVerify()
    {
        SetData("verified",true);
    }

    //Called by Randomisers and returns if this was succesfully moved or not
    function OnRandomiseOutput()
    {
        local source = message().from;

        if (IsPlaced())
        {
            PostMessage(source,"OutputFailed",1);
            return;
        }

        local inputs = message().data;
        local config = message().data2;

        local inputArr = rndUtils.StrToIntArray(rndUtils.DeStringify(inputs));
        local configArr = rndUtils.StrToIntArray(rndUtils.DeStringify(config));

        PrintDebug("OnRandomiseOutput received from " + source + " contains: [" + inputs + ", " + config + "]",4);

        local valid = 0;
        foreach(input in inputArr)
        {
            valid = IsValid(input,configArr);
            if (valid == 0)
            {
                SetData("placed",true);
                PostMessage(source,"OutputSuccess",input,!container);
                PrintDebug("    found suitable input " + input + " from " + source,4);

                Place(input,self);
                return;
            }
            else
                PrintDebug("    input " + input + " was not valid (error code " + valid + ")",4);
        }
        PostMessage(source,"OutputFailed",valid);
    }

    function Place(input,output)
    {
        //This is a horrible dirty filthy hack to make objects not make any noise when being placed,
        //which would otherwise alert the AI and screw up premade patrol patterns and ambush setups.
        //It's removed by a timer that goes after 2 seconds.
        Property.Set(input, "Material Tags", "1: Tags", "Material None");
        outputItems.append(input);

        Container.Remove(input);
        if (rndUtils.isContainer(output))
        {
            PrintDebug("outputting " + input + " to container " + output + " <"+ ShockGame.SimTime() +">",2);
            PlaceInContainer(input,output);
        }
        else
        {
            PrintDebug("outputting " + input + " to location " + output + " <"+ ShockGame.SimTime() +">",2);
            PlacePhysical(input,output);
        }

        //Send a "Randomised" message to all objects targeting our input
        //This allows special behaviours to be implemented without modifying the scripts on our inputs
        foreach (ilink in Link.GetAll(linkkind("~Target"),input))
        {
            local targeted = sLink(ilink).dest;
            PostMessage(targeted,"Randomise",input);
        }

        SetFinishTimer();
    }

    function SetFinishTimer()
    {
        if (timerID)
            KillTimer(timerID);
        timerID = SetOneShotTimer("rndFinishTimer",REMOVE_TIMER);
    }

    function PlaceInContainer(input,output)
    {
        local position = GetData("position");
        local facing = GetData("facing");
        Object.Teleport(input, position, facing);
        Property.SetSimple(input, "HasRefs", FALSE);
        Link.Create(linkkind("Contains"),output,input);
        //Container.Add(input,output); //This will combine objects, which can then be moved elsewhere. We don't want this
    }

    function PlacePhysical(input,output)
    {
        local position = GetData("position");
        local facing = GetData("facing");
        local physicsControls = GetData("physicsControls");

        //Make object render
        Property.SetSimple(input, "HasRefs", TRUE);

        //If we are the same object, don't bother doing anything.
        //Just remain in place.
        if (input == output)
        {
        }
        //If we are the same archetype, "lock" into position and adopt physics controls
        else if (rndUtils.SameItemType(input,output))
        {
            Property.Set(input, "PhysControl", "Controls Active", physicsControls);
            Object.Teleport(input, position, facing);
        }
        //Different objects, need to "jiggle" the object to fix physics issues
        else
        {
            local height = GetJiggleHeight(input,output);
            position = vector(position.x, position.y, position.z + height);
            Object.Teleport(input, position, FixItemFacing(input,facing));

            //Fix up physics
            Property.Set(input, "PhysControl", "Controls Active", "");
            Physics.Activate(input);
            Physics.SetVelocity(input,vector(0,0,height + 5));
        }

        //Freeze objects
        if (rndUtils.HasMetaProp(output,"Object Randomiser - Freeze"))
        {
            Property.Set(input, "PhysControl", "Controls Active", PHYSCONTROL_LOC_ROT);
        }
    }

    function GetJiggleHeight(input,output)
    {
        if (rndUtils.HasMetaProp(output,"Object Randomiser - No Position Fix"))
            return 0;
        
        //local physType = Property.Get(input, "PhysType","Type");
        local physType = rndUtils.GetPropertyParent(input,"PhysType","Type");

        if (physType == 1) //Sphere
        {
            local radius = rndUtils.GetPropertyParent(input,"PhysDims","Radius 1");
            print (input + " radius: " + radius);
            return radius;
            //Physics.SetVelocity(input,vector(0,0,radius));
        }
        else
        {
            print (input + " has phystype of: " + physType);
            return 10;
        }

    }

    function OnTimer()
    {
        if (message().name == "rndFinishTimer")
        {
            PrintDebug("Output finished, removing...",3);
            foreach (item in outputItems)
                Property.Remove(item, "Material Tags");

            //clean up
            Object.RemoveMetaProperty(self,"Object Randomiser Output");
        }
    }

    //Items with these archetypes will have their X, Y and Z facing set to the specified value
    //DO NOT use the values from the editor, they are in hex, whereas this is in degrees.
    //So for instance, a pitch of 4000 will be equivalent to 90 degrees
    static fixArchetypes = [
        [-938,0,0,-1], //Cyber Modules
        [-85,0,0,-1], //Nanites
        [-1396,90,0,-1], //Ciggies
        [-5321,0,0,-1], //Worm Implants
        [-99,90,0,-1], //Implants
        [-91,0,-1,-1], //Cola
        [-51,-1,0,-1], //Hypos
        [-76,90,0,-1], //Audio Logs
        [-28,90,0,-1], //Crystal Shard
        //[-964,-1,-1,-1], //Vodka
    ];

    function FixItemFacing(item,facing)
    {
        foreach (archetype in fixArchetypes)
        {
            local type = archetype[0];
            if (rndUtils.isArchetype(item,type))
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
}

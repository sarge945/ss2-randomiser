//This randomiser takes a series of outputs,
//but not inputs,
//and will instead replace each output based on
//a randomly chosen input
class rndReplacerRandomiser extends rndBaseRandomiser
{
    rolls = null;
    totalOutputs = null;
    replaceObjects = null;

    function Init(reloaded)
    {
        base.Init(reloaded);

        replaceObjects = getParamArray("replacementTypes",allowedTypes);

        foreach (olink in Link.GetAll(linkkind("~Target"),self))
        {
            local out = sLink(olink).dest;
            if (CheckAllowedTypes(out))
                outputs.append(out);
        }

        //Shuffle Array
        outputs = rndUtils.Shuffle(outputs,seed);

        ShowWelcomeMessage("Replacer");

        //We have to set a timer, or Object.BeginCreate breaks everything
        SetOneShotTimer("StartTimer",0.01);

        rolls = 0;
        totalOutputs = outputs.len();
    }

    function GetReplaceObject(output)
    {
        local total = replaceObjects.len() - 1;
        local obj = rndUtils.RandBetween(seed + output,0,total);
        return replaceObjects[obj];
    }

    function OnTimer()
    {
        Randomise();
    }

    function Randomise()
    {
        if (outputs.len() == 0)
        {
            Complete("Replacer");
            return;
        }

        local output = outputs[0];

        CreateNewObject(output);

        rolls++;
        outputs.remove(0);
        Randomise();
    }

    function CreateNewObject(output)
    {
        local replacement = GetReplaceObject(output);
        if (rndUtils.isArchetypeExact(output,replacement))
        {
            PrintDebug("Not replacing " + output + ", same archetype",1);
            return;
        }
        local name = Object.GetName(output);
        local newObject = Object.BeginCreate(replacement);
        PrintDebug("created object (" + ShockGame.GetArchetypeName(newObject) + ") " + newObject,1);

        Object.Teleport(newObject,Object.Position(output),Object.Facing(output));

        copyLinks(output,newObject,"SwitchLink");
        copyLinks(output,newObject,"~SwitchLink");
        copyLinks(output,newObject,"Target");
        copyLinks(output,newObject,"~Target");
        
        Object.EndCreate(newObject);

        Place(output,newObject);

        PrintDebug("Replacing " + output + " (" + ShockGame.GetArchetypeName(output) + ") with " + newObject + " (" + ShockGame.GetArchetypeName(newObject) + ")",1);

        Object.Destroy(output);

        Object.SetName(newObject,name);
    }

    function Place(output,newObject)
    {
        //Set model, since some eggs have a different model,
        //and we want things to look exactly the same
        local model = Property.Get(output, "ModelName");
        Property.SetSimple(newObject, "ModelName", model);
        
        local name = Object.GetName(output);
        Object.SetName(newObject,name);

        local tweqModel = Property.Get(output, "CfgTweqModels","Model 0");
        Property.Set(newObject, "CfgTweqModels", "Model 0", tweqModel);
    }
}

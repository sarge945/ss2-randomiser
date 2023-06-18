//A complex randomiser
//This supports Object Pools, allowed types, and other features to make
//handling groups of objects much easier
class rndComplexRandomiser extends rndBaseRandomiser
{
    //Configuration
    minTimes = null;
    maxTimes = null;
    allowOriginalLocations = null;
    priority = null;
    failures = null;

    //State
    totalRolls = null;
    totalItems = null;
    inputs = null;

    //state
    outputLoop = null;

    //Settings
    fuzzy = null;
    ignorePriority = null;
    noRespectJunk = null;
    noSecret = null;
    noCorpse = null;
    noHighPriority = null;
    timerID = null;
    noItemOutputs = null;

    function Init(reloaded)
    {
        base.Init(reloaded);
        priority = getParam("priority",0);

        if (!reloaded)
        {
            //Set timer
            local startTime = GetStartTime();
            SetData("StartTime",startTime);
            SetOneShotTimer("StartTimer",startTime);
        }

        //Populate configuration
        fuzzy = getParam("variedOutput",1);
        ignorePriority = getParam("ignorePriority",0);
        noSecret = getParam("noSecret",0);
        noCorpse = getParam("noCorpse",0);
        noRespectJunk = getParam("noRespectJunk",0);
        noHighPriority = getParam("noHighPriority",0);
        noItemOutputs = getParam("noItemOutputs",0);
        maxTimes = getParam("maxTimes",9999);
        minTimes = getParam("minTimes",9999);
        allowOriginalLocations = getParam("allowOriginalLocations",1);

        //Setup
        totalRolls = rndUtils.RandBetween(seed,minTimes,maxTimes);
        failures = 0;
    }

    function GetCollection()
    {
        return rndObjectCollection(self);
    }

    function Setup()
    {
        local collection = GetCollection();

        local potentialInputs = rndUtils.DeDuplicateArray(collection.inputs);
        local potentialOutputs = rndUtils.DeDuplicateArray(rndUtils.Combine(collection.lowOutputs,collection.highOutputs));
        
        inputs = [];
        outputs = [];

        foreach (pi in potentialInputs)
        {
            if (IsInputValid(pi))
            {
                inputs.append(pi);
                PostMessage(pi,"Verify");
            }
        }
        
        foreach (po in potentialOutputs)
        {
            if (IsOutputValid(po))
                outputs.append(po);
        }

        //Show startup message
        ShowWelcomeMessage("Complex");

        //Setup variables
        outputLoop = 0;

        if (inputs.len() == 0 || outputs.len() == 0)
        {
            PrintDebug("Randomiser won't function! [inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]");
            return;
        }

        totalItems = inputs.len();

        PrintDebug("[inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]",4);

        if (inputs.len() > 0 && outputs.len() > 0)
        {
            ShuffleBothArrays();
            Randomise();
        }
    }

    function ShowWelcomeMessage(randomiserType)
    {
        PrintDebug(randomiserType + " Randomiser Started. [seed: " + seed + ", startTime: " + GetData("StartTime") + ", inputs: " + inputs.len() + ", outputs: " + outputs.len() + "]");
    }

    function GetStartTime()
    {
        //return 0.25 + (seed % 1000 * 0.0001);
        return 0.01;
    }

    function OnOutputSuccess()
    {
        local output = message().from;
        local input = message().data;
        local pos = inputs.find(input);

        if (inputs.len() == 0 || outputs.len() == 0 || pos == null)
            return;

        //print("OnOutputSuccess received");
        rolls++;

        //print("output successful");
        PrintDebug("    Output Successful for " + input + " to " + output,4);

        RemoveInput(input);
        ReplaceOutput(output);
        Randomise();
    }

    function OnOutputFailed()
    {
        local output = message().from;
        local pos = outputs.find(output);

        if (inputs.len() == 0 || outputs.len() == 0 || pos == null)
            return;

        failures++;

        //print("OnOutputFailed received");
        PrintDebug("    Output Failed for output " + output,4);

        outputs.remove(pos);
        Randomise();
        //ReplaceOutput(output,true);
    }

    function Randomise(outputDebugText = true)
    {
        if (inputs.len() == 0 || outputs.len() == 0)
        {
            Complete("Complex");
            return;
        }

        if (rolls >= totalRolls || rolls > totalItems)
        {
            PrintDebug("Rolls exceeded",5);
            return;
        }

        local output = outputs[0];

        PrintDebug("Randomising inputs to " + output + " (roll: " + rolls + "/" + totalRolls + ")",4);

        local inputString = rndUtils.Stringify(inputs);

        PrintDebug("    Sending RandomiseOutput to randomise " + inputString + " at " + output,4);
        PostMessage(output,"RandomiseOutput",inputString,GetSettingsString(),rolls);
        if (timerID != null)
            KillTimer(timerID);
        timerID = SetOneShotTimer("RandomiseTimer",0.01);
    }

    function OnTimer()
    {
        if (message().name == "StartTimer")
        {
            Setup();
        }
        else if (message().name == "RandomiseTimer")
        {
            //we're stuck!
            PrintDebug("contingency timer activated...",4);
            ShowDebug("contingency timer activated...",4);
            outputs.remove(0);
            Randomise();
        }
    }

    function RemoveInput(input)
    {
        local index = inputs.find(input);

        if (index != null)
            inputs.remove(index);
    }

    function GetSettingsString()
    {
        return noRespectJunk + ";" + noSecret + ";" + noCorpse + ";" + allowOriginalLocations + ";";
    }

    function ShuffleBothArrays()
    {
        inputs = rndUtils.Shuffle(inputs,seed);

        //If we are set to have high-priority outputs, then we are going to need
        //to split the outputs array, then shuffle each, then recombine them,
        //with the high priority ones at the start
        if (ignorePriority)
        {
            outputs = rndUtils.Shuffle(outputs,-seed);
        }
        else
        {
            local lowPrio = rndUtils.FilterByMetaprop(outputs,"Object Randomiser - High Priority Output",true);
            local highPrio = rndUtils.FilterByMetaprop(outputs,"Object Randomiser - High Priority Output");

            lowPrio = rndUtils.Shuffle(lowPrio,-seed);
            highPrio = rndUtils.Shuffle(highPrio,-seed);

            if (noHighPriority)
                outputs = lowPrio;
            else
                outputs = rndUtils.Combine(highPrio,lowPrio);
        }
    }

    //Move an input to the end after it's used
    //Allow items to "bubble" where a container will
    //possibly contain more than one, or nothing,
    //since they are reinserted from the bubble index to the end,
    //rather than always at the end
    function ReplaceOutput(output,forceEnd = false)
    {
        local pos = outputs.find(output);
        
        if (pos == null)
            return;
        
        if (fuzzy && !forceEnd)
        {
            local min = outputs.len() * 0.35;
            local max = outputs.len() - 1;

            local insertIndex = rndUtils.RandBetween(seed + output,min,max);
            outputs.remove(pos);
            outputs.insert(insertIndex,output);
        }
        else
        {
            outputs.remove(pos);
            outputs.append(output);
        }
    }

    function IsInputValid(input)
    {
        //Check allowed types
        if (!CheckAllowedTypes(input))
            return false;

        if (noCorpse)
        {
            local containerLink = Link.GetOne(linkkind("~Contains"),input);
            if (containerLink)
            {
                local container = sLink(containerLink).dest;
                if (rndUtils.isCorpse(container))
                {
                    PrintDebug("Container: " + container);
                    return false;
                }

            }
        }

        return true;
    }

    function IsOutputValid(output)
    {
        if (!rndUtils.isMarker(output) && !rndUtils.isContainer(output) && noItemOutputs)
            return false;

        return true;
    }

}

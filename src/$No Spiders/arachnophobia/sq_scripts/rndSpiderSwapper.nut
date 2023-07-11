//Very simple class, it just replaces whatever it's attached to with a worm
class rndSpiderSwapper extends rndBase
{
    function OnBeginScript()
    {
        //Give the randomiser time to swap this object out
        SetOneShotTimer("rndSwapTimer",0.1);
    }

    //If we're a baby spider, get a grub, otherwise, a blue monkey
    function GetReplacement()
    {
        if (Object.Archetype(self) == -2014)
            return -182; //grub
        //return -1431; //Blue Monkey
        return -1432; //Red Monkey
    }

    function OnTimer()
    {
        if (message().name == "rndSwapTimer")
        {
            local replacement = GetReplacement();
            local newObject = Object.BeginCreate(replacement);
            Object.Teleport(newObject,Object.Position(self),Object.Facing(self));

            copyLinks(self,newObject,"SwitchLink");
            copyLinks(self,newObject,"~SwitchLink");
            copyLinks(self,newObject,"Target");
            copyLinks(self,newObject,"~Target");
            
            rndUtils.CopyProperties(self,newObject);
            
            Object.EndCreate(newObject);

            Object.Destroy(self);
        }
    }
}

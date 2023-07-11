class rndCardScript extends SqRootScript
{
    function OnFrobWorldEnd()
    {
        //print ("touch card");
        foreach (cardLink in Link.GetAll(linkkind("SwitchLink"),self))
        {
            local dest = sLink(cardLink).dest;
            PostMessage(dest,"Unlocked");
        }
    }
}

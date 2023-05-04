Introduction
============

This mod is very complex, and was created specifically to allow very advanced randomisation. As a result of this complexity, it is also complicated to work with. This document will overview the basic steps for creating a randomiser, as well as exploring concepts like object collections, markers, and advanced randomiser usage.

This guide assumes a basic knowledge of DML modding. No squirrel knowledge is required.

Object Collections
==================

Object collections define the objects, corpses and containers which a randomiser can work with. Randomisers may specify multiple object collections as both inputs (to determine which objects to randomise) and outputs (to determine where they can be randomised to).

While it's possible to simply use 1 object collection for an entire map, for balance reasons, this is not recommended. Instead, object collections should be created for each area of the map, to allow more fine-grained control over randomisation.

For example, for the first medsci map, separate object collections were created for the science sector and the R&D sector. This was done because the player doesn't enter R&D until much later than the science sector, and it will become clear in the next section why this is important.

Object Collections can be created through DML, using the example below:

````
//Create an object collection for the Science Sector
Create "rndObjectCollection" "rndScienceObjects"
{
}
````

Once created, objects can then be linked to the object collection using Target links.

````
//Small security room desk
+Link 258 "rndScienceObjects" "Target"
{
}
````

Note: Randomisers automatically include any items found in any containers and corpses within an object collection, so there's no need to explicitly add contained items to an object collection. To stop an item being added automatically, use the "Object Randomiser - No Auto Input" metaproperty. For example:

````
//Stop the French-Epstein device from being randomised because it's a reward for completing the area
+MetaProp 220 "Object Randomiser - No Auto Input"
````

Note: While not strictly enforced, it's recommended to only ever add items and containers to one object collection, for the sake of organisation. Filtering should be done by specifying input and output collections on Randomisers, not by adding items to many collections. Randomisation should still work correctly, but it will result in a lot of extra unnecessary confusion and very messy DML.

Creating Randomisers
====================

Randomisers have Object Collections as inputs and outputs. Inputs should be linked to Randomisers using SwitchLinks, and Outputs should be linked to Randomisers using ~SwitchLinks. Inputs determine which items can be randomised, while Outputs determine the locations and containers at which those items can be placed.

Here is an example DML snippet that shows a basic randomiser:

````
//Create a randomiser for MedSci1
//Science and R&D Items can be mixed together
Create "rndComplexRandomiser" "rndMedSci1Randomiser"
{
}

//Inputs
+Link "rndScienceObjects" "rndMedSci1Randomiser" "SwitchLink"
{
}

+Link "rndRNDObjects" "rndMedSci1Randomiser" "SwitchLink"
{
}

//Outputs
+Link "rndScienceObjects" "rndMedSci1Randomiser" "~SwitchLink"
{
}
+Link "rndRNDObjects" "rndMedSci1Randomiser" "~SwitchLink"
{
}
````

Once this is created, all the items within the Science and R&D sectors of medsci1 should be automatically randomised upon starting the game, except for weapons and armor, and key items such as power cells.

Randomising the Power Cell
==========================

By default, randomisers don't randomise key items, in order to prevent impossible outcomes for the player.

In order to randomise the power cell, we want to create another randomiser:

````
//Create a randomiser for the Science Sector Power Cell
Create "rndComplexRandomiser" "rndSciencePowercellRandomiser"
{
	+ObjProp "DesignNoteSS" = "allowedTypes0=-1862; ignorePriority=1; noSecret=1;"
}

//Link the Science Items to it as Input
+Link "rndScienceObjects" "rndSciencePowercellRandomiser" "SwitchLink"
{
}

//Link the Science Items to it as Output
+Link "rndScienceObjects" "rndSciencePowercellRandomiser" "~SwitchLink"
{
}
````

By specifying the type (using allowedTypes0), we can specify any archetype by number. -1862 is the archetype for Power Cells. Note that we have specified only the science sector for this Randomiser, this is to ensure the power cell is always available in the science sector, otherwise the player wouldn't be able to enter Medical.

This example illustrates the importance of using multiple object collections and splitting maps up by area - by doing so, we can randomise subsets of items easily without having to constantly redefine which items we wish to work with.

Note: Additional archetypes can be specified using allowedTypes1, allowedTypes2, etc.

Note: ignorePriority=1 and noSecret=1 will be explained in a later section.

Note: the archetype for keycards is -156. Randomisers for keycards are specified exactly the same way as for power cells, but with their allowed type set to -156 instead.

Randomising Weapons and Armour
==============================

Weapons and Armour work exactly the same way as Power Cells, and it's recommended for balance reasons that they are also kept within their associated areas, otherwise the player may be unfairly screwed (for example if all the pistols in medsci1 all appear in R&D, leaving them ill-equipped for medical) or unfairly favoured (for example if the shotgun from R&D randomises into the Science sector, allowing the player to get it early).

Here's an example of weapon randomisers for medsci1 that ensure the player can only get the weapons appearing in their area.

````
//Create a randomiser for the Science Sector Weapons
Create "rndComplexRandomiser" "rndScienceWeaponRandomiser"
{
	+ObjProp "DesignNoteSS" = "allowedTypes0=-12; ignorePriority=1; noSecret=1;"
}

//Link the Science Items to it as Input
+Link "rndScienceObjects" "rndScienceWeaponRandomiser" "SwitchLink"
{
}

//Link the Science Items to it as Output
+Link "rndScienceObjects" "rndScienceWeaponRandomiser" "~SwitchLink"
{
}

//Create a randomiser for the R and D Weapons
Create "rndComplexRandomiser" "rndRandDWeaponRandomiser"
{
	+ObjProp "DesignNoteSS" = "allowedTypes0=-12; ignorePriority=1; noSecret=1;"
}

//Inputs
+Link "rndRNDObjects" "rndRandDWeaponRandomiser" "SwitchLink"
{
}

//Outputs
+Link "rndRNDObjects" "rndRandDWeaponRandomiser" "~SwitchLink"
{
}
````

Note: Additional archetypes can be specified using allowedTypes1, allowedTypes2, etc.

Note: ignorePriority=1 and noSecret=1 will be explained in a later section.

Note: The archetype for Armour is -78, and can be added to the existing weapon randomisers with allowedTypes1=-78

Limiting Randomisation
======================

By default, randomisers will randomise every single input in each object collection they are linked to. Sometimes, this may be undesired. Randomisation can be limited by specifying maxTimes and minTimes. When determining what to do, the randomiser will only move up to the maxTimes number of items, and will never move less than the minTimes number of items.

This can be used to add a small number of items from one location into another.

This example shows how we can add up to 2 random items from the Science Sector into the Cryo sector of medsci1, which gives variety without being too unbalanced:

````
//Shuffle up to 2 objects from Science sector into Cryo, for variety
Create "rndComplexRandomiser" "rndCryoExtraRandomiser"
{
	+ObjProp "DesignNoteSS" = "maxTimes=2; minTimes=0"
}

//Inputs
+Link "rndScienceObjects" "rndCryoExtraRandomiser" "SwitchLink"
{
}

//Outputs
+Link "rndCryoObjects" "rndCryoExtraRandomiser" "~SwitchLink"
{
}
````

Note: If minTimes is not specified, a randomiser will always randomise the maxTimes number of items.

Randomising the Same Data Set
=============================

Sometimes, it's important to run multiple randomisers on the same set of inputs or outputs. A common example where this is used is body bags - they can contain any hypo from anywhere in the map, but hypos themselves can also be randomised to be anywhere else on the map as well.

This presents a problem. Randomisers run in a nondeterministic order. This means that randomisers which run on the same data sets can "steal" each others items.

Here's an example:

What if you want between 2 and 4 hypos from the Science or R&D sectors to be randomised into body bags in the morgue. Any other hypos (including the ones that normally always appear in body bags) should be able to appear anywhere else on the map.

This can be done like this:

````
//Create a randomiser for the Body Bags (only allow hypos)
Create "rndComplexRandomiser" "rndBodybagRandomiser"
{
	+ObjProp "DesignNoteSS" = "allowedTypes0=-51; maxTimes=4; minTimes=2"
}
//Inputs
+Link "rndScienceObjects" "rndBodybagRandomiser" "SwitchLink"
{
}
+Link "rndRNDObjects" "rndBodybagRandomiser" "SwitchLink"
{
}
+Link "rndBodybags" "rndBodybagRandomiser" "SwitchLink"
{
}
//Outputs
+Link "rndBodybags" "rndBodybagRandomiser" "~SwitchLink"
{
}
````

However, this presents a problem. If the Bodybag Randomiser runs before the Science randomiser, all of it's hypos will be "stolen", resulting in empty body bags.

This can be circumvented by adding a priority. By default, all randomisers have a priority of 0.

Priority forces a randomiser to execute after all other randomisers of lower priority. By adding priority=1 to the DML, we can ensure the body bag randomiser always runs after the Science and R&D randomiser, which means hypos from around the map will be randomised into bodybags, and won't be randomised again to appear elsewhere.

For example:

````
//Create a randomiser for the Body Bags (only allow hypos)
Create "rndComplexRandomiser" "rndBodybagRandomiser"
{
	+ObjProp "DesignNoteSS" = "allowedTypes0=-51; maxTimes=4; minTimes=2; priority=1"
}
//Inputs
+Link "rndScienceObjects" "rndBodybagRandomiser" "SwitchLink"
{
}
+Link "rndRNDObjects" "rndBodybagRandomiser" "SwitchLink"
{
}
+Link "rndBodybags" "rndBodybagRandomiser" "SwitchLink"
{
}
//Outputs
+Link "rndBodybags" "rndBodybagRandomiser" "~SwitchLink"
{
}
````

Note: Priority should generally be kept below 3-4. Each level of priority adds 0.2 seconds to the start delay for a randomiser, and after ~1 second, it's possible to notice the results in-game.

Using Markers
=============

Often it's important to allow items to appear in locations which previously did not contain any item, rather than simply swapping items around or adding them to containers.

In order to do this, Markers should be created and linked to object collections, in much the same way as items are.

Here's an example of a marker:

````
//Bench in small area with trashcan and observation window to Watts lab
Create "rndOutputMarker" "rndObservationRoom"
{
	+ObjProp "Position"
	{
		"Location" "36.5863, 45.1214, -13.0845"
		"Heading" 4234
		"Pitch" 0
		"Bank" 0
	}
}
+MetaProp "rndObservationRoom" "Object Randomiser - No Junk"
+Link "rndObservationRoom" "rndScienceObjects" "Target"
{
}
````

This will now allow items to appear randomly at that location.

Note: The "Object Randomiser - No Junk" metaproperty will be explained in a later section.

Note: Adding a large number of markers will likely bias the way randomisation works, especially if markers are placed unevenly. If a room which previously contained only 1 item is given 10 markers, this may present a balance issue, as now 10 items may randomise into that room. This creates a situation where a lot of items are concentrated in one area, which may leave other areas barren and may unfairly reduce or increase the challenge and exploration aspects of the game. The solution is to use Linked Markers, explained below.

Linked Markers
==============

By default, all Markers count as outputs. This means that an item can appear at each marker at an equal chance. Having a lot of markers is good for adding a lot of variety to a map, but may cause other issues. For example, adding 20 markers in the recharger room in the Science sector of medsci1 will allow a lot of dynamic item placements, and very interesting and varied item positions, which is desired. However this also presents a problem whereby a significant number of items may randomise into that room, leaving many other areas of the map empty.

In order to address this, Markers can be SwitchLinked to objects (or other markers) instead of Target linked to an object collection. When doing this, the markers will be linked, and will only be able to output as many items as there are outputs.

For instance, in Medical, there is a small ledge near Primate Research containing some nanites. It would be good to allow any object to appear in multiple places along that ledge, but having multiple objects appear at the same time would be undesirable.

To remedy this, instead of linking the markers to the object collection, they should be linked to the nanites instead. Now, whenever an item randomises to the nanites location, it will randomly choose any spot along the ledge

````
//Nanites near Primate Research
+Link 1221 "rndMedicalObjects" "Target"
{
}

//Create a marker at the end of the little ledge above Primate Research
Create "rndOutputMarker" "rnd_marker_43"
{
    +ObjProp "Position"
    {
        "Location" "-89.34, -229.92, -1.98"
        "Heading" 6186
        "Pitch" 0
        "Bank" 0
    }
}
+Link "rnd_marker_43" 1221 "SwitchLink"
{
}
````

Note: This should be used to create a large number of markers within a room without having the room be overfilled with items.

Note: Markers can be linked to multiple outputs, which will allow even more variety as more items will be able to share the locations.

Randomiser Features
===================

Randomisers support a number of features, which can be configured using the Design Note property via DML.

Here's an example of a configured randomiser:


````
Create "rndComplexRandomiser" "rndExampleRandomiser"
{
	+ObjProp "DesignNoteSS" = "allowedTypes0=-12; priority=1; variedOutput=0; maxTimes=2; minTimes=0"
}
````

Features List
-------------

allowedTypes

allowedTypes is an array, and must be followed by a number (such as allowedTypes0, allowedTypes1 etc).
By specifying a series of allowed types, a randomiser can be configured to only randomise inputs which are of a certain archetype.
In this case, only weapons (-12) will be randomised.

This allows a subset of items to be randomised without having to manually add them to a new object collection,
and containers which contain multiple types of objects will only have the relevant items affected.

priority

By default, all randomisers have a priority of 0. By specifying a higher number, a randomiser can raise it's priority.
This is useful when multiple randomisers are working on the same objects.

For example, in MedSci1, a number of body bags are randomised, and can only contain hypos. These hypos are pulled from all the items in the map.
At the same time, a randomiser exists to allow all the items in the map to be randomised.
If they both run at the same priority, the map randomiser can "steal" items from the bodybags, meaning they will most likely be empty.
By configuring the body bag randomiser to have a priority higher than the general map randomiser, hypos can be "stolen" from around the map and placed in body bags,
but not the other way around.

variedOutput

By default, randomisers will fill outputs by giving them a chance to
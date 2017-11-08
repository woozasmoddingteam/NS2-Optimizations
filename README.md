#About
This mod just improves performance in NS2 (a game).

#Configuration
Both the client and the server will have a file called either NS2OptiServer.json
or NS2OptiClient.json in the NS2 configuration directory. It has various self-explanatory
options, which you might want to tinker with.

#Optimizations

##Closure optimizations
Lots of code that allocated closures now use a table trick.
Very compatible with other mods.

##Fast mixin
This makes mixin initialisation a lot faster, *though* it depends
on the fact, that most code only does **static** initialisation
of mixins, i.e. the mixins initialised does **not** change from entity
to entity of the same class.

Violating this inside either OnCreate or OnInitialized will have **fatal** effects.
Outside of these two methods, you have free reign, but it **will** have a performance impact.

Obviously this will have problems with some mods.

##GUI rework
This is a complete rewrite of the GUIManager class and eventually also
of the entire minimap system. However, the minimap system has not been worked on
in some time due to my laziness.
The GUIManager code is completely active though.

The GUIManager part is purely a client-side optimisation.

This can have problems with some mods due to some assumptions it makes about GUI code,
so be aware of misfunctioning code.
If you are aware of any such mod, please do contact me, so that I may add an exception for
this particular mod.

##Smart relevancy
NS2's netcode is obviously not very good (it's rather awful), and events such
as beacons will cause lag, due to many entities becoming relevant to many clients all
at once.
What this optimisation does, is to *smooth* the transition, thus making the same number
of entities relevant over a large amount of time.

Additionally, a special configuration key is available, which makes **all** player entities
relevant to **all** clients **all** the time. This does not seem like a good idea, but often
you may find NS2 counter-intuitive.

This is quite compatible with other mods, just like the closure optimisations, so you
should have few worries.

##Tech
This change just optimises tech data look-ups. A tech data look-up could e.g. be
checking the health of a particular technology, such as a hive.
It could be the amount of armor, whether it needs infestation, or if it needs
to be attached to something to properly function.
The way these are implemented in vanilla is **not** optimal. This seeks to fix that.

Although this change may seem rather fundamental, it is still **very** compatible with
other mods.

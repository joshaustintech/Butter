# Butter

A simple, private recipe keeper for iPhone. Each person's recipes live only in their own iCloud.

## Language

**Recipe**:
A saved dish: a title, its Ingredients, its ordered Steps, an optional photo, an optional Source, and the dates it was saved and last updated.
_Avoid_: Card, entry, item

**Ingredient**:
One line of what a Recipe needs (e.g. "2 chicken thighs"), kept as the text the person wrote, with no separate quantity or unit.
_Avoid_: Item, component

**Step**:
One ordered instruction in a Recipe's method.
_Avoid_: Direction, instruction, stage

**Source**:
Where a Recipe came from: a webpage, or a photographed page. A Recipe typed in by hand has no Source.
_Avoid_: Origin, link

**Cooking session**:
A hands-free stretch of time spent following one Recipe Step by Step, from starting to cook until stopping or finishing the last Step. An interruption (backgrounding, a phone call) pauses it and keeps the current Step; it is never kept across an app relaunch.
_Avoid_: Cook mode, cooking view, walkthrough

**Cooking command**:
A spoken instruction heard during a Cooking session, such as moving to the next Step or stopping.
_Avoid_: Voice command, utterance

**Saved date**:
When the Recipe was first added to Butter.
_Avoid_: Created date, added date

**Updated date**:
When the Recipe was last changed.
_Avoid_: Modified date, edited date

**Duplicate**:
An imported Recipe whose Source is a webpage already saved as a Recipe. Butter doesn't save it again; it tells the person the Recipe is already saved and opens the existing one. A photographed page is never a Duplicate. If two devices each save the same webpage before syncing, Butter later keeps the older Recipe and quietly removes the newer one, unless the newer one has been edited.
_Avoid_: Copy, repeat

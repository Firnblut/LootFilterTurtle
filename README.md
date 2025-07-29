# LootFilterTurtle
LootFilter for Turtle-WoW

This Addon is for Turtle WoW, written for Game-Version 1.12 in LUA 5.0

It adds several enhancements in bag management. The following features are currently enabled:

1. Displays vendor value on all items in your bags (does not display vendor value of items in quest dialogues, trade windows, etc)
2. Displays maximum stack size on all items in your bags (see above)
3. Deletes all grey items you loot
4. Deletes all items on your custom list when you loot them
5. Vendor value threshold: Only deletes items (3+4) if their value is below a certain vendor value threshold (vendor value in this step is determined by maximum stack size times unit vendor price)
6. Sells all grey and listed items as soon you talk to a vendor

Commands:
/lfo            Opens Lootfilter UI. Add items by shift+clicking on them in your inventory or add them manually by entering their name into the list. Enter the loot threshold. Use save-button to save changes.
/lf notify      Toggles delete/keep notifications with reasons (quality, list, price)
/lf all         Checks all items currently in your bag and keeps/deletes the according to your setting (respecting vendor value threshold)
/lf debug       Toggles debug messages in case you want to modify the addon

Unknown items: This database doesn't include items without vendor value (which are questitems most of the time) and doesn't include custom turtle-wow items. If you come upon an unknown item, it's itemID and name will be saved in savedVariables\lootfilter112.lua and you can use the entry to add it to database.lua. Just look up the price and maximum stacksize in turtle-wow's database and add it to database lua as: [itemID]="price,maxstack"

Installation: As with all addons, download the zip-file (green "< > Data"-Button), extract all to lootfilter112 and put this folger into your interface\addons folder in your WoW directory.


This addon is not currently in development. There will be no more features, bugfixing, etc. Use at your own risk.

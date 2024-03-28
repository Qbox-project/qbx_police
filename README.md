# qbx_policejob
Police Job for QBOX :police_officer:

## Dependencies
- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [qbx_management](https://github.com/Qbox-project/qbx_management) - For the boss menu
- [qbx_garages](https://github.com/Qbox-project/qbx_garages) - For the vehicle spawner
- [qbx_clothing](https://github.com/Qbox-project/qbx_clothing) - For the locker room
- [qbx_phone](https://github.com/Qbox-project/qbx_phone) - For the MEOS app and notifications etc.
- [qbx_smallresources](https://github.com/Qbox-project/qbx_smallresources) - For logging certain events
- [ox_lib](https://github.com/overextended/ox_lib) - For UI elements and cached data

## Screenshots
*We need new ones*

## Features
- Classical requirements like on duty/off duty, clothing, vehicle, stash etc.
- Citizen ID based armory (Whitelisted)
- Fingerprint test
- Evidence locker (stash)
- Whitelisted vehicles
- Speed radars across the map
- Stormram
- Impounding player vehicle (permanent / for an amount of money)
- Integrated jail system
- Bullet casings
- GSR
- Blood drop
- Evidence bag & Money bag
- Police radar
- Handcuff as an item (Can used via command too. Check Commands section.)
- Emergency services can see each other on map

### Commands
- /spikestrip - Places spike strip on ground.
- /grantlicense - Give access to a license for a user.
- /revokelicense - Revoke access to a license for a user.
- /pobject [cone/barrier/roadsign/tent/light/delete] - Places or deletes an object on/from ground.
- /cuff - Cuffs/Uncuffs nearby player
- /escort - Escorts nearby plyer.
- /callsign [text] - Sets the player a callsign on database.
- /clearcasings - Clears nearby bullet casings.
- /jail [id] [time] - Sends a player to the jail.
- /unjail [id] - Takes the player out of jail.
- /clearblood - Clears nearby blood drops.
- /seizecash - Seizes nearby player's cash. (Puts in money bag)
- /sc - Puts soft cuff on nearby player.
- /cam [cam] - Shows the selected security cam display.
- /flagplate [plate] [reason] - Flags the vehicle.
- /unflagplate [plate] - Removes the flag of a vehicle.
- /plateinfo [plate] - Displays if a vehicle is marked or not.
- /depot [price] - Depots nearby vehicle. Player can take it after paying the cost.
- /impound - Impounds nearby vehicle permanently.
- /paytow [id] - Makes payment to the tow driver.
- /paylawyer [id] - Makes payment to the lawyer.
- /takedna [id] - Takes a DNA sample from the player.
- /911p [message] - Sends a report to the police.

## Installation
### Manual
- Download the script and put it in the `[qbx]` directory.
- Add the following code to your server.cfg/resouces.cfg

```
ensure qbx_core
ensure qbx_policejob
```

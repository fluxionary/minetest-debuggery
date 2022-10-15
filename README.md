# debuggery

minetest mod w/ some useful debugging utilities

dependencies:
* futil https://github.com/fluxionary/minetest-futil

# commands

* `attach <target1> to <target2>`
  attaches two objects, which might be a player name or an entity name (a random entity of that type is chosen)
* `detach <target>`
  detaches the target from its parent.
* `count_objects`
  prints counts of all types of objects currently active.
  example output:
  ```
  petz:calf = 5
  petz:frog = 1
  petz:goat = 2
  petz:lamb = 3
  petz:panda = 1
  petz:pony = 2
  petz:rat = 4
  petz total = 18
  ..............
  total = 18
  ```
* `entity_lag_log_toggle`
  starts (or stops) a log of how much time entities are spending doing their `on_step` callback.
  example output:
  ```
  2022-09-03 16:03:51: petz:foxy @ (-2833,71,2327)'s on_step took 424138 us
  2022-09-03 16:03:51: petz:leopard @ (-297,48,854)'s on_step took 371364 us
  2022-09-03 16:03:52: petz:snow_leopard @ (-2811,74,2283)'s on_step took 377283 us
  ```
* `/grep_nodes <limit> <pattern>`
  requires *either* worldedit or areas mod. allows you to search for nodes whose name matches `<pattern>` between
  either areas positions (`area_pos1`, `area_pos2`) or worldedit positions (`/1`, `/2`). searching a large area is
  broken up into discrete steps, so as not to cause a single huge lag spike. locations of nodes will be sent to
  the player who executed the command in in-game chat
  ```
  //grep_nodes 5 pipeworks
  broke job into 1 chunks, took 0.009692s
  pipeworks:nodebreaker_off @ (-538,23,-274)
  pipeworks:deployer_off @ (-535,23,-274)
  ```
* `instrument_mod <global_name>`
  recursively finds all functions inside a lua table available as `<global_name>`, and records information about how
  often they are executed, and how long they take to run. most mods use their own name as the global value.
  run the command again to turn the logging off. example output:
  ```
  22:04:06: in 4.4160022735596s,
  22:04:06: kitz.actfunc was called 9 times, used 224 us
  22:04:06: kitz.animate was called 17 times, used 45 us
  22:04:06: kitz.clear_queue_low was called 2 times, used 0 us
  22:04:06: kitz.exists was called 4977398 times, used 1192386 us
  22:04:06: kitz.get_box_height was called 66 times, used 642 us
  22:04:06: kitz.get_closest_entity was called 21 times, used 4062036 us
  ```
* `memory`
  get lua's current memory usage (doesn't include memory managed by the c++ parts of the engine)
* `memory_toggle`
  reports on the server's memory usage periodically.
* `rectify`
  sets pitch and yaw to (0, 0)
* `remove_entities <entity_name>`
  remove all currently active entities w/ the given name
* `whatisthis`
  get the full itemstring of wielded item
* `/rollback_check [<seconds>] [<limit_per_node>] [<player>]`
  * note the initial slash - this does not override the builtin rollback command
  * requires the same privilege(s) as `rollback_check`, or `{rollback=true}` if that doesn't exist
  checks a region defined via worldedit (`/1`, `/2`) or areas (`area_pos1`, `area_pos2`)

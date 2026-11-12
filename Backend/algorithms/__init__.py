"""
Pure-Python algorithm modules for ResQ.

These modules deliberately do NOT import Django, so they can be unit-tested,
benchmarked and replaced independently of the API layer (NFR: Maintainability).

- priority.py   : emergency priority scoring
- dijkstra.py   : minimum-travel-time routing on the road graph
- allocation.py : Dynamic Programming allocation of vehicles to emergencies
"""

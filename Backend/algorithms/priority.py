"""
Emergency priority scoring (FR: Calculate Emergency Priority).

    score = 100 * ( 0.40 * severity / 5
                  + 0.30 * urgency / 5
                  + 0.20 * people_factor
                  + 0.10 * delay_factor )

    people_factor = min(1, ln(1 + people) / ln(1 + 50))
        Logarithmic: going from 1 to 5 people matters more than 45 to 50,
        and 50+ people saturates the term.

    delay_factor  = min(1, waiting_minutes / 30)
        "Impact of delay": an emergency that has waited longer slowly gains
        priority, so a low-severity call is never starved forever.

The result is in the range 0..100 (rounded to 1 decimal place).
"""

import math

WEIGHT_SEVERITY = 0.40
WEIGHT_URGENCY = 0.30
WEIGHT_PEOPLE = 0.20
WEIGHT_DELAY = 0.10

PEOPLE_SATURATION = 50
DELAY_SATURATION_MIN = 30.0

MIN_LEVEL = 1
MAX_LEVEL = 5


def _check_level(name, value):
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError(f"{name} must be an integer between {MIN_LEVEL} and {MAX_LEVEL}.")
    if not MIN_LEVEL <= value <= MAX_LEVEL:
        raise ValueError(f"{name} must be between {MIN_LEVEL} and {MAX_LEVEL}.")


def people_factor(people_affected):
    if people_affected < 0:
        raise ValueError("people_affected cannot be negative.")
    return min(1.0, math.log1p(people_affected) / math.log1p(PEOPLE_SATURATION))


def delay_factor(waiting_minutes):
    return min(1.0, max(0.0, waiting_minutes) / DELAY_SATURATION_MIN)


def priority_score(severity, urgency, people_affected, waiting_minutes=0.0):
    """Return a priority score in 0..100 for one emergency."""
    _check_level("severity", severity)
    _check_level("urgency", urgency)
    raw = (
        WEIGHT_SEVERITY * severity / MAX_LEVEL
        + WEIGHT_URGENCY * urgency / MAX_LEVEL
        + WEIGHT_PEOPLE * people_factor(people_affected)
        + WEIGHT_DELAY * delay_factor(waiting_minutes)
    )
    return round(100.0 * raw, 1)


def vehicles_required(severity, people_affected):
    """
    How many vehicles an emergency needs.
    Large, severe incidents (severity >= 4 and 10+ people) need two units.
    """
    if severity >= 4 and people_affected >= 10:
        return 2
    return 1
